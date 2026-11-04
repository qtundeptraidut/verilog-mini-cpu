# Rebuild and run the mini 8-bit CPU testbench with Icarus Verilog.
# Usage: powershell -ExecutionPolicy Bypass -File .\run_tb.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$iverilog = "D:\PY_AI\iverilog\bin\iverilog.exe"
$vvp      = "D:\PY_AI\iverilog\bin\vvp.exe"

if (-not (Test-Path $iverilog)) { throw "iverilog not found at $iverilog" }
if (-not (Test-Path $vvp))      { throw "vvp not found at $vvp" }

New-Item -ItemType Directory -Force -Path "$root\build" | Out-Null

$rtl = @(
    "rtl\uart_rx.v",
    "rtl\uart_tx.v",
    "rtl\uart_to_ram_ctrl.v",
    "rtl\alu.v",
    "rtl\reg8.v",
    "rtl\cpu_fsm.v",
    "rtl\ram.v",
    "rtl\rom.v",
    "rtl\alu_ir.v",
    "rtl\pc.v",
    "rtl\top_system.v"
) | ForEach-Object { Join-Path $root $_ }

& $iverilog -g2012 -Wno-timescale -o "$root\build\tb_top_system.vvp" "$root\tb\tb_top_system.v" @rtl
if ($LASTEXITCODE -ne 0) { throw "iverilog compile failed" }

& $vvp "$root\build\tb_top_system.vvp"
if ($LASTEXITCODE -ne 0) { throw "simulation failed" }
