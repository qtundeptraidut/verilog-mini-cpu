# miniCPU-FPGA-VRL

A mini 8-bit CPU written in Verilog and controlled over UART.

This version fixes the previous implementation and adds a self-checking testbench.

## Clock review

<img width="1414" height="559" alt="image" src="https://github.com/user-attachments/assets/1973f425-d38a-4b88-9707-678a8d8736d7" />

## Data flow

<img width="1559" height="423" alt="image" src="https://github.com/user-attachments/assets/6b4cc26e-997a-47eb-8cc5-45525a6d977d" />

<img width="2048" height="1772" alt="image" src="https://github.com/user-attachments/assets/abc5117e-076f-4dd5-9a92-0637111165d5" />


## Repository layout

```text
rtl/          RTL source (UART, CPU, ALU, RAM/ROM)
tb/           Self-checking testbench
terminal/     Python UART terminal for the FPGA
run_tb.ps1    Build and run the testbench with Icarus Verilog
build/        Generated simulation artifacts (ignored)
```

## UART protocol

- 8N1, LSB first, idle high.
- Send three bytes:

| Byte | Destination | Description |
|------|-------------|-------------|
| 0 | RAM[0] | A |
| 1 | RAM[1] | B |
| 2 | RAM[2] | ALU mode (low nibble) |

After the third byte, the CPU runs: `LOAD A -> LOAD B -> LOAD MODE -> EXEC -> TX -> HALT`.
The ALU result is available on `led_out` and is transmitted back over UART.

## ALU modes

| Mode | Operation | Mode | Operation |
|------|-----------|------|-----------|
| 0x0 | ADD | 0x5 | ~A |
| 0x1 | SUB | 0x6 | ~B |
| 0x2 | AND | 0x7 | CMP |
| 0x3 | OR  | 0x8 | A |
| 0x4 | XOR | 0x9 | B |

For `CMP`: `LED1` = A < B, `LED2` = A == B, `LED3` = A > B.

`sw` selects `led_out`/`tx`:

```text
2'b00 alu_result
2'b01 regA
2'b10 regB
2'b11 status_reg
```

## Run the testbench

```powershell
powershell -ExecutionPolicy Bypass -File .\run_tb.ps1
```

Expected result:

```text
SUMMARY: ALL TESTS PASSED
```

## Python terminal

1. Install `pyserial`:

```powershell
py -m pip install pyserial
```

2. Edit `terminal/py` and set the correct `COM_PORT`.
3. Run:

```powershell
py terminal/py
```

4. Use the menu to send bytes, for example:

```text
math 5 + 3
```

or send the raw bytes:

```text
05 03 00
```

## Changes

- Rebuilt into separate RTL modules.
- Fixed UART receiver so back-to-back bytes are accepted.
- Fixed RAM write/read mux so the mode byte is stored correctly.
- CPU now waits for `system_run` and returns to `FETCH` after HALT.
- Fixed ALU compare result for `A == B`.
- Added a self-checking testbench and `run_tb.ps1`.
