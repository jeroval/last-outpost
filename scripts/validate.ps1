param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
}

& (Join-Path $PSScriptRoot 'doctor.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$godotExe = (Resolve-Path -LiteralPath $GodotPath).Path
function Invoke-GodotCheck {
    param([string[]]$Arguments, [string]$Marker = '')
    $savedPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $godotExe @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedPreference
    }
    $output | ForEach-Object { Write-Output $_.ToString() }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($code -ne 0 -or $text -match '(?m)(SCRIPT ERROR:|Parse Error:|^ERROR:)') {
        throw "Godot validation failed (exit=$code). See output above."
    }
    if ($Marker -and -not $text.Contains($Marker)) {
        throw "Godot test did not report completion: $Marker"
    }
}

Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--import')
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/smoke.gd') -Marker 'PLAYTEST OK'
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/station_smoke.gd') -Marker 'STATION OK'
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/progression_smoke.gd') -Marker 'PROGRESSION OK'
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/ux_smoke.gd') -Marker 'UX OK'
& (Join-Path $PSScriptRoot 'agent-check.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output 'Validation locale OK : colonie, station, progression, UX et suivi agentique.'
