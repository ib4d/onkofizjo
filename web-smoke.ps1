param([int]$Port = 4173)
$ErrorActionPreference = 'Stop'
$base = "http://127.0.0.1:$Port"
$routes = @(
  'stitch-marketing.html', 'marketing-section.html?section=services', 'marketing-section.html?section=services&lang=en', 'marketing-section.html?section=locations', 'marketing-section.html?section=blog', 'marketing-section.html?section=contact', 'crm.html', 'calendar.html', 'patient.html?patientId=demo-patient-maria-nowak',
  'note-create.html?patientId=demo-patient-ewa-dabrowska', 'appointment-create.html?patientId=demo-patient-maria-nowak', 'appointment-status.html?appointmentId=appt-002', 'teleconsult.html?patientId=demo-patient-ewa-dabrowska&appointmentId=appt-003',
  'diet-plan.html?patientId=demo-patient-maria-nowak', 'hermes.html?patientId=demo-patient-anna-kowalska', 'roles.html', 'audit.html', 'crm-modules.html'
)
foreach ($route in $routes) {
  $response = Invoke-WebRequest -Uri "$base/$route" -UseBasicParsing
  if ($response.StatusCode -ne 200) { throw "$route returned $($response.StatusCode)" }
  Write-Output "PASS $route"
}
function Assert-PageContains([string]$route, [string]$expected) {
  $response = Invoke-WebRequest -Uri "$base/$route" -UseBasicParsing
  if ($response.Content -notlike "*$expected*") {
    throw "$route did not contain expected text: $expected"
  }
  Write-Output "PASS content $route contains '$expected'"
}
function Assert-PageExcludes([string]$route, [string]$unexpected) {
  $response = Invoke-WebRequest -Uri "$base/$route" -UseBasicParsing
  if ($response.Content -like "*$unexpected*") {
    throw "$route contained forbidden static text: $unexpected"
  }
  Write-Output "PASS content $route excludes '$unexpected'"
}
function Assert-Header([string]$route, [string]$header, [string]$expected) {
  $response = Invoke-WebRequest -Uri "$base/$route" -UseBasicParsing
  $actual = $response.Headers[$header]
  if ($actual -notlike "*$expected*") { throw "$route missing $header containing '$expected'" }
  Write-Output "PASS header $route $header contains '$expected'"
}
Assert-PageContains 'marketing-section.html?section=services&lang=en' 'Services'
Assert-PageContains 'marketing-section.html?section=services&lang=pl' 'Usługi'
Assert-PageContains 'crm-modules.html' 'Teleconsultation'
Assert-PageContains 'crm-modules.html' 'Clinical records'
Assert-PageContains 'appointment-create.html?patientId=demo-patient-maria-nowak' 'id="patientId"'
Assert-PageContains 'appointment-create.html?patientId=demo-patient-maria-nowak' 'Utwórz wizytę'
Assert-PageContains 'appointment-status.html?appointmentId=appt-002' 'id="appointmentId"'
Assert-PageContains 'appointment-status.html?appointmentId=appt-002' 'Guardar estado'
Assert-PageContains 'teleconsult.html?patientId=demo-patient-ewa-dabrowska&appointmentId=appt-003' 'id="video"'
Assert-PageContains 'teleconsult.html?patientId=demo-patient-ewa-dabrowska&appointmentId=appt-003' 'id="phone"'
Assert-PageContains 'note-create.html?patientId=demo-patient-ewa-dabrowska' 'id="submit"'
Assert-PageContains 'patient.html?patientId=demo-patient-maria-nowak' 'patient-context.js'
Assert-PageExcludes 'diet-plan.html' 'Anna Kowalska'
Assert-PageContains 'crm.html' 'data-phase3-responsive'
Assert-PageContains 'calendar.html' 'data-phase3-responsive'
Assert-PageContains 'appointment-create.html' 'auth-bridge.js'
Assert-Header 'crm.html' 'X-Content-Type-Options' 'nosniff'
Assert-Header 'crm.html' 'Referrer-Policy' 'same-origin'
Assert-Header 'crm.html' 'Cache-Control' 'no-store'
Write-Output "PASS: $($routes.Count) application routes returned HTTP 200."
