# Optimización Física de Windows, WSL2, Docker y Ergonomía Diaria

Guía operativa para exprimir hardware diario (incluyendo laptops con `1366x768` y RAM ajustada) sin degradar rendimiento ni perder estabilidad entre herramientas de desarrollo.

---

## 1. Control de Memoria y CPU de WSL2 + Docker Desktop

Por defecto, WSL2 (`vmmemWSL`) puede consumir hasta el 50% de la RAM física del equipo y **no siempre la devuelve a Windows** tras cerrar contenedores.

### Regla Obligatoria: `%USERPROFILE%\.wslconfig`
Usar [`configs/.wslconfig.example`](./configs/.wslconfig.example) ajustando `memory=` al 40–50% de tu RAM real (ej. `6GB` en equipo de 16 GB, `12GB` en equipo de 32 GB) con `autoMemoryReclaim=gradual` y `sparseVhd=true`.

- **Modo Zero-Idle en Docker:** No dejar stacks (`InsForge`, `LocalStack`, `FriGram`, `Postgres`) corriendo en segundo plano cuando no estás trabajando en ese proyecto. Parar contenedores al cambiar de contexto:
  ```powershell
  docker ps -q | ForEach-Object { docker stop $_ }
  ```
- **Compactar discos virtuales `.vhdx` de Docker/WSL2** cuando el disco `C:` pierda espacio tras borrar imágenes (`wsl --shutdown` y `Optimize-VHD` o `diskpart` sobre `ext4.vhdx`).

---

## 2. Regla de Oro: Google Drive (`G:\`) vs. Workspace Git (`D:\`)

- **Nunca clonar repositorios Git dentro de `G:\`** (Google Drive for Desktop). Drive bloquea archivos dentro de `.git/objects/` y `.venv/`, generando corrupción de índices, conflictos silenciosos y uso excesivo de CPU/red indexando `node_modules`.
- **Topología limpia:**
  - `D:\Users\Miko\Workspace\<proyecto>\` $\rightarrow$ Código fuente, `.git`, `.venv`, `node_modules`, `docker-compose`.
  - `G:\obsidian\<proyecto>\` $\rightarrow$ Markdown de estado vivo, ADRs, auditorías y `ENVIROMENT_IMPORTS.md`.
- **Si un repo necesita consultar notas de Obsidian localmente:** referenciar la ruta en `G:\obsidian\<proyecto>\` o usar junctions unidireccionales **exclusivamente hacia subcarpetas excluidas en `.gitignore`** (nunca versionar la carpeta de Drive dentro de Git).

---

## 3. Configuración Global de Skills Cross-IA en Windows (Sin Trampas)

1. **No crear `%USERPROFILE%\.gemini\config\skills.json`:** Antigravity no lo expande en alcance global.
2. **No depender de symlinks de Git dentro del repo:** Windows checkouts pueden convertirlos en texto plano.
3. **Ejecutar desde `D:\Users\Miko\Workspace\enviroment`:**
   ```powershell
   .\scripts\sync-skills.ps1 -Global
   ```
   Mantiene copias limpias sincronizadas en:
   - `%USERPROFILE%\.gemini\config\skills\` *(Antigravity App + CLI + IDE)*
   - `%USERPROFILE%\.agents\skills\` *(Codex CLI / Gemini CLI)*
   - `%USERPROFILE%\.claude\skills\` *(Claude Code)*
4. **Limpieza segura de residuos viejos de Gemini CLI:** revisar `%USERPROFILE%\.gemini\tmp\` y respaldos obsoletos (`antigravity-backup`, `antigravity-ide`) — pero **nunca** borrar `~/.gemini/antigravity/` (conversaciones) ni `~/.gemini/config/`.

---

## 4. Ergonomía para Pantalla `1366x768` (~650px útiles)

- Ocultar automáticamente o reducir la barra de tareas de Windows si necesitás verticalidad extra en VS Code / dashboards.
- En VS Code (`settings.json`):
  - `"window.zoomLevel": -0.5` o fuente compacta (`13px`) cuando trabajás en split editor + terminal.
  - Terminal integrada en panel derecho (lateral) o maximizable (`Ctrl+J` / toggle maximize) en vez de dejarla fija ocupando 250px abajo en 768px de alto.
  - Apagar extensiones pesadas por perfil (usar *VS Code Profiles*: `Python-Cloud`, `Web-React-Tailwind`, `Rust-Tauri`) para que un proyecto React no cargue linters Python ni `rust-analyzer` en RAM.

---

## 5. Rutina Semanal de Higiene (5 minutos)

1. Auditar estado del host (solo lectura):
   ```powershell
   .\machine\scripts\audit-host.ps1
   ```
2. Previsualizar qué cachés seguros se pueden purgar (`-DryRun` es obligatorio por defecto):
   ```powershell
   .\machine\scripts\cleanup-caches.ps1
   ```
3. Confirmar limpieza real solo tras revisar la lista:
   ```powershell
   .\machine\scripts\cleanup-caches.ps1 -Execute
   ```
