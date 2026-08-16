param([int]$Port = 8797)
$ErrorActionPreference = 'Stop'
$Base = "http://127.0.0.1:$Port"
function Get-Json($Path) { Invoke-RestMethod -Uri "$Base$Path" -Method Get -Headers @{Accept='application/json'} }
function Post-Json($Path, $Body, $Headers = $null) {
  $arguments = @{ Uri = "$Base$Path"; Method = 'Post'; ContentType = 'application/json'; Body = ($Body | ConvertTo-Json -Compress) }
  if ($Headers) { $arguments.Headers = $Headers }
  Invoke-RestMethod @arguments
}
Write-Output "Testing Onkofizjo API at $Base"
$health = Get-Json '/api/health'; if (-not $health.demo -or -not $health.version -or $health.dataMode -ne 'synthetic-only') { throw 'Health contract failed' }
try { Get-Json '/api/auth/session' | Out-Null; throw 'Unauthenticated session guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 401) { throw } }
$session = Post-Json '/api/auth/session' @{ userId='demo-gosia'; role='GOSIA' }; if (-not $session.authenticated -or -not $session.accessToken) { throw 'Demo session contract failed' }
$sessionCheck = Invoke-RestMethod -Uri "$Base/api/auth/session" -Method Get -Headers @{ Authorization = "Bearer $($session.accessToken)" }; if (-not $sessionCheck.authenticated -or $sessionCheck.session.role -ne 'GOSIA') { throw 'Authenticated session read failed' }
Write-Output 'PASS: unauthenticated requests are rejected and demo Gosia session is verifiable.'
$authHeaders = @{ Authorization = "Bearer $($session.accessToken)" }
try { Post-Json '/api/assistant-runs' @{ patientId='demo-patient-ewa-dabrowska'; task='unauthenticated guard'; sources=@() } | Out-Null; throw 'Assistant auth guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 401) { throw } }
$assistant = Post-Json '/api/assistant-runs' @{ patientId='demo-patient-ewa-dabrowska'; task='smoke test'; sources=@('patient-context') } -Headers $authHeaders; if ($assistant.status -ne 'NEEDS_REVIEW') { throw 'Assistant guardrail failed' }
$patients = Get-Json '/api/patients'; if ($patients.patients.Count -lt 3) { throw 'Expected at least 3 demo patients' }
$search = Get-Json '/api/patients?q=maria'; if ($search.patients.Count -ne 1 -or $search.patients[0].id -ne 'demo-patient-maria-nowak') { throw 'Patient search contract failed' }
$context = Get-Json '/api/patient-context?patientId=demo-patient-ewa-dabrowska'; if (-not $context.profiles.'demo-patient-ewa-dabrowska') { throw 'Ewa context missing' }
$expectedContexts = @(
  @{ Id='demo-patient-anna-kowalska'; Record='PAC-2023-089' },
  @{ Id='demo-patient-maria-nowak'; Record='PAC-2024-014' },
  @{ Id='demo-patient-ewa-dabrowska'; Record='PAC-2024-027' }
)
foreach ($expected in $expectedContexts) {
  $scoped = Get-Json "/api/patient-context?patientId=$($expected.Id)"
  $profile = $scoped.profiles.($expected.Id)
  if ($null -eq $profile -or $profile.recordId -ne $expected.Record) { throw "Patient context mismatch for $($expected.Id)" }
  if ($scoped.profiles.PSObject.Properties.Name.Count -ne 1) { throw "Patient context was not scoped for $($expected.Id)" }
}
Write-Output 'PASS: patient contexts remain scoped and retain distinct record IDs.'
try {
  Get-Json '/api/patient-context?patientId=does-not-exist' | Out-Null
  throw 'Unknown patient guard failed'
} catch {
  if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
}
Write-Output 'PASS: unknown patient context returns HTTP 404 without fallback data.'
$tele = Post-Json '/api/teleconsultations' @{ patientId='demo-patient-ewa-dabrowska'; appointmentId='appt-003'; mode='PHONE'; role='GOSIA' }; if ($tele.status -ne 'INITIATED') { throw 'Teleconsultation flow failed' }
$permissions = Get-Json '/api/permissions'; if (-not $permissions.roles.GOSIA.approve_diet -or $permissions.roles.AI_AGENT.approve_diet) { throw 'Permission policy failed' }
$audit = Get-Json '/api/audit-events'; if ($null -eq $audit.events) { throw 'Audit endpoint failed' }
try { Post-Json '/api/teleconsultations' @{ patientId='demo-patient-maria-nowak'; appointmentId='appt-001'; mode='PHONE'; role='GOSIA' } | Out-Null; throw 'Mismatch guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 422) { throw } }
try { Post-Json '/api/appointments/status' @{ appointmentId='appt-002'; status='INVALID' } | Out-Null; throw 'Appointment status guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 422) { throw } }
try { Post-Json '/api/diet-plans/status' @{ patientId='demo-patient-maria-nowak'; status='APPROVED'; approvedBy='agent'; role='AI_AGENT' } -Headers $authHeaders | Out-Null; throw 'Diet approval guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 403) { throw } }
Write-Output 'PASS: health, patients, search, scoped context, assistant review, teleconsultation, permissions, audit, mismatch, status and approval guards.'
