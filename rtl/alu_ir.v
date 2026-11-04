`timescale 1ns/1ps
// ============================================================
// Instruction register: splits an 8-bit instruction into opcode/operand.
// ============================================================
module ALU_IR (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,
    input  wire [7:0] instr_in,
    output reg  [3:0] opcode,
    output reg  [3:0] operand
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode  <= 4'b0000;
            operand <= 4'b0000;
        end else if (load) begin
            opcode  <= instr_in[7:4];
            operand <= instr_in[3:0];
        end
    end
endmodule
