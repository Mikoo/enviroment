#!/usr/bin/env bash
# check-repo.sh — CI & local verification gate for Mikoo/enviroment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Skill mirror parity ==="
bash "$REPO_ROOT/scripts/sync-skills.sh" --check

echo "=== 2. Machine script safety invariants ==="
bash "$REPO_ROOT/machine/scripts/check-machine-scripts.sh"

echo "=== 3. Cross-AI SKILL.md, openai.yaml & Markdown link validation ==="
python3 - "$REPO_ROOT" << 'EOF'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
skills_dir = root / ".agents" / "skills"
errors = []

allowed_skill_keys = {"name", "description", "license", "compatibility", "allowed-tools"}
name_re = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

skill_dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
if not skill_dirs:
    errors.append("No skill directories found in .agents/skills/")

for sdir in skill_dirs:
    skill_md = sdir / "SKILL.md"
    if not skill_md.is_file():
        errors.append(f"{sdir.name}: missing SKILL.md")
        continue

    text = skill_md.read_text(encoding="utf-8")
    lines = text.splitlines()
    if len(lines) >= 500:
        errors.append(f"{sdir.name}/SKILL.md exceeds 500 lines ({len(lines)})")

    m = re.match(r"^---\n(.*?)\n---\n", text, flags=re.DOTALL)
    if not m:
        errors.append(f"{sdir.name}/SKILL.md: missing valid YAML frontmatter block")
        continue

    fm_lines = m.group(1).splitlines()
    fm_data = {}
    for line in fm_lines:
        if not line.strip() or line.strip().startswith("#"):
            continue
        if ":" not in line:
            errors.append(f"{sdir.name}/SKILL.md: malformed frontmatter line '{line}'")
            continue
        k, v = line.split(":", 1)
        key = k.strip()
        val = v.strip().strip('"').strip("'")
        fm_data[key] = val
        if key not in allowed_skill_keys:
            errors.append(f"{sdir.name}/SKILL.md: disallowed frontmatter key '{key}' (breaks Codex/agentskills.io)")

    if fm_data.get("name") != sdir.name:
        errors.append(f"{sdir.name}/SKILL.md: name '{fm_data.get('name')}' != folder '{sdir.name}'")
    if not name_re.match(sdir.name) or len(sdir.name) > 64:
        errors.append(f"{sdir.name}: invalid kebab-case name or >64 chars")

    desc = fm_data.get("description", "")
    if not desc:
        errors.append(f"{sdir.name}/SKILL.md: missing description")
    elif len(desc) > 1024:
        errors.append(f"{sdir.name}/SKILL.md: description > 1024 chars ({len(desc)})")

    openai_yaml = sdir / "agents" / "openai.yaml"
    if not openai_yaml.is_file():
        errors.append(f"{sdir.name}: missing agents/openai.yaml")
    else:
        y_text = openai_yaml.read_text(encoding="utf-8")
        for req_field in ("display_name:", "short_description:", "default_prompt:"):
            if req_field not in y_text:
                errors.append(f"{sdir.name}/agents/openai.yaml: missing {req_field}")

# Check no Obsidian [[wikilinks]] leaked into Cross-AI folders/files
check_paths = [
    root / "AGENTS.md",
    root / "CLAUDE.md",
    root / "GEMINI.md",
    root / "00_WEB_CHAT_INDEX.md",
    root / "README.md",
    *list((root / ".agents").rglob("*.md")),
    *list((root / "patterns").rglob("*.md")),
    *list((root / "machine").rglob("*.md")),
]

link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
for md_path in check_paths:
    if not md_path.is_file():
        continue
    content = md_path.read_text(encoding="utf-8")
    # Strip fenced code blocks and inline code spans before checking links/wikilinks
    stripped = re.sub(r"```.*?```", "", content, flags=re.DOTALL)
    stripped = re.sub(r"`[^`\n]+`", "", stripped)
    if "[[" in stripped:
        errors.append(f"{md_path.relative_to(root)}: contains Obsidian wikilink '[[' outside code")

    for target in link_re.findall(stripped):
        target = target.split("#", 1)[0].strip()
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        resolved = (md_path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"{md_path.relative_to(root)}: broken relative link '{target}'")

# Ensure 00_WEB_CHAT_INDEX.md stays compact and lists every canonical skill
web_index = (root / "00_WEB_CHAT_INDEX.md").read_text(encoding="utf-8")
if len(web_index.encode("utf-8")) > 8192:
    errors.append("00_WEB_CHAT_INDEX.md exceeds 8 KB (keep compact for mobile/web chats)")
for sdir in skill_dirs:
    if f"`{sdir.name}`" not in web_index:
        errors.append(f"00_WEB_CHAT_INDEX.md: missing skill entry '{sdir.name}'")

# Ensure all PowerShell scripts are pure ASCII (prevents Windows PowerShell 5.1 ANSI smart-quote parse errors)
for ps_path in sorted(root.rglob("*.ps1")):
    ps_bytes = ps_path.read_bytes()
    try:
        ps_bytes.decode("ascii")
    except UnicodeDecodeError as exc:
        errors.append(f"{ps_path.relative_to(root)}: non-ASCII byte at offset {exc.start} (keep .ps1 files pure ASCII)")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)

print(f"OK: Validated {len(skill_dirs)} skills, frontmatter rules, openai.yaml, web-chat parity, PS1 ASCII, and relative links.")
EOF
