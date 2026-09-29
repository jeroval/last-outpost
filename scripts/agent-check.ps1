param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$SkillsPath = '.agents/skills'
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$problems = New-Object 'System.Collections.Generic.List[string]'

function Test-LocalReference([string]$BaseDirectory, [string]$Reference, [string]$Origin) {
    if ($Reference -match '^(https?://|mailto:|#)') { return }
    $relative = [Uri]::UnescapeDataString(($Reference -split '#', 2)[0].Trim('<', '>'))
    if (-not $relative) { return }
    $targetPath = [IO.Path]::GetFullPath((Join-Path $BaseDirectory $relative))
    if (-not $targetPath.StartsWith($rootPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        $problems.Add("Reference hors du depot dans ${Origin}: $Reference")
        return
    }
    if (-not (Test-Path -LiteralPath $targetPath)) {
        $problems.Add("Reference absente dans ${Origin}: $Reference")
    }
}

foreach ($required in @('docs/agent/PROJECT.md', 'docs/agent/OPERATIONS.md', 'docs/agent/UPDATES.md', 'docs/agent/BUGS.json', 'docs/knowledge/INDEX.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $rootPath $required) -PathType Leaf)) {
        $problems.Add("Fichier requis absent : $required")
    }
}

$skillRoot = Join-Path $rootPath $SkillsPath
$skillFiles = @()
if (Test-Path -LiteralPath $skillRoot -PathType Container) {
    $skillFiles = @(Get-ChildItem -LiteralPath $skillRoot -Filter SKILL.md -File -Recurse)
}
if ($skillFiles.Count -eq 0) { $problems.Add("Aucun SKILL.md dans $SkillsPath") }
$skillNames = @{}
foreach ($skillFile in $skillFiles) {
    $content = Get-Content -LiteralPath $skillFile.FullName -Raw -Encoding UTF8
    if ($content -notmatch '(?s)\A---\r?\n(.*?)\r?\n---') {
        $problems.Add("Frontmatter absent : $($skillFile.FullName)")
        continue
    }
    $frontmatter = $Matches[1]
    if ($frontmatter -notmatch '(?m)^name:\s*([a-z0-9-]{1,64})\s*$') {
        $problems.Add("Nom de skill invalide : $($skillFile.FullName)")
        continue
    }
    $name = $Matches[1]
    if ($name -ne $skillFile.Directory.Name) { $problems.Add("Nom/dossier differents : $name") }
    if ($skillNames.ContainsKey($name)) { $problems.Add("Nom de skill duplique : $name") }
    $skillNames[$name] = $true
    if ($frontmatter -notmatch '(?m)^description:\s*\S.+$') { $problems.Add("Description absente : $name") }
    if ($content -match '\[TODO|TODO:|\[INSERT') { $problems.Add("Scaffold inacheve : $name") }
}

$markdownFiles = @($skillFiles)
foreach ($folder in @('docs/agent', 'docs/knowledge')) {
    $fullFolder = Join-Path $rootPath $folder
    if (Test-Path -LiteralPath $fullFolder) {
        $markdownFiles += @(Get-ChildItem -LiteralPath $fullFolder -Filter '*.md' -File -Recurse | Where-Object { $_.FullName -notmatch '[\\/]reference[\\/]|[\\/]candidates[\\/]' })
    }
}
foreach ($file in $markdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($link in [regex]::Matches($content, '\[[^\]]*\]\(([^\s)]+)\)')) {
        Test-LocalReference $file.Directory.FullName $link.Groups[1].Value $file.Name
    }
}

$bugFile = Join-Path $rootPath 'docs/agent/BUGS.json'
$issueCount = 0
if (Test-Path -LiteralPath $bugFile) {
    try {
        $register = Get-Content -LiteralPath $bugFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($register.schema_version -ne 1) { $problems.Add('Version du registre bugs non supportee.') }
        if (-not ($register.issues -is [Array])) { $problems.Add('issues doit etre un tableau JSON.') }
        $ids = @{}
        foreach ($issue in $register.issues) {
            $issueCount++
            if ($issue.id -notmatch '^LO-[0-9]{3}$') { $problems.Add("Identifiant invalide : $($issue.id)") }
            if ($ids.ContainsKey([string]$issue.id)) { $problems.Add("Bug duplique : $($issue.id)") }
            $ids[[string]$issue.id] = $true
            foreach ($field in @('title', 'severity', 'status', 'expected', 'actual', 'fix', 'updated')) {
                if ([string]::IsNullOrWhiteSpace([string]$issue.$field)) { $problems.Add("$($issue.id) : champ $field vide") }
            }
            if ($issue.status -notin @('open', 'in_progress', 'fixed_pending_verification', 'verified', 'deferred')) { $problems.Add("$($issue.id) : statut invalide") }
            if ($issue.severity -notin @('low', 'medium', 'high', 'critical')) { $problems.Add("$($issue.id) : gravite invalide") }
            if (@($issue.reproduction).Count -eq 0) { $problems.Add("$($issue.id) : reproduction absente") }
            if ($issue.updated -notmatch '^\d{4}-\d{2}-\d{2}$') { $problems.Add("$($issue.id) : date invalide") }
            $hasPass = $false
            foreach ($proof in $issue.evidence) {
                foreach ($field in @('date', 'command', 'result')) {
                    if ([string]::IsNullOrWhiteSpace([string]$proof.$field)) { $problems.Add("$($issue.id) : preuve sans $field") }
                }
                if ($proof.verdict -eq 'pass') { $hasPass = $true }
                if (@($proof.refs).Count -eq 0) { $problems.Add("$($issue.id) : preuve sans reference") }
                foreach ($ref in $proof.refs) { Test-LocalReference $rootPath $ref $issue.id }
            }
            if ($issue.status -eq 'verified' -and -not $hasPass) { $problems.Add("$($issue.id) : verified exige une preuve avec verdict pass") }
        }
    } catch {
        $problems.Add("Registre bugs illisible : $($_.Exception.Message)")
    }
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) { Write-Output "ECHEC : $problem" }
    exit 1
}
Write-Output "AGENT CHECK OK : $($skillFiles.Count) skills, $issueCount bugs, liens locaux verifies."
Write-Output 'Portee : coherence locale uniquement ; jeu, decouverte native et CI non testes par cette commande.'
exit 0
