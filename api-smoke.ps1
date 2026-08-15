param([int]$Port = 8797)
$ErrorActionPreference = 'Stop'
$Base = "http://127.0.0.1:$Port"
function Get-Json($Path) { Invoke-RestMethod -Uri "$Base$Path" -Method Get -Headers @{Accept='application/json'} }
function Post-Json($Path, $Body) { Invoke-RestMethod -Uri "$Base$Path" -Method Post -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Compress) }
Write-Output "Testing Onkofizjo API at $Base"
$health = Get-Json '/api/health'; if (-not $health.demo) { throw 'Health check is not demo API' }
$patients = Get-Json '/api/patients'; if ($patients.patients.Count -lt 3) { throw 'Expected at least 3 demo patients' }
$context = Get-Json '/api/patient-context?patientId=demo-patient-ewa-dabrowska'; if (-not $context.profiles.'demo-patient-ewa-dabrowska') { throw 'Ewa context missing' }
$assistant = Post-Json '/api/assistant-runs' @{ patientId='demo-patient-ewa-dabrowska'; task='smoke test'; sources=@('patient-context') }; if ($assistant.status -ne 'NEEDS_REVIEW') { throw 'Assistant guardrail failed' }
$tele = Post-Json '/api/teleconsultations' @{ patientId='demo-patient-ewa-dabrowska'; appointmentId='appt-003'; mode='PHONE'; role='GOSIA' }; if ($tele.status -ne 'INITIATED') { throw 'Teleconsultation flow failed' }
Write-Output 'PASS: health, patient list, scoped context, assistant review, teleconsultation.'
