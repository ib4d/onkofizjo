param(
  [switch]$Reset
)

$ErrorActionPreference = 'Stop'
$ComposeFile = Join-Path $PSScriptRoot 'docker-compose.staging.yml'
$EnvFile = Join-Path $PSScriptRoot 'staging.env'

if (-not (Test-Path $EnvFile)) {
  throw "Missing $EnvFile. Copy staging.env.example to staging.env and replace both local passwords."
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) { throw 'Docker CLI is required. Install Docker Desktop, then rerun this script.' }
& docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose plugin is required: docker compose version failed.' }

function Compose([string[]]$Arguments) {
  & docker compose --env-file $EnvFile -f $ComposeFile @Arguments
  if ($LASTEXITCODE -ne 0) { throw "docker compose failed: $($Arguments -join ' ')" }
}

$settings = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^([^#][^=]*)=(.*)$' } | ForEach-Object {
  $settings[$Matches[1]] = $Matches[2]
}
foreach ($name in @('ONKOFIZJO_STAGING_ADMIN_PASSWORD', 'ONKOFIZJO_STAGING_APP_PASSWORD')) {
  if (-not $settings[$name] -or $settings[$name] -like 'replace-with-*') { throw "$name must be replaced in staging.env." }
}

if ($Reset) {
  Write-Warning 'Reset requested: removing only the onkofizjo staging container volume.'
  Compose @('down', '-v')
}

Compose @('up', '-d')
$containerId = (& docker compose --env-file $EnvFile -f $ComposeFile ps -q postgres).Trim()
if (-not $containerId) { throw 'Could not resolve the PostgreSQL staging container.' }
$health = ''
for ($attempt = 0; $attempt -lt 30; $attempt++) {
  Start-Sleep -Seconds 2
  $health = (& docker inspect --format '{{.State.Health.Status}}' $containerId 2>$null)
  if ($health -eq 'healthy') { break }
}
if ($health -ne 'healthy') { throw "PostgreSQL staging did not become healthy (last status: $health)." }

$adminEnv = 'PGPASSWORD=' + $settings['ONKOFIZJO_STAGING_ADMIN_PASSWORD']
$schemaExists = (& docker compose --env-file $EnvFile -f $ComposeFile exec -T -e $adminEnv postgres psql -h 127.0.0.1 -U $settings['ONKOFIZJO_STAGING_ADMIN_USER'] -d $settings['ONKOFIZJO_STAGING_DB_NAME'] -tAc "SELECT to_regclass('onkofizjo.audit_events')" 2>$null).Trim()
if ($schemaExists -and -not $Reset) { throw 'Staging schema already exists. Use -Reset explicitly to rebuild only this synthetic database.' }

Get-Content (Join-Path $PSScriptRoot '001_initial_production.sql') -Raw | & docker compose --env-file $EnvFile -f $ComposeFile exec -T -e $adminEnv postgres psql -h 127.0.0.1 -U $settings['ONKOFIZJO_STAGING_ADMIN_USER'] -d $settings['ONKOFIZJO_STAGING_DB_NAME'] -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) { throw 'Production schema migration failed in staging.' }

$appPasswordSql = $settings['ONKOFIZJO_STAGING_APP_PASSWORD'].Replace("'", "''")
$appUser = $settings['ONKOFIZJO_STAGING_APP_USER']
$grantSql = @"
DO `$`$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$appUser') THEN
    CREATE ROLE $appUser LOGIN PASSWORD '$appPasswordSql';
  ELSE
    ALTER ROLE $appUser LOGIN PASSWORD '$appPasswordSql';
  END IF;
END `$`$;
GRANT CONNECT ON DATABASE $($settings['ONKOFIZJO_STAGING_DB_NAME']) TO $appUser;
GRANT USAGE ON SCHEMA onkofizjo TO $appUser;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA onkofizjo TO $appUser;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA onkofizjo TO $appUser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA onkofizjo TO $appUser;
"@
$grantSql | & docker compose --env-file $EnvFile -f $ComposeFile exec -T -e $adminEnv postgres psql -h 127.0.0.1 -U $settings['ONKOFIZJO_STAGING_ADMIN_USER'] -d $settings['ONKOFIZJO_STAGING_DB_NAME'] -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) { throw 'Application role grant failed.' }

Get-Content (Join-Path $PSScriptRoot 'staging-fixtures.sql') -Raw | & docker compose --env-file $EnvFile -f $ComposeFile exec -T -e $adminEnv postgres psql -h 127.0.0.1 -U $settings['ONKOFIZJO_STAGING_ADMIN_USER'] -d $settings['ONKOFIZJO_STAGING_DB_NAME'] -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) { throw 'Synthetic staging fixtures failed.' }

$appEnv = 'PGPASSWORD=' + $settings['ONKOFIZJO_STAGING_APP_PASSWORD']
Get-Content (Join-Path $PSScriptRoot 'staging_rls_checks.sql') -Raw | & docker compose --env-file $EnvFile -f $ComposeFile exec -T -e $appEnv postgres psql -h 127.0.0.1 -U $appUser -d $settings['ONKOFIZJO_STAGING_DB_NAME'] -v ON_ERROR_STOP=1 -v subject_gosia=staging-gosia -v subject_collaborator_a=staging-collaborator-a -v patient_a=30000000-0000-4000-8000-000000000001 -v patient_b=30000000-0000-4000-8000-000000000002 -v diet_plan_id=50000000-0000-4000-8000-000000000001
if ($LASTEXITCODE -ne 0) { throw 'Staging RLS harness failed.' }

Write-Output 'PASS: isolated PostgreSQL staging migration, fixtures and RLS harness completed.'
