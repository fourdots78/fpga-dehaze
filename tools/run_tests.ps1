param([Parameter(Mandatory=$true)][string]$VsimExe)
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $VsimExe -PathType Leaf)) { throw 'VsimExe must point to vsim.exe.' }
& (Join-Path $PSScriptRoot 'setup.ps1')
Push-Location 'T:\'
try {
    foreach ($caseName in @('controls','capture','sign','osd','pipeline_pedestrian','pipeline_children','pipeline','pipeline_slip')) {
        $logPath = "sim/${caseName}_rerun.log"
        & $VsimExe -c -do "sim/run_$caseName.do" -l $logPath *> "sim/${caseName}_rerun_stdout.log"
        if ($LASTEXITCODE -ne 0) { throw "Simulation command failed: $caseName" }
        $log = Get-Content -LiteralPath $logPath -Raw
        if ($log -notmatch 'PASS' -or $log -match '(?m)^# FAIL|\*\* Fatal|\*\* Error') { throw "Simulation failed: $caseName" }
        Write-Output "PASS: $caseName"
    }
} finally { Pop-Location }
