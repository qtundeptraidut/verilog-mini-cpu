`timescale 1ns/1ps
// ============================================================
// 8-bit ALU.
// sel[3:0]:
//   0000 ADD   0001 SUB   0010 AND   0011 OR
//   0100 XOR   0101 ~A    0110 ~B    0111 CMP
//   1000 A     1001 B
// CMP output: LED1 = A<B, LED2 = A==B, LED3 = A>B
// ============================================================
module adder_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       carry,
    output wire       zero
);
    wire [8:0] temp_sum;
    assign temp_sum = {1'b0, A} + {1'b0, B} + {8'b0, cin};
    assign sum   = temp_sum[7:0];
    assign carry = temp_sum[8];
    assign zero  = (sum == 8'b00000000);
endmodule

module sub_8bit (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] diff,
    output wire       carry,   // borrow
    output wire       zero
);
    wire [8:0] temp_diff;
    assign temp_diff = {1'b0, A} - {1'b0, B};
    assign diff  = temp_diff[7:0];
    assign carry = temp_diff[8];
    assign zero  = (diff == 8'b00000000);
endmodule

module ALU_8BITD (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [3:0] sel,
    output reg  [7:0] outv,
    output reg        carry,
    output reg        zero
);
    localparam LED1 = 8'b00000001;   // A < B
    localparam LED2 = 8'b00000010;   // A == B
    localparam LED3 = 8'b00000100;   // A > B

    wire [7:0] sum_wire;  wire carry_add; wire zero_add;
    wire [7:0] diff_wire; wire carry_sub; wire zero_sub;

    adder_8bit ADDER (.A(A), .B(B), .cin(1'b0),
                      .sum(sum_wire), .carry(carry_add), .zero(zero_add));
    sub_8bit   SUB   (.A(A), .B(B),
                      .diff(diff_wire), .carry(carry_sub), .zero(zero_sub));

    always @(*) begin
        outv  = 8'b0;
        carry = 1'b0;
        zero  = 1'b0;
        case (sel)
            4'b0000: begin outv = sum_wire;  carry = carry_add; zero = zero_add; end
            4'b0001: begin outv = diff_wire; carry = carry_sub; zero = zero_sub; end
            4'b0010: begin outv = A & B;  zero = (outv == 8'b0); end
            4'b0011: begin outv = A | B;  zero = (outv == 8'b0); end
            4'b0100: begin outv = A ^ B;  zero = (outv == 8'b0); end
            4'b0101: begin outv = ~A;     zero = (outv == 8'b0); end
            4'b0110: begin outv = ~B;     zero = (outv == 8'b0); end
            4'b0111: begin
                carry = carry_sub;            // 1 when A < B (borrow)
                zero  = (diff_wire == 8'b0);  // 1 when A == B
                if (diff_wire == 8'b0)    outv = LED2;
                else if (carry_sub == 1'b1) outv = LED1;
                else                        outv = LED3;
            end
            4'b1000: outv = A;
            4'b1001: outv = B;
            default: begin outv = 8'b0; carry = 1'b0; zero = 1'b0; end
        endcase
    end
endmodule
