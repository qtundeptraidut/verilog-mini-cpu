`timescale 1ns/1ps
// ============================================================
// Program ROM.
//   0x00 LOAD  A    (RAM[0])
//   0x01 LOAD  B    (RAM[1])
//   0x02 LOAD  MODE (RAM[2])
//   0x03 EXEC  ALU
//   0x04 TX
//   0x05 HALT
// ============================================================
module ROM (
    input  wire [7:0] addr,
    output reg  [7:0] data_out
);
    always @(*) begin
        case (addr)
            8'h00:   data_out = 8'b0010_0000;
            8'h01:   data_out = 8'b0010_0001;
            8'h02:   data_out = 8'b0010_0010;
            8'h03:   data_out = 8'b0011_0000;
            8'h04:   data_out = 8'b0100_0000;
            8'h05:   data_out = 8'b0111_0000;
            default: data_out = 8'b0111_0000;
        endcase
    end
endmodule
