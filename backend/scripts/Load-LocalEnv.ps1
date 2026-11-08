# Loads only backend settings into the current process; never evaluates file contents.
[CmdletBinding()]
param([string]$EnvFile = (Join-Path (Split-Path $PSScriptRoot -Parent) '.env'))

$allowedNames = @(
    'SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD',
    'JWT_SECRET_BASE64', 'APP_CORS_ALLOWED_ORIGIN', 'APP_JWT_TTL_SECONDS', 'SERVER_PORT'
)
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) {
    throw 'No se encontro el archivo .env. Usa la plantilla o conserva el arranque habitual.'
}
try { $envLines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $EnvFile).Path) }
catch { throw 'No se pudo leer el archivo .env.' }
$pendingSettings = @{}
$lineNumber = 0
foreach ($envLine in $envLines) {
    $lineNumber++
    $entry = $envLine.Trim()
    if ($entry.Length -eq 0 -or $entry.StartsWith('#')) { continue }
    if ($entry -notmatch '^([A-Z][A-Z0-9_]*)\s*=(.*)$') {
        throw "Formato .env invalido en linea $lineNumber. Usa NOMBRE=valor."
    }
    $settingName = $Matches[1]
    $settingValue = $Matches[2].Trim()
    if ($settingName -notin $allowedNames -or $pendingSettings.ContainsKey($settingName)) {
        throw "Variable no permitida o duplicada en linea $lineNumber."
    }
    if ($settingValue.StartsWith('"') -or $settingValue.StartsWith("'")) {
        if ($settingValue.Length -lt 2 -or $settingValue[-1] -ne $settingValue[0]) {
            throw "Comillas sin cerrar en linea $lineNumber."
        }
        $settingValue = $settingValue.Substring(1, $settingValue.Length - 2)
    }
    if ($settingValue.Contains([char]0)) { throw "Valor invalido en linea $lineNumber." }
    $pendingSettings[$settingName] = $settingValue
}
# Validate the whole file before changing any process variable.
foreach ($settingName in $pendingSettings.Keys) {
    $settingValue = $pendingSettings[$settingName]
    if ($settingValue.Length -gt 0 -and
        $null -eq [Environment]::GetEnvironmentVariable($settingName, 'Process')) {
        [Environment]::SetEnvironmentVariable($settingName, $settingValue, 'Process')
    }
}
# Do not leave parsed values in the caller's scope when dot-sourced.
Remove-Variable envLines, envLine, entry, settingValue, pendingSettings, Matches -ErrorAction SilentlyContinue
