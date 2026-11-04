`timescale 1ns/1ps
// ============================================================
// 256x8 single-port RAM, synchronous write, asynchronous read.
// Initialised to zero for simulation.
// ============================================================
module RAM (
    input  wire       clk,
    input  wire       write_en,
    input  wire [7:0] data_in,
    input  wire [7:0] Addr,
    output wire [7:0] data_out
);
    reg [7:0] data_storage [255:0];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            data_storage[i] = 8'h00;
    end

    always @(posedge clk) begin
        if (write_en)
            data_storage[Addr] <= data_in;
    end

    assign data_out = data_storage[Addr];
endmodule
