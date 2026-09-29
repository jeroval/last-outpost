param([switch]$Package)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework/v4.0.30319/csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw 'Compilateur .NET Framework Windows absent. Utiliser une archive du jeu deja preparee.'
}
$launcher = Join-Path $buildRoot 'LastOutpostLauncher.exe'
$source = Join-Path $projectRoot 'tools/launcher/Launcher.cs'
& $compiler /nologo /target:winexe /platform:anycpu /optimize+ /utf8output /codepage:65001 /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/out:$launcher" $source
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw 'Compilation du lanceur en echec.' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools/launcher/LastOutpostLauncher.exe.config') -Destination (Join-Path $buildRoot 'LastOutpostLauncher.exe.config') -Force
Write-Output "Lanceur cree : $launcher"

if ($Package) {
    $windows = Join-Path $buildRoot 'windows'
    $web = Join-Path $buildRoot 'web'
    foreach ($required in @('windows/LastOutpost.exe', 'web/index.html', 'web/index.js', 'web/index.wasm', 'web/index.pck')) {
        if (-not (Test-Path -LiteralPath (Join-Path $buildRoot $required) -PathType Leaf)) {
            throw "Archive complete impossible : $required absent. Executer les exports Windows et Web avant -Package."
        }
    }
    $instructions = Join-Path $buildRoot 'DEMARRER-ICI.txt'
    Copy-Item -LiteralPath (Join-Path $projectRoot 'tools/launcher/DEMARRER-ICI.txt') -Destination $instructions -Force
    $archive = Join-Path $buildRoot 'LastOutpost-Complet-Windows-Web.zip'
    Compress-Archive -LiteralPath @($launcher, (Join-Path $buildRoot 'LastOutpostLauncher.exe.config'), $instructions, $windows, $web) -DestinationPath $archive -Force
    Write-Output "Archive complete creee : $archive"
}
