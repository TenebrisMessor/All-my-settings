# ⚙️ Configuraciones Personales – Entornos y Terminal  d

Este repositorio contiene la configuración de mi entorno de desarrollo en diferentes sistemas operativos: **Linux**, **MacOS** y **Windows**.

---
## Diagrama de flujo

```mermaid
flowchart TD
  A([Inicio]) --> B[setup.sh]
  B --> C{Detectar SO}
  C -->|macOS| D[macos/setup-macos.sh]
  C -->|Linux| E[linux/setup-linux.sh]
  C -->|Windows| F[windows/setup-windows.ps1]

  D --> G[common/setup-common.sh]
  E --> G
  F --> H[Common block PowerShell]

  subgraph COMMON["Common setup global"]
    G --> I[Instalar o configurar Conda]
    I --> J[Crear o actualizar env sithlab]
    J --> K[Instalar librerias pip-sithlab.txt]
    K --> L[Deploy NVIM common/nvim -> ~/.config/nvim]
    L --> M([Listo])
  end

  subgraph COMMON_WIN["Common setup Windows"]
    H --> J2[Crear o actualizar env sithlab]
    J2 --> K2[Instalar librerias pip-sithlab.txt]
    K2 --> L2[Deploy NVIM LOCALAPPDATA\\nvim]
    L2 --> M2([Listo])
  end
```
---
## 📁 Estructura del Repositorio
<!-- BACKUP_LOG_START -->
| Fecha | Evento | Detalle |
|---|---|---|
| 2025-06-23 | Respaldo automático | pip + apt + conda (base) |
| 2025-06-23 | Respaldo automático | pip + paquetes + conda (base) |
<!-- BACKUP_LOG_END -->
