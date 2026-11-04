`timescale 1ns/1ps
// ============================================================
// Program counter.
// Increments only while system_run is high; cpu_done resets it to zero.
// ============================================================
module PC (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       run_en,
    input  wire       pc_inc,
    input  wire       pc_reset,
    output reg  [7:0] pc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)             pc_out <= 8'h00;
        else if (pc_reset)      pc_out <= 8'h00;
        else if (run_en && pc_inc) pc_out <= pc_out + 8'h01;
    end
endmodule
