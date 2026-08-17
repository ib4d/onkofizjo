$ErrorActionPreference = 'Stop'
$robots = Get-Content robots.txt -Raw
$sitemap = Get-Content sitemap.xml -Raw
$marketing = Get-Content stitch-marketing.html -Raw
if ($robots -match 'Replace the placeholder domain' -or $sitemap -match 'reha\.mp' -or $marketing -match 'https://reha\.mp') { throw 'Release gate blocked: replace provisional public domain before launch.' }
if ($sitemap -match 'crm\.html|patient\.html|teleconsult\.html|diet-plan\.html') { throw 'Release gate blocked: private route found in sitemap.' }
Write-Output 'PASS: release metadata has a definitive domain and no private URLs.'
