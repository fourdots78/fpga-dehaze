$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$hashes = Get-Content -LiteralPath (Join-Path $packageRoot 'SHA256SUMS.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$checked = 0
foreach ($entry in $hashes.PSObject.Properties) {
    $target = Join-Path $packageRoot $entry.Name
    if (!(Test-Path -LiteralPath $target -PathType Leaf)) { throw "Missing file: $($entry.Name)" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.Value) { throw "Hash mismatch: $($entry.Name)" }
    $checked++
}
Write-Output "PASS: $checked package files verified."
