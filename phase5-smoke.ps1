param([int]$Port = 8797)
$ErrorActionPreference = 'Stop'
$base = "http://127.0.0.1:$Port"
function Post($path, $body, $headers = $null) {
  $args = @{ Uri = "$base$path"; Method = 'Post'; ContentType = 'application/json'; Body = ($body | ConvertTo-Json -Compress) }
  if ($headers) { $args.Headers = $headers }
  Invoke-RestMethod @args
}
Write-Output "Testing Onkofizjo Fase 5 at $base"
$session = Post '/api/auth/session' @{ userId='demo-gosia'; role='GOSIA' }
$headers = @{ Authorization = "Bearer $($session.accessToken)" }
$patients = (Invoke-RestMethod "$base/api/patients" -Headers $headers).patients
if ($patients.Count -lt 3) { throw 'Fase 5 requires three distinct synthetic patient contexts' }
$video = Post '/api/teleconsultations' @{ patientId='demo-patient-ewa-dabrowska'; appointmentId='appt-003'; mode='VIDEO'; state='READY'; consent=$true } $headers
if ($video.patientId -ne 'demo-patient-ewa-dabrowska' -or $video.status -ne 'READY' -or $video.recording -ne $false -or $video.provider -ne 'DEMO_PROVIDER_NEUTRAL') { throw 'Video teleconsultation contract failed' }
try { Post '/api/teleconsultations' @{ patientId='demo-patient-ewa-dabrowska'; appointmentId='appt-003'; mode='VIDEO'; consent=$false } $headers | Out-Null; throw 'Consent guard failed' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 422) { throw } }
$phone = Post '/api/teleconsultations' @{ patientId='demo-patient-maria-nowak'; appointmentId='appt-002'; mode='PHONE'; state='RINGING' } $headers
if ($phone.patientId -ne 'demo-patient-maria-nowak' -or $phone.mode -ne 'PHONE' -or $phone.status -ne 'RINGING' -or $phone.phoneAction -notlike 'tel:*') { throw 'Phone fallback contract failed' }
$diet = Post '/api/diet-plans' @{ patientId='demo-patient-maria-nowak'; goal='regularidad de comidas'; restrictions=@('lactosa') } $headers
if ($diet.patientId -ne 'demo-patient-maria-nowak' -or $diet.status -ne 'ASSISTANT_PROPOSED' -or $diet.version -ne 1 -or $diet.meals.Count -lt 3 -or $diet.humanApprovalRequired -ne $true -or $diet.ruleTrace[0].applied -ne $true -or $diet.meals[0].description -notlike '*roślinnym*') { throw 'Diet proposal restriction rule failed' }
$approved = Post '/api/diet-plans/status' @{ patientId='demo-patient-maria-nowak'; planId=$diet.id; status='APPROVED'; approvedBy='demo-gosia' } $headers
if ($approved.status -ne 'APPROVED' -or $approved.patientId -ne 'demo-patient-maria-nowak') { throw 'Human approval contract failed' }
Write-Output 'PASS: video consent and provider boundary.'
Write-Output 'PASS: phone fallback and patient scoping.'
Write-Output 'PASS: grounded diet proposal, versioning and human approval.'
