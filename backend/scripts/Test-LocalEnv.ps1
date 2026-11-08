$ErrorActionPreference = 'Stop'
$loader = Join-Path $PSScriptRoot 'Load-LocalEnv.ps1'
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('student-env-' + [guid]::NewGuid() + '.txt')
$names = @('SERVER_PORT', 'APP_CORS_ALLOWED_ORIGIN', 'APP_JWT_TTL_SECONDS')
$previousSettings = @{}
foreach ($name in $names) {
    $previousSettings[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
function Assert-Condition([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw "Fallo: $Label (valores omitidos)." }
}
function Set-Fixture([string]$Content) { [System.IO.File]::WriteAllText($fixture, $Content) }
try {
    Set-Fixture "# comment`nSERVER_PORT=8091`nAPP_CORS_ALLOWED_ORIGIN='http://localhost:5173'`nAPP_JWT_TTL_SECONDS=`n"
    $output = & $loader -EnvFile $fixture
    Assert-Condition ($null -eq $output) 'sin salida de valores'
    Assert-Condition ($env:SERVER_PORT -eq '8091') 'carga variable'
    Assert-Condition ($env:APP_CORS_ALLOWED_ORIGIN -eq 'http://localhost:5173') 'quita comillas'
    Assert-Condition ($null -eq [Environment]::GetEnvironmentVariable('APP_JWT_TTL_SECONDS', 'Process')) 'ignora vacios'
    Set-Fixture 'SERVER_PORT=8092'
    & $loader -EnvFile $fixture
    Assert-Condition ($env:SERVER_PORT -eq '8091') 'entorno existente tiene prioridad'

    [Environment]::SetEnvironmentVariable('SERVER_PORT', $null, 'Process')
    Set-Fixture 'SERVER_PORT=$(not-executed)#literal=a'
    & $loader -EnvFile $fixture
    Assert-Condition ($env:SERVER_PORT -eq '$(not-executed)#literal=a') 'sin evaluacion o interpolacion'

    foreach ($content in @("SERVER_PORT=8093`nUNSUPPORTED_SETTING=marker", "SERVER_PORT='unclosed", "SERVER_PORT=8093`nSERVER_PORT=8094", 'export SERVER_PORT=8093')) {
        [Environment]::SetEnvironmentVariable('SERVER_PORT', $null, 'Process')
        Set-Fixture $content
        $rejected = $false
        try { & $loader -EnvFile $fixture } catch { $rejected = $true }
        Assert-Condition $rejected 'rechaza formato, variable o duplicado'
        Assert-Condition ($null -eq [Environment]::GetEnvironmentVariable('SERVER_PORT', 'Process')) 'validacion atomica'
    }
    $rejected = $false
    try { & $loader -EnvFile ($fixture + '.missing') } catch { $rejected = $true }
    Assert-Condition $rejected 'archivo ausente'
    Write-Output 'Pruebas .env aprobadas: carga, comillas, vacios, prioridad, literales, errores y ausencia. Sin credenciales reales.'
}
finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previousSettings[$name], 'Process') }
    if ([System.IO.File]::Exists($fixture)) { [System.IO.File]::Delete($fixture) }
}
