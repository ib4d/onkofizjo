# Onkofizjo · desarrollo local

## Inicio recomendado

Desde `C:\dev\mis-apps\reha-app`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start-dev.ps1
```

El script inicia:

- Web: `http://127.0.0.1:4173/`
- API: `http://127.0.0.1:8797/api/health`

El script libera primero los procesos que ocupen esos puertos para evitar que se utilice una versión antigua del API.

## Comprobaciones

```powershell
.\api-smoke.ps1 -Port 8797
.\web-smoke.ps1 -Port 4173
```

Si PowerShell bloquea scripts, ejecutar los comandos con `-ExecutionPolicy Bypass`.

## Diagnóstico rápido

```powershell
Invoke-WebRequest http://127.0.0.1:8797/api/health -UseBasicParsing
```

Si devuelve `not_found` para un endpoint nuevo, reiniciar `start-dev.ps1`: normalmente significa que sigue activo un proceso API antiguo.

La aplicación utiliza únicamente datos sintéticos. No introducir información clínica real en este entorno.
