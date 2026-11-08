# Verifies PowerShell -> Maven -> Spring using only temporary, fictitious settings.
[CmdletBinding()]
param([string]$MavenCommand = (Join-Path (Split-Path $PSScriptRoot -Parent) 'mvnw.cmd'))

$ErrorActionPreference = 'Stop'
$backend = Split-Path $PSScriptRoot -Parent
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('spring-env-' + [guid]::NewGuid() + '.txt')
$settings = @{
    SPRING_DATASOURCE_URL = 'jdbc:mysql://127.0.0.1:1/unused'
    SPRING_DATASOURCE_USERNAME = 'env-fixture-user'
    SPRING_DATASOURCE_PASSWORD = 'fixture-only-not-a-secret'
    JWT_SECRET_BASE64 = 'fixture-only-not-a-key'
    APP_CORS_ALLOWED_ORIGIN = 'http://localhost:18091'
    APP_JWT_TTL_SECONDS = '1800'
    SERVER_PORT = '18091'
}
$names = @($settings.Keys) + @('LOCAL_ENV_PROCESS_TEST')
$previousSettings = @{}
foreach ($name in $names) {
    $previousSettings[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
Push-Location $backend
try {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $null, 'Process') }
    $lines = foreach ($name in $settings.Keys) { '{0}={1}' -f $name, $settings[$name] }
    [System.IO.File]::WriteAllLines($fixture, [string[]]$lines)
    & (Join-Path $PSScriptRoot 'Load-LocalEnv.ps1') -EnvFile $fixture
    $env:LOCAL_ENV_PROCESS_TEST = 'true'
    & $MavenCommand --offline '-Dtest=LocalConfigurationTests' test
    if ($LASTEXITCODE -ne 0) { throw 'Fallo la prueba aislada de configuracion Spring.' }
}
finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previousSettings[$name], 'Process') }
    if ([System.IO.File]::Exists($fixture)) { [System.IO.File]::Delete($fixture) }
    Pop-Location
}
