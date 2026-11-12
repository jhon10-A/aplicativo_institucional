# Runs only a fake java function against a temporary backend; never connects to MySQL.
$ErrorActionPreference='Stop'
$fixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('student-launcher-'+[guid]::NewGuid())
$temporaryScripts=Join-Path $fixtureRoot 'scripts'
$originalToken=$env:JWT_SECRET_BASE64
$originalOrigin=$env:APP_CORS_ALLOWED_ORIGIN
function global:java { $global:studentLauncherArguments=@($args); $global:LASTEXITCODE=0 }
function Assert-Launcher([bool]$Condition,[string]$Name){if(-not $Condition){throw ('Fallo del launcher: '+$Name)}}
try {
    New-Item -ItemType Directory -Path $temporaryScripts -Force | Out-Null
    foreach($name in @('Run-LocalBackend.ps1','Load-LocalEnv.ps1')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $temporaryScripts $name)}
    $jar=Join-Path $fixtureRoot 'fixture.jar'
    [IO.File]::WriteAllText($jar,'not-a-real-jar')
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'target') | Out-Null
    Copy-Item -LiteralPath $jar -Destination (Join-Path $fixtureRoot 'target/backend-0.0.1-SNAPSHOT.jar')
    [IO.File]::WriteAllText((Join-Path $fixtureRoot '.env'),"JWT_SECRET_BASE64=fixture-only-not-a-key`n")
    [Environment]::SetEnvironmentVariable('JWT_SECRET_BASE64',$null,'Process')
    [Environment]::SetEnvironmentVariable('APP_CORS_ALLOWED_ORIGIN',$null,'Process')
    $launcher=Join-Path $temporaryScripts 'Run-LocalBackend.ps1'
    & $launcher -JavaHome '' -Port 18081 -ReadOnly | Out-Null
    Assert-Launcher ($global:studentLauncherArguments -contains '--app.cors.allowed-origin=http://localhost:5173') 'origen local explicito'
    foreach($flag in @('--app.dev.seed-enabled=false','--spring.sql.init.mode=never','--spring.jpa.hibernate.ddl-auto=validate','--spring.datasource.hikari.read-only=true','--server.port=18081')) {
        Assert-Launcher ($global:studentLauncherArguments -contains $flag) 'arranque protegido'
    }
    $env:APP_CORS_ALLOWED_ORIGIN='http://127.0.0.1:5174'
    $rejected=$false
    try {& $launcher -JavaHome '' -JarPath $jar | Out-Null}catch{$rejected=$true}
    Assert-Launcher $rejected 'no sobrescribe otro origen autorizado'
    & $launcher -JavaHome '' -JarPath $jar -Origin 'http://127.0.0.1:5174' | Out-Null
    Assert-Launcher ($global:studentLauncherArguments -contains '--app.cors.allowed-origin=http://127.0.0.1:5174') 'conserva loopback configurado'
    foreach($invalidOrigin in @('*','http://localhost','http://localhost:5173/','https://example.invalid')) {
        $rejected=$false
        try {& $launcher -JavaHome '' -JarPath $jar -Origin $invalidOrigin | Out-Null}catch{$rejected=$true}
        Assert-Launcher $rejected 'rechaza origen invalido'
    }
    Write-Output 'Launcher aprobado: origen explicito, alternativas conservadas, sin inicializacion SQL ni MySQL.'
} finally {
    [Environment]::SetEnvironmentVariable('JWT_SECRET_BASE64',$originalToken,'Process')
    [Environment]::SetEnvironmentVariable('APP_CORS_ALLOWED_ORIGIN',$originalOrigin,'Process')
    Remove-Item Function:\java -ErrorAction SilentlyContinue
    $resolved=[IO.Path]::GetFullPath($fixtureRoot)
    $tempBase=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if($resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf).StartsWith('student-launcher-')) {
        if(Test-Path -LiteralPath $resolved){Remove-Item -LiteralPath $resolved -Recurse -Force}
    }
}
