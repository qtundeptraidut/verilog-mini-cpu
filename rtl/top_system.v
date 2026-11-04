`timescale 1ns/1ps
// ============================================================
// TOP_SYSTEM: mini 8-bit CPU with UART input/output.
//
// Protocol:
//   Host sends 3 bytes over UART (8N1, LSB first):
//     byte0 -> RAM[0] (A)
//     byte1 -> RAM[1] (B)
//     byte2 -> RAM[2] (ALU mode, low nibble used)
//   On the third byte the loader asserts system_run; the CPU executes:
//     LOAD A, LOAD B, LOAD MODE, EXEC, TX, HALT
//   The ALU result (or regA/regB/status_reg, selected by sw) is shown on
//   led_out and transmitted back over UART.
//
// sw selects led_out / tx_data:
//   2'b00 alu_result, 2'b01 regA, 2'b10 regB, 2'b11 status_reg
// ============================================================
module TOP_SYSTEM #(
    parameter CLKS_PER_BIT = 434
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output wire       tx,
    input  wire [1:0] sw,
    output wire [7:0] led_out
);
    wire [7:0] rx_data;
    wire       rx_ready;

    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_rx (
        .clk(clk), .rst_n(rst_n), .rx(rx),
        .rx_data(rx_data), .rx_ready(rx_ready)
    );

    // cpu_done is a one-cycle pulse asserted when the IR holds HALT.
    wire [3:0] opcode;
    reg halt_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) halt_d <= 1'b0;
        else        halt_d <= (opcode == 4'b0111);
    end
    wire cpu_done = (opcode == 4'b0111) & ~halt_d;

    wire       uart_ram_we;
    wire       system_run;
    wire [7:0] uart_ram_addr;
    wire [7:0] uart_ram_data;

    UART_TO_RAM_CTRL uart_ctrl (
        .clk(clk), .rst_n(rst_n),
        .rx_ready(rx_ready), .rx_data(rx_data), .cpu_done(cpu_done),
        .ram_we(uart_ram_we), .ram_addr(uart_ram_addr),
        .ram_data_out(uart_ram_data), .system_run(system_run)
    );

    wire [7:0] pc_out;
    wire [7:0] rom_data;
    wire [3:0] operand;
    wire pc_en, ir_load, en_A, en_B, en_Mode, alu_en, tx_start, tx_busy;

    ROM rom (.addr(pc_out), .data_out(rom_data));

    PC pc (
        .clk(clk), .rst_n(rst_n),
        .run_en(system_run), .pc_inc(pc_en), .pc_reset(cpu_done),
        .pc_out(pc_out)
    );

    ALU_IR ir (
        .clk(clk), .rst_n(rst_n), .load(ir_load), .instr_in(rom_data),
        .opcode(opcode), .operand(operand)
    );

    CPU_FSM fsm (
        .clk(clk), .rst_n(rst_n), .system_run(system_run), .tx_busy(tx_busy),
        .opcode(opcode), .operand(operand),
        .pc_en(pc_en), .ir_load(ir_load),
        .en_A(en_A), .en_B(en_B), .en_Mode(en_Mode),
        .alu_en(alu_en), .tx_start(tx_start)
    );

    wire [7:0] ram_data_out;
    // CPU never writes to RAM; when the loader pulses ram_we, use its address.
    wire [7:0] ram_addr = uart_ram_we ? uart_ram_addr : {4'b0000, operand};
    wire       ram_we   = uart_ram_we;

    RAM ram (
        .clk(clk), .write_en(ram_we), .data_in(uart_ram_data),
        .Addr(ram_addr), .data_out(ram_data_out)
    );

    wire [7:0] regA, regB, regMode;
    REG8 regA_inst (.clk(clk), .rst_n(rst_n), .en(en_A),    .d(ram_data_out), .q(regA));
    REG8 regB_inst (.clk(clk), .rst_n(rst_n), .en(en_B),    .d(ram_data_out), .q(regB));
    REG8 regM_inst (.clk(clk), .rst_n(rst_n), .en(en_Mode), .d(ram_data_out), .q(regMode));

    wire [7:0] alu_out;
    wire       carry_combo;
    wire       zero_combo;

    ALU_8BITD alu (
        .A(regA), .B(regB), .sel(regMode[3:0]),
        .outv(alu_out), .carry(carry_combo), .zero(zero_combo)
    );

    wire [7:0] alu_result;
    REG8 regALU (.clk(clk), .rst_n(rst_n), .en(alu_en), .d(alu_out), .q(alu_result));

    // Registered status flags, latched when the ALU executes.
    reg [7:0] status_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      status_reg <= 8'b00000000;
        else if (alu_en) status_reg <= {6'b000000, zero_combo, carry_combo};
    end

    wire [7:0] selected_data =
        (sw == 2'b00) ? alu_result :
        (sw == 2'b01) ? regA :
        (sw == 2'b10) ? regB :
                        status_reg;

    wire [7:0] tx_data = selected_data;

    UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_tx (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start),
        .tx_data(tx_data), .tx(tx), .tx_busy(tx_busy)
    );

    assign led_out = selected_data;
endmodule
