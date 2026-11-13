# Development-only launcher. No settings are persisted and no database data is seeded.
[CmdletBinding()]
param(
    [string]$Origin = 'http://localhost:5173',
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$JarPath = '',
    [ValidateRange(1024,65535)][int]$Port = 8080,
    [switch]$ReadOnly
)
$ErrorActionPreference='Stop'
$backend=Split-Path $PSScriptRoot -Parent
if([string]::IsNullOrWhiteSpace($JarPath)){$JarPath=Join-Path $backend 'target/backend-0.0.1-SNAPSHOT.jar'}
$uri=$null
if ($Origin -cnotmatch '^http://(localhost|127\.0\.0\.1):[0-9]+$' -or
    -not [Uri]::TryCreate($Origin,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'http' -or
    $uri.Host -notin @('localhost','127.0.0.1') -or $uri.Port -lt 1 -or $uri.UserInfo -ne '' -or
    $uri.Query -ne '' -or $uri.Fragment -ne '' -or $uri.AbsolutePath -ne '/' -or $Origin.EndsWith('/')) {
    throw 'Usa un origen HTTP loopback con puerto explicito y sin ruta.'
}
if (-not (Test-Path -LiteralPath $JarPath -PathType Leaf)) { throw 'Genera primero el JAR del backend con Maven package.' }
$java=if([string]::IsNullOrWhiteSpace($JavaHome)){'java'}else{Join-Path $JavaHome 'bin/java.exe'}
if (-not (Get-Command $java -ErrorAction SilentlyContinue)) { throw 'Configura JAVA_HOME con Java 21 o proporciona -JavaHome.' }
Push-Location $backend
try {
    if(Test-Path -LiteralPath .env){& (Join-Path $PSScriptRoot 'Load-LocalEnv.ps1')}
    $existing=$env:APP_CORS_ALLOWED_ORIGIN
    if([string]::IsNullOrWhiteSpace($existing) -and (Test-Path -LiteralPath config/application-local.properties)) {
        foreach($line in [IO.File]::ReadAllLines((Join-Path $backend 'config/application-local.properties'))) {
            if($line -match '^\s*app\.cors\.allowed-origin\s*[:=]\s*(.*?)\s*$'){$existing=$Matches[1]}
        }
    }
    if(-not [string]::IsNullOrWhiteSpace($existing) -and $existing -ne $Origin) {
        throw 'Hay otro origen CORS local configurado. Usa su mismo -Origin o revisa la configuracion; no se sobrescribira.'
    }
    if([string]::IsNullOrWhiteSpace($env:JWT_SECRET_BASE64)) { throw 'Configura JWT_SECRET_BASE64 privadamente antes de iniciar.' }
    $arguments=@('-jar',(Resolve-Path -LiteralPath $JarPath).Path,
        ('--server.port='+$Port),
        '--spring.profiles.active=local','--app.dev.seed-enabled=false',
        '--spring.jpa.hibernate.ddl-auto=validate','--spring.sql.init.mode=never',
        ('--app.cors.allowed-origin='+$Origin))
    if($ReadOnly){$arguments+='--spring.datasource.hikari.read-only=true'}
    Write-Output 'Iniciando backend local con CORS explicito, validacion de esquema e inicializador desactivado.'
    & $java @arguments
    if($LASTEXITCODE -ne 0){throw 'El backend no pudo iniciar; revisa su configuracion local sin compartir secretos.'}
} finally {Pop-Location}
