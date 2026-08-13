# Publicar cambios en GitHub desde Windows

El runtime local de Codex incluye Git para trabajar con commits, pero no incluye el helper HTTPS (`git-remote-https`). Por eso los commits se crean correctamente y el `push` falla.

## Solución recomendada

Instala Git for Windows desde https://git-scm.com/download/win y reinicia PowerShell. Comprueba que aparece el helper:

```powershell
git --version
git push origin main
```

Cuando Git solicite autenticación, utiliza Git Credential Manager o un token personal de GitHub; nunca guardes un token dentro de la URL del repositorio.

## Alternativa

GitHub Desktop también puede abrir este repositorio local y publicar los commits pendientes sin modificar el proyecto.

Los commits locales ya creados no se pierden. Después de configurar Git, basta con ejecutar:

```powershell
cd C:\dev\mis-apps\reha-app
git push origin main
```
