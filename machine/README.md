# Pilar Físico: Optimización de la Computadora y Aislamiento de Entornos

Este directorio concentra todo lo necesario para mantener la estación de trabajo **rápida, reproducible y libre de contaminación cruzada**, separando la máquina física de los experimentos, juegos pesados o stacks complejos.

---

## Principios Fundamentales

1. **Host limpio por defecto:** El sistema operativo base (Windows) solo debería alojar utilidades diarias esenciales, drivers/GPU, navegador, editor (`VS Code`), Git, Docker/WSL2 y un gestor mínimo de toolchains.
2. **Aislamiento escalonado:** Nunca instalar librerías globales de Python, compiladores C++ masivos ni servicios de fondo directamente en el host si un nivel de aislamiento superior lo resuelve. Ver [`ISOLATION_MATRIX.md`](./ISOLATION_MATRIX.md).
3. **Separación estricta de almacenamiento:**
   - Repositorios Git y builds activos $\rightarrow$ disco local rápido (`D:\Users\Miko\Workspace\`), **fuera de Google Drive**.
   - Notas de proyectos, tracking e historial humano $\rightarrow$ `G:\obsidian\`.
   - Archivos temporales, shader caches y descargas descartables $\rightarrow$ auditados y limpiados periódicamente con `scripts/cleanup-caches.ps1`.
4. **Configuración reproducible + scripts auditables:** Todo script de mantenimiento debe ser idempotente, tener modo simulación por defecto (`-DryRun` / `-WhatIf`) y pasar el verificador estático [`scripts/check-machine-scripts.sh`](./scripts/check-machine-scripts.sh).

---

## Mapa de `machine/`

| Archivo | Uso |
| :--- | :--- |
| [`ISOLATION_MATRIX.md`](./ISOLATION_MATRIX.md) | Árbol de decisión **Host vs Portable vs Venv/uv vs Docker/Devcontainer vs Sandbox/VM** (incluye casos reales: `Hookshot` y `FriGram`). |
| [`WINDOWS_WSL_OPTIMIZATION.md`](./WINDOWS_WSL_OPTIMIZATION.md) | Límites de RAM WSL2, Drive for Desktop sin corrupción Git, ergonomía `1366x768` y sync global de skills Cross-IA. |
| [`HARDWARE_AND_PATHS.template.md`](./HARDWARE_AND_PATHS.template.md) | Plantilla local (copiar a `LOCAL_PC_PROFILE.md`, ignorado por `.gitignore`) para registrar tus specs sin exponer datos locales en GitHub. |
| [`configs/.wslconfig.example`](./configs/.wslconfig.example) | Plantilla de límites de memoria, CPU y recuperación automática de RAM para WSL2 + Docker Desktop. |
| [`configs/.gitconfig.windows.example`](./configs/.gitconfig.windows.example) | Configuración Git segura para Windows (line endings, longpaths, sin romper symlinks). |
| `scripts/audit-host.ps1` | Diagnóstico solo lectura de discos, consumo WSL2/Docker, cachés y rutas de skills globales. |
| `scripts/cleanup-caches.ps1` | Limpieza segura de cachés (`npm`, `pip`, `uv`, `cargo`, Docker dangling, `~/.gemini/tmp`) en modo `-DryRun` por defecto. |
| `scripts/check-machine-scripts.sh` | Chequeos estructurales estáticos (patrón `InsForge/scripts/check-setup-sh.sh`) para validar scripts de máquina. |
