# Matriz de Aislamiento Físico (`ISOLATION_MATRIX`)

Regla de oro: **elegir siempre el nivel más alto de aislamiento que no degrade innecesariamente la experiencia requerida (GPU, latencia o red).** Nunca instalar en el host por costumbre.

---

## 1. Los 5 Niveles de Aislamiento

| Nivel | Tecnología | Qué aísla | Cuándo usarlo | Cuándo NO usarlo |
| :--- | :--- | :--- | :--- | :--- |
| **Nivel 0 — Host Nativo** | Windows directo | Nada (solo usuario/carpeta). | Drivers GPU, editor (`VS Code`), Git, Docker Desktop, navegadores y **juegos/render Vulkan nativo** cuando exigen acceso directo a GPU. | Bots, bases de datos, runtimes experimentales, instaladores de prueba o dependencias con conflictos de versión. |
| **Nivel 1 — Portable / Self-Contained** | Binarios portables + carpeta dedicada en `D:\Apps\` | Sin instalador global ni entradas en `PATH` del sistema (o cargadas solo en shell de proyecto). | Compiladores portables (`llvm-mingw`), herramientas CLI sueltas, binarios Rust/Go precompilados, builders autocontenidos. | Apps que igual instalan servicios Windows o modifican el registro masivamente. |
| **Nivel 2 — Entorno de Lenguaje (`venv` / `uv` / `nvm`)** | `.venv` por proyecto, `uv`, `fnm`/`nvm`, `conda` | Dependencias Python/Node por carpeta de proyecto. | Desarrollo diario Python (`FastAPI`, `pytest`, `boto3`) y Node/TS (`Vite`, `React`, `SvelteKit`). | Cuando requiere servicios externos (Postgres, Redis, SQS, Chrome headless, librerías C de sistema). |
| **Nivel 3 — Contenedor / Devcontainer (`Docker Compose`)** | Contenedores OCI + red privada + volúmenes nombrados | Sistema de archivos, puertos, servicios, librerías nativas y versiones de SO Linux. | Stacks multi-servicio (`Postgres + PostgREST + Deno + MinIO`), **FriGram**, bots, scrapers, `LocalStack`, pruebas reproducibles. | Apps GUI con Vulkan intensivo o gaming de baja latencia en Windows. |
| **Nivel 4 — VM / WSL2 Distro Dedicada / Windows Sandbox** | `Windows Sandbox` (efímero), Hyper-V VM, o `wsl --import` dedicado | Kernel / registro / filesystem completo de Windows. | Probar software desconocido, compiladores pesados de un solo uso (Visual Studio MFC para builds puntuales), entornos sucios que no querés en tu Windows diario. | Flujos rápidos que necesitan editar código cada minuto desde tu IDE principal (usar Nivel 2 o 3). |

---

## 2. Casos de Estudio Reales

### Caso A: `Hookshot` (Recompilación nativa / Game Engine con Vulkan y C++)
- **Naturaleza del problema:** Las recompilaciones estáticas nativas (ARM64 $\rightarrow$ C $\rightarrow$ `.exe` con renderizado **Vulkan**) exigen acceso directo a GPU en el host para jugar (Nivel 0 en ejecución), pero su fase de build/instalación suele arrastrar dependencias pesadas (Visual Studio Build Tools + MFC, `llvm-mingw`, caches intermedios de ~4+ GB en `%LOCALAPPDATA%\HookshotBuilder` y shader caches).
- **Estrategia limpia recomendada:**
  1. **Evitar instalar todo Visual Studio IDE en el host si el proyecto soporta `llvm-mingw` portable** (Nivel 1): usar la variante con toolchain autocontenida y mantener código/build/shaders fuera de `C:\Users` (en una ruta dedicada tipo `D:\Games\Hookshot\` o `D:\Sandbox\Hookshot\`).
  2. **Si exige MSVC / Windows SDK pesado solo para compilar una vez:** compilar el binario en una **VM / Windows Sandbox o contenedor Windows** (Nivel 4), extraer únicamente el ejecutable final + assets y correr el resultado en Nivel 0 sin dejar 15 GB de Visual Studio Build Tools en tu Windows diario.
  3. **Higiene post-build:** una vez generado el juego estable, purgar los archivos intermedios de compilación (~4 GB) conservando solo saves y ejecutable, y registrar la ruta de build en `cleanup-caches.ps1`.

### Caso B: `FriGram` (Stack complejo / Multi-dependencia / Entorno propenso a ensuciar)
- **Naturaleza del problema:** Aplicaciones o suites con múltiples librerías nativas, versiones específicas de runtime, clientes de mensajería/automatización, sesiones persistentes o servicios en segundo plano. Si se instalan directo en Windows terminan dejando demonios corriendo, versiones rotas de Python/Node o conflictos de `PATH`.
- **Estrategia limpia recomendada:**
  1. **Primario — Nivel 3 (Docker Compose con proyecto dedicado):**
     - Crear su propio directorio fuera del código fuente diario con `.env` (`COMPOSE_PROJECT_NAME=frigram`, bind estricto a `127.0.0.1` y volúmenes nombrados).
     - Levantar **solo bajo demanda** (`docker compose up -d`) y bajar al terminar (`docker compose down`) para liberar RAM en reposo.
  2. **Si requiere CLI/GUI Linux o herramientas de red complejas — Nivel 4 (Distro WSL2 dedicada o Devcontainer):**
     - `wsl --import frigram-lab D:\WSL\frigram-lab base-ubuntu.tar` permite congelar, exportar (`wsl --export`) o destruir (`wsl --unregister frigram-lab`) todo el entorno en segundos dejando Windows 100% intacto.

---

## 3. Árbol Rápido de Decisión

1. ¿Necesita GPU/Vulkan directo para correr a 60 FPS en pantalla?
   - **Sí** $\rightarrow$ Ejecutar binario final en **Nivel 0/1** en `D:\`, pero compilar en toolchain portable (Nivel 1) o VM aislada (Nivel 4) si requiere SDKs invasivos.
   - **No** $\rightarrow$ Ir al paso 2.
2. ¿Es un instalador de terceros desconocido o modifica el Registro/servicios de Windows?
   - **Sí** $\rightarrow$ **Windows Sandbox o VM (Nivel 4)** primero. Nunca directo en el host.
   - **No** $\rightarrow$ Ir al paso 3.
3. ¿Necesita servicios en background (DB, colas, Redis, Nginx, Deno) o librerías de SO Linux?
   - **Sí** $\rightarrow$ **Docker Compose / Devcontainer (Nivel 3)** con `COMPOSE_PROJECT_NAME` único y bind `127.0.0.1`.
   - **No** $\rightarrow$ **Nivel 2 (`uv` / `.venv` / `nvm`)** dentro del repo en `D:\Users\Miko\Workspace\`.
