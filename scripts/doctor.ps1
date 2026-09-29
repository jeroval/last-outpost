param(
    [string]$GodotPath = '',
    [switch]$RequireWeb,
    [switch]$RequireWindows
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    Write-Error "Godot introuvable : $GodotPath. Installer Godot 4.7.2 ou fournir -GodotPath."
    exit 1
}

$godotExe = (Resolve-Path -LiteralPath $GodotPath).Path
$versionOutput = @(& $godotExe --version)
$godotExitCode = $LASTEXITCODE
$version = ([string]$versionOutput[0]).Trim()
if ($godotExitCode -ne 0 -or -not $version.StartsWith('4.7.2.stable.')) {
    Write-Error "Version Godot attendue : 4.7.2 stable ; version observée : $version"
    exit 1
}

foreach ($relativePath in @('project.godot', 'export_presets.cfg', 'scenes/main.tscn', 'scripts/main.gd', 'scenes/station.tscn', 'game/station_game.gd', 'data/content.json', 'tests/smoke.gd', 'tests/station_smoke.gd')) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $relativePath) -PathType Leaf)) {
        Write-Error "Fichier du projet manquant : $relativePath"
        exit 1
    }
}

Write-Output "Godot : $version"
Write-Output "Projet : $projectRoot"
if ($RequireWeb) {
    $template = Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable/web_nothreads_release.zip'
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        Write-Error "Modèle Web absent : $template. L'installer via Éditeur > Gérer les modèles d'exportation."
        exit 1
    }
    Write-Output "Modèle Web : $template"
}
if ($RequireWindows) {
    $template = Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe'
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        Write-Error "Modèle Windows absent : $template. L'installer via Éditeur > Gérer les modèles d'exportation."
        exit 1
    }
    Write-Output "Modèle Windows : $template"
}
