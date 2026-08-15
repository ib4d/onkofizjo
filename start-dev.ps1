param([int]$WebPort = 4173, [int]$ApiPort = 8797)
$bundledPython = 'C:\Users\abad1\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$python = if (Test-Path $bundledPython) { $bundledPython } else { (Get-Command python -ErrorAction SilentlyContinue).Source }
if (-not $python) { $python = (Get-Command py -ErrorAction SilentlyContinue).Source }
if (-not $python) { throw 'Python no está instalado o no está disponible en PATH.' }
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$occupied = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in @($WebPort, $ApiPort) } | Select-Object -ExpandProperty OwningProcess -Unique
foreach ($processId in $occupied) {
  if ($processId -and $processId -ne $PID) { Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue }
}
Start-Process -FilePath $python -ArgumentList '-m','http.server',"$WebPort" -WorkingDirectory $root -WindowStyle Hidden
$env:ONKOFIZJO_API_PORT = "$ApiPort"
Start-Process -FilePath $python -ArgumentList 'api/server.py' -WorkingDirectory $root -WindowStyle Hidden
Write-Output "Web: http://127.0.0.1:$WebPort/"
Write-Output "API: http://127.0.0.1:$ApiPort/api/health"
