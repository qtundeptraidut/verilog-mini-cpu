`timescale 1ns/1ps
// ============================================================
// 8-bit register with synchronous enable and async active-low reset.
// ============================================================
module REG8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)  q <= 8'b0;
        else if (en) q <= d;
    end
endmodule
