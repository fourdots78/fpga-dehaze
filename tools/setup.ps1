param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $packageRoot 'project')).Path.TrimEnd('\')
$mapping = @(& subst.exe) | Where-Object { $_ -match '^T:\\: => ' }
$mappedRoot = if ($mapping) { ($mapping -replace '^T:\\: => ', '').TrimEnd('\') } else { '' }
$ready = $mappedRoot -and [string]::Equals($mappedRoot,$projectRoot,[StringComparison]::OrdinalIgnoreCase)
if ($CheckOnly) { [pscustomobject]@{RequiredRoot=$projectRoot;CurrentRoot=$mappedRoot;Ready=[bool]$ready}; return }
if ($ready) { Write-Output 'T: already maps to this package.'; return }
if ($mapping -or (Test-Path -LiteralPath 'T:\')) { throw 'T: is occupied. Preserve the existing mapping; use a machine/session with T: free or review the mapping before changing it.' }
& subst.exe T: $projectRoot
if ($LASTEXITCODE -ne 0) { throw 'Failed to map T:.' }
Write-Output 'Ready: open T:\cam2dvi\cam2dvi.gprj'
