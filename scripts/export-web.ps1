param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
}

& (Join-Path $PSScriptRoot 'doctor.ps1') -GodotPath $GodotPath -RequireWeb
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$webDirectory = Join-Path $projectRoot 'build/web'
New-Item -ItemType Directory -Path $webDirectory -Force | Out-Null
$godotExe = (Resolve-Path -LiteralPath $GodotPath).Path
& $godotExe --headless --path $projectRoot --export-release Web 'build/web/index.html'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

foreach ($fileName in @('index.html', 'index.js', 'index.pck', 'index.wasm')) {
    $file = Join-Path $webDirectory $fileName
    if (-not (Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0) {
        Write-Error "Export Web incomplet : $fileName"
        exit 1
    }
}
$licenseSource = Join-Path $projectRoot 'assets/third_party/polybuild_trees/LICENSE.md'
Copy-Item -LiteralPath $licenseSource -Destination (Join-Path $webDirectory 'THIRD_PARTY_LICENSES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/GODOT_LICENSE.txt') -Destination (Join-Path $webDirectory 'GODOT_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/GODOT_COPYRIGHT.txt') -Destination (Join-Path $webDirectory 'GODOT_COPYRIGHT.txt')
Write-Output "Export Web créé : $webDirectory"
