$ErrorActionPreference = 'Stop'
$rootPath = Split-Path -Parent $PSScriptRoot
$cachePath = [IO.Path]::GetFullPath((Join-Path $rootPath '.godot'))
$fixturePath = Join-Path $cachePath ('agent-check-fixture-' + [Guid]::NewGuid().ToString('N'))
$checker = Join-Path $PSScriptRoot 'agent-check.ps1'
$utf8 = New-Object Text.UTF8Encoding($false)

function Write-Fixture([string]$RelativePath, [string]$Content) {
    $filePath = Join-Path $fixturePath $RelativePath
    [IO.Directory]::CreateDirectory((Split-Path -Parent $filePath)) | Out-Null
    [IO.File]::WriteAllText($filePath, $Content, $utf8)
}

function Assert-Check([int]$ExpectedExit, [string]$ExpectedMessage) {
    $result = @(& powershell -NoProfile -File $checker -RepositoryRoot $fixturePath)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne $ExpectedExit -or ($result -join "`n") -notmatch [regex]::Escape($ExpectedMessage)) {
        throw "Resultat inattendu : code $exitCode, attendu $ExpectedExit. $($result -join ' ')"
    }
}

try {
    foreach ($path in @('docs/agent/PROJECT.md', 'docs/agent/OPERATIONS.md', 'docs/agent/UPDATES.md', 'docs/knowledge/INDEX.md')) {
        Write-Fixture $path '# Fixture isolee'
    }
    Write-Fixture '.agents/skills/fixture/SKILL.md' "---`nname: fixture`ndescription: Verifier un registre dans un depot temporaire.`n---`nProcedure de fixture."
    $issue = [ordered]@{
        id = 'LO-001'; title = 'Fixture'; severity = 'medium'; status = 'verified'
        reproduction = @('Action de test'); expected = 'Resultat'; actual = 'Defaut'; fix = 'Correction'
        evidence = @([ordered]@{ date = '2026-09-29'; command = 'Test isole'; result = 'Passe'; verdict = 'pass'; refs = @('docs/agent/PROJECT.md') })
        updated = '2026-09-29'
    }
    $register = [ordered]@{ schema_version = 1; updated = '2026-09-29'; issues = @($issue) }
    Write-Fixture 'docs/agent/BUGS.json' ($register | ConvertTo-Json -Depth 8)
    Assert-Check 0 'AGENT CHECK OK'

    $issue.evidence[0].refs = @('preuve-absente.txt')
    Write-Fixture 'docs/agent/BUGS.json' ($register | ConvertTo-Json -Depth 8)
    Assert-Check 1 'Reference absente'
    $issue.evidence[0].refs = @('docs/agent/PROJECT.md')
    $issue.evidence[0].verdict = 'observed'
    Write-Fixture 'docs/agent/BUGS.json' ($register | ConvertTo-Json -Depth 8)
    Assert-Check 1 'verified exige une preuve'

    $issue.evidence[0].verdict = 'pass'
    $register.issues = @($issue, $issue)
    Write-Fixture 'docs/agent/BUGS.json' ($register | ConvertTo-Json -Depth 8)
    Assert-Check 1 'Bug duplique'
    Write-Fixture 'docs/agent/BUGS.json' '{invalide'
    Assert-Check 1 'Registre bugs illisible'

    Write-Output 'AGENT CHECK SELFTEST OK : cas valide, preuve absente, fausse cloture, doublon et JSON invalide.'
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixturePath)
    if (-not $resolvedFixture.StartsWith($cachePath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Suppression refusee : fixture hors du cache du projet.'
    }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
