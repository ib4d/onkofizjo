param([int]$Port = 8797)
$ErrorActionPreference = 'Stop'
$base = "http://127.0.0.1:$Port"
$health = Invoke-RestMethod "$base/api/health"
if (-not $health.demo -or $health.dataMode -ne 'synthetic-only') { throw 'Health data-mode contract failed' }
try { Invoke-WebRequest "$base/api/readiness" -UseBasicParsing | Out-Null; throw 'Readiness must fail closed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 503) { throw } }
$metrics = Invoke-RestMethod "$base/api/metrics"
if (-not $metrics.clinicalPayloadsExcluded -or $metrics.dataMode -ne 'synthetic-only') { throw 'Metrics safety contract failed' }
Write-Output 'PASS: health declares synthetic-only mode.'
Write-Output 'PASS: readiness fails closed until production gates exist.'
Write-Output 'PASS: metrics exclude clinical payloads.'
