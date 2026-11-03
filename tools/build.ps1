param([Parameter(Mandatory=$true)][string]$GowinExe)
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $GowinExe -PathType Leaf)) { throw 'GowinExe must point to gw_sh.exe.' }
& (Join-Path $PSScriptRoot 'setup.ps1')
Push-Location 'T:\'
try {
    $started = Get-Date
    & $GowinExe build.tcl *> build_latest.log
    if ($LASTEXITCODE -ne 0) { throw 'Build failed; inspect project/build_latest.log.' }
    $output = Get-Item -LiteralPath 'cam2dvi/impl/pnr/cam2dvi.fs' -ErrorAction Stop
    if ($output.LastWriteTime -lt $started) { throw 'No new bitstream produced.' }
    Write-Output 'Build finished. Inspect the new timing report before programming.'
} finally { Pop-Location }
