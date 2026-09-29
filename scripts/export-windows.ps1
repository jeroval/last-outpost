param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
}

& (Join-Path $PSScriptRoot 'doctor.ps1') -GodotPath $GodotPath -RequireWindows
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$windowsDirectory = Join-Path $projectRoot 'build/windows'
New-Item -ItemType Directory -Path $windowsDirectory -Force | Out-Null
$godotExe = (Resolve-Path -LiteralPath $GodotPath).Path
& $godotExe --headless --path $projectRoot --export-release 'Windows Desktop' 'build/windows/LastOutpost.exe'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$gameExe = Join-Path $windowsDirectory 'LastOutpost.exe'
if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf) -or (Get-Item -LiteralPath $gameExe).Length -lt 1000000) {
    Write-Error 'Export Windows incomplet : LastOutpost.exe'
    exit 1
}

Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/third_party/polybuild_trees/LICENSE.md') -Destination (Join-Path $windowsDirectory 'THIRD_PARTY_LICENSES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/GODOT_LICENSE.txt') -Destination (Join-Path $windowsDirectory 'GODOT_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/GODOT_COPYRIGHT.txt') -Destination (Join-Path $windowsDirectory 'GODOT_COPYRIGHT.txt')
@'
LAST OUTPOST - VERSION WINDOWS 64 BITS

Double-cliquez sur LastOutpost.exe pour jouer. Aucun editeur Godot n'est necessaire.
Les fichiers de licences fournis avec le jeu doivent rester dans le dossier lors d'un partage.
'@ | Set-Content -LiteralPath (Join-Path $windowsDirectory 'LISEZ-MOI.txt') -Encoding UTF8

$archive = Join-Path $projectRoot 'build/LastOutpost-Windows-x64.zip'
$files = @(
    $gameExe,
    (Join-Path $windowsDirectory 'THIRD_PARTY_LICENSES.md'),
    (Join-Path $windowsDirectory 'GODOT_LICENSE.txt'),
    (Join-Path $windowsDirectory 'GODOT_COPYRIGHT.txt'),
    (Join-Path $windowsDirectory 'LISEZ-MOI.txt')
)
Compress-Archive -LiteralPath $files -DestinationPath $archive -Force
if (-not (Test-Path -LiteralPath $archive -PathType Leaf) -or (Get-Item -LiteralPath $archive).Length -eq 0) {
    Write-Error 'Archive Windows incomplète.'
    exit 1
}
Write-Output "Jeu Windows créé : $gameExe"
Write-Output "Archive à partager : $archive"

# The complete archive is opt-in so it cannot silently include an older Web export.
& (Join-Path $PSScriptRoot 'build-launcher.ps1')
Write-Output 'Pour regrouper les deux exports a jour : scripts/build-launcher.ps1 -Package'
