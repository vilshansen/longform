# Validates that index.json entries match the Markdown files on disk.
# Exit code 0 = OK (warnings allowed), 1 = errors found (blocks commit).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $repoRoot "index.json"
$errors = @()
$warnings = @()

if (-not (Test-Path $indexPath)) {
    Write-Host "FAIL: $indexPath not found." -ForegroundColor Red
    exit 1
}

try {
    $items = @(Get-Content $indexPath -Raw | ConvertFrom-Json)
}
catch {
    Write-Host "FAIL: index.json is not valid JSON - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$indexFiles = @($items | ForEach-Object { $_.file } | Where-Object { $_ })

$indexFiles | Group-Object | Where-Object Count -gt 1 | ForEach-Object {
    $errors += "DUPLICATE: '$($_.Name)' appears $($_.Count) times in index.json."
}

foreach ($f in $indexFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $f))) {
        $errors += "MISSING: index.json entry '$f' has no corresponding file."
    }
}

$mdFiles = @(Get-ChildItem $repoRoot -Filter *.md -File | ForEach-Object { $_.Name })
foreach ($f in $mdFiles) {
    if ($f -notin $indexFiles) {
        $warnings += "UNINDEXED: '$f' exists on disk but has no entry in index.json."
    }
}

foreach ($w in $warnings) { Write-Host "WARN: $w" -ForegroundColor Yellow }
if ($errors.Count -gt 0) {
    Write-Host ("Index check FAILED - {0} error(s):" -f $errors.Count) -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "Index check passed: $($indexFiles.Count) entries, all files consistent."
exit 0
