param([int]$Port = 4182)
$ErrorActionPreference = 'Stop'
foreach ($path in @('/robots.txt','/sitemap.xml','/manifest.webmanifest')) {
  $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port$path" -UseBasicParsing
  if ($response.StatusCode -ne 200) { throw "$path unavailable" }
}
$robots = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/robots.txt" -UseBasicParsing
foreach ($blocked in @('/api/','/crm.html','/patient.html')) { if ($robots.Content -notlike "*Disallow: $blocked*") { throw "robots missing $blocked" } }
$sitemap = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/sitemap.xml" -UseBasicParsing
if ($sitemap.Content -notlike '*stitch-marketing.html*' -or $sitemap.Content -like '*crm.html*') { throw 'sitemap public-scope contract failed' }
Write-Output 'PASS: public SEO assets are served.'
Write-Output 'PASS: robots blocks clinical/private routes.'
Write-Output 'PASS: sitemap contains marketing only.'
