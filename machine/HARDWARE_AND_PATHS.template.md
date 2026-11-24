# Perfil Local de Hardware y Rutas (Plantilla)

> Copiá este archivo a `machine/LOCAL_PC_PROFILE.md` (excluido por `.gitignore`) o en tu bóveda privada para que cualquier IA conozca los límites físicos reales de tu máquina antes de recomendar Docker, VMs, modelos locales o builds pesados.

## 1. Hardware Base
- **SO:** Windows 11 / 10 (build `...`) + WSL2 (`Ubuntu ...`)
- **CPU:** *(ej. modelo, núcleos físicos/lógicos)*
- **RAM total:** *(ej. 16 GB / 32 GB)* -> **Tope asignado a WSL2:** *(ver `.wslconfig`)*
- **GPU:** *(modelo y VRAM — crítico para Vulkan / juegos / IA local)*
- **Pantalla principal:** `1366x768` *(altura útil navegador ~650px)* + monitor secundario si aplica.

## 2. Mapa de Unidades y Directorios Canónicos
- **`C:\` (Sistema):** Espacio libre objetivo `>= 25%`. Evitar caches gigantes en `%LOCALAPPDATA%` si el SSD es ajustado.
- **`D:\Users\Miko\Workspace\`:** Única raíz permitida para repositorios Git, `.venv`, `node_modules` y builds compilados.
- **`G:\obsidian\`:** Bóveda Google Drive for Desktop (solo `.md`, assets ligeros y tracking de proyectos — **nunca `.git`**).

## 3. Puertos Locales Reservados
- `4566`: LocalStack (SQS / S3 / EC2 mock)
- `5173`: Vite frontend dev
- `5432` / `5430`: PostgreSQL / PostgREST local
- `7130` / `7131` / `7133`: InsForge self-hosted / Deno
- `8000`: FastAPI local

## 4. Cargas Pesadas / No-Dev Aisladas
- **Gaming / Recompilaciones (`Hookshot`, etc.):** Ubicación dedicada fuera de `C:\Users`, método de aislamiento aplicado.
- **Stacks complejos (`FriGram`, etc.):** Contenedor / WSL distro / Sandbox asignado.
