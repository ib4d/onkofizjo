$ErrorActionPreference = 'Stop'
$required = @('ops/POSTLAUNCH_RUNBOOK.md','PHASE9_STATUS.md','SEO_RELEASE_CHECKLIST.md','release-gate.ps1')
foreach ($file in $required) { if (-not (Test-Path $file)) { throw "Missing operational artifact: $file" } }
$runbook = Get-Content ops/POSTLAUNCH_RUNBOOK.md -Raw
foreach ($term in @('P0','rollback','dato de salud','api-smoke.ps1','web-smoke.ps1')) { if ($runbook -notlike "*$term*") { throw "Runbook missing $term" } }
Write-Output 'PASS: phase nine operational artifacts are present.'
Write-Output 'PASS: incident severity, rollback and privacy rules are documented.'
