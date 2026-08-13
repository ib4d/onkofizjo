param([int]$WebPort = 4173, [int]$ApiPort = 8794)
$python = 'C:\Users\abad1\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Start-Process -FilePath $python -ArgumentList '-m','http.server',"$WebPort" -WorkingDirectory $root -WindowStyle Hidden
$env:ONKOFIZJO_API_PORT = "$ApiPort"
Start-Process -FilePath $python -ArgumentList 'api/server.py' -WorkingDirectory $root -WindowStyle Hidden
Write-Output "Web: http://127.0.0.1:$WebPort/"
Write-Output "API: http://127.0.0.1:$ApiPort/api/health"
