param([int]$Port = 4173)
$ErrorActionPreference = 'Stop'
$base = "http://127.0.0.1:$Port"
$routes = @(
  'stitch-marketing.html', 'crm.html', 'calendar.html', 'patient.html?patientId=demo-patient-maria-nowak',
  'note-create.html?patientId=demo-patient-ewa-dabrowska', 'appointment-create.html?patientId=demo-patient-maria-nowak', 'appointment-status.html?appointmentId=appt-002', 'teleconsult.html?patientId=demo-patient-ewa-dabrowska&appointmentId=appt-003',
  'diet-plan.html?patientId=demo-patient-maria-nowak', 'hermes.html?patientId=demo-patient-anna-kowalska', 'roles.html', 'audit.html'
)
foreach ($route in $routes) {
  $response = Invoke-WebRequest -Uri "$base/$route" -UseBasicParsing
  if ($response.StatusCode -ne 200) { throw "$route returned $($response.StatusCode)" }
  Write-Output "PASS $route"
}
Write-Output "PASS: $($routes.Count) application routes returned HTTP 200."
