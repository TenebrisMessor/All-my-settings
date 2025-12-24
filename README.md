# ⚙️ Configuraciones Personales – Entornos y Terminal  d

Este repositorio contiene la configuración de mi entorno de desarrollo en diferentes sistemas operativos: **Linux**, **MacOS** y **Windows**.

---
## Diagrama de flujo

```mermaid
flowchart TD
  A[setup.sh] --> B{Detecta SO}
  B -->|macOS| C[macos/setup-macos.sh]
  B -->|Linux| D[linux/setup-linux.sh]
  B -->|Windows| E[windows/setup-windows.ps1]
  C --> F[common/setup-common.sh]
  D --> F
  E --> G[common block en PowerShell]
  F --> H[Conda env: sithlab]
  F --> I[pip install libs]
  F --> J[Deploy NVIM config]

---
## 📁 Estructura del Repositorio
<!-- BACKUP_LOG_START -->
| Fecha | Evento | Detalle |
|---|---|---|
| 2025-06-23 | Respaldo automático | pip + apt + conda (base) |
| 2025-06-23 | Respaldo automático | pip + paquetes + conda (base) |
<!-- BACKUP_LOG_END -->
