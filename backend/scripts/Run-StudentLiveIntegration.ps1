# Explicit live database write opt-in. Never invoke as part of Maven's default tests.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BackupPath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$BackupSha256,
    [Parameter(Mandatory=$true)][string]$ClasspathFile,
    [Parameter(Mandatory=$true)][string]$RunDirectory,
    [string]$JavaHome=$env:JAVA_HOME,
    [switch]$AuthorizeNewTestRecords,
    [switch]$ResumeCommittedFixture
)
$ErrorActionPreference='Stop'
if(-not $AuthorizeNewTestRecords){throw 'Se requiere autorizacion expresa para insertar datos ficticios en MySQL real.'}
$backend=Split-Path $PSScriptRoot -Parent
$run=[IO.Path]::GetFullPath($RunDirectory)
$allowed=[IO.Path]::GetFullPath((Join-Path (Split-Path $backend -Parent) 'secrets/student-live')).TrimEnd('\')+'\'
if(-not $run.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){throw 'El directorio debe estar dentro de secrets/student-live/.'}
$backupHash=[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($BackupPath))).Replace('-','')
if($backupHash -ne $BackupSha256){throw 'Respaldo ausente o huella distinta.'}
$cp=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $ClasspathFile).Path).Trim()
if([string]::IsNullOrWhiteSpace($JavaHome)){throw 'Configura JAVA_HOME con Java 21.'}
$java=Join-Path $JavaHome 'bin/java.exe'
if(-not (Test-Path -LiteralPath $java)){throw 'No se encontro Java en JAVA_HOME.'}
$env:LIVE_TEST_DIRECTORY=$run
$env:LIVE_TEST_BACKUP=(Resolve-Path -LiteralPath $BackupPath).Path
$env:LIVE_TEST_BACKUP_SHA256=$BackupSha256
$env:LIVE_TEST_AUTHORIZE='AUTHORIZED_NEW_TEST_RECORDS_3307'
$env:LIVE_TEST_RESUME=if($ResumeCommittedFixture){'VERIFY_COMMITTED_FIXTURE_ONLY'}else{''}
Push-Location $backend
try {
    & (Join-Path $PSScriptRoot 'Load-LocalEnv.ps1')
    # A separate ephemeral signing key keeps audit tokens out of the normal server session.
    $bytes=New-Object byte[] 32
    $rng=[Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes);$rng.Dispose()
    $env:JWT_SECRET_BASE64=[Convert]::ToBase64String($bytes)
    & $java -cp $cp (Join-Path $PSScriptRoot 'integration/StudentLiveIntegration.java')
    if($LASTEXITCODE -ne 0){throw 'Integracion detenida. Revisar estado y diario privados; no reintentar inserciones automaticamente.'}
} finally {Pop-Location}
