`timescale 1ns/1ps
// ============================================================
// UART -> RAM loader.
// Receives three bytes: RAM[0] = A, RAM[1] = B, RAM[2] = mode.
// Asserts system_run after the third byte; cpu_done rearms the loader.
// Bytes arriving while the CPU is running are ignored.
// ============================================================
module UART_TO_RAM_CTRL (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_ready,
    input  wire [7:0] rx_data,
    input  wire       cpu_done,
    output reg        ram_we,
    output reg  [7:0] ram_addr,
    output reg  [7:0] ram_data_out,
    output reg        system_run
);
    reg [7:0] addr_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_cnt     <= 8'h00;
            system_run   <= 1'b0;
            ram_we       <= 1'b0;
            ram_addr     <= 8'h00;
            ram_data_out <= 8'h00;
        end else if (cpu_done) begin
            addr_cnt   <= 8'h00;
            system_run <= 1'b0;
            ram_we     <= 1'b0;
        end else if (rx_ready && !system_run) begin
            ram_we       <= 1'b1;
            ram_addr     <= addr_cnt;
            ram_data_out <= rx_data;
            addr_cnt     <= addr_cnt + 8'd1;
            if (addr_cnt == 8'h02)
                system_run <= 1'b1;
        end else begin
            ram_we <= 1'b0;
        end
    end
endmodule
