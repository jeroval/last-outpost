param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $SkipBuild) { & (Join-Path $projectRoot 'scripts/build-launcher.ps1') }
$launcher = Join-Path $projectRoot 'build/LastOutpostLauncher.exe'
$report = Join-Path $projectRoot 'build/launcher-test-report.txt'
$process = Start-Process -FilePath $launcher -ArgumentList @('--self-test', ('"' + $report + '"')) -PassThru -WindowStyle Hidden
if (-not $process.WaitForExit(30000)) {
    $process.Kill()
    throw 'Le test du lanceur a depasse 30 secondes.'
}
Get-Content -LiteralPath $report -Encoding UTF8
if ($process.ExitCode -ne 0) { throw "Tests du lanceur en echec : $($process.ExitCode)" }

# A copied executable must resolve exports beside itself, not from the working directory.
$fixtureRoot = Join-Path $projectRoot 'build/launcher path with spaces'
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$copiedLauncher = Join-Path $fixtureRoot 'LastOutpostLauncher.exe'
Copy-Item -LiteralPath $launcher -Destination $copiedLauncher -Force
$diagnostic = Join-Path $fixtureRoot 'diagnostic.txt'
$process = Start-Process -FilePath $copiedLauncher -ArgumentList @('--diagnose', ('"' + $diagnostic + '"')) -WorkingDirectory $env:WINDIR -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 2) { throw 'Le diagnostic doit signaler les exports absents par le code 2.' }
$contents = Get-Content -LiteralPath $diagnostic -Raw -Encoding UTF8
if (-not $contents.Contains('Windows: MISSING') -or -not $contents.Contains('Web: MISSING') -or -not $contents.Contains($fixtureRoot)) {
    throw 'Diagnostic incorrect depuis un chemin avec espaces.'
}
Write-Output 'PASS: copied launcher resolves its own directory and reports missing exports.'
