param([int]$Port = 8797)
$ErrorActionPreference = 'Stop'
$base = "http://127.0.0.1:$Port"
$session = Invoke-RestMethod "$base/api/auth/session" -Method Post -ContentType 'application/json' -Body '{"userId":"demo-gosia","role":"GOSIA"}'
$headers = @{ Authorization = "Bearer $($session.accessToken)" }
function Run($sources) {
  Invoke-RestMethod "$base/api/assistant-runs" -Method Post -Headers $headers -ContentType 'application/json' -Body ((@{ patientId='demo-patient-maria-nowak'; task='phase six evidence check'; sources=$sources } | ConvertTo-Json -Compress))
}
$refused = Run @('know-003')
if ($refused.status -ne 'REVIEW_REQUIRED' -or $refused.sources.Count -ne 0 -or -not $refused.noInferenceWithoutEvidence) { throw 'Hermes refusal guard failed' }
$grounded = Run @('know-001')
if ($grounded.status -ne 'NEEDS_REVIEW' -or $grounded.sources[0] -ne 'know-001' -or -not $grounded.humanReviewRequired) { throw 'Hermes grounded source guard failed' }
Write-Output 'PASS: unapproved sources produce no clinical conclusion.'
Write-Output 'PASS: approved internal sources are cited and remain human-review gated.'
