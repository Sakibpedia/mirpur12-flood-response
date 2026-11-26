# Runs all 15 flood rescue operations headlessly.
param([string]$Godot = "godot", [switch]$KeepLogs)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dir = Join-Path $PSScriptRoot "out"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$failed = @()
for ($o = 1; $o -le 15; $o++) {
    $env:OP = "$o"
    $log = Join-Path $dir "op_$o.log"
    & $Godot --headless --path $root "res://tools/test/OperationTest.tscn" *> $log
    $code = $LASTEXITCODE
    $line = (Select-String -Path $log -Pattern '\[OP\]' | Select-Object -Last 1).Line
    Write-Output "O$o (exit $code): $line"
    if ($code -ne 0 -or $line -notmatch '\[OP\] PASS') {
        $failed += $o
        Select-String -Path $log -Pattern 'FAIL|SCRIPT ERROR' | Select-Object -First 6 |
            ForEach-Object { Write-Output "    $($_.Line.Trim())" }
    }
    if (-not $KeepLogs) { Remove-Item $log -Force }
}
Remove-Item Env:OP -ErrorAction SilentlyContinue
if ($failed.Count -gt 0) { throw "Failing operations: $($failed -join ', ')" }
Write-Output "[OP] ALL 15 OPERATIONS PASS"
