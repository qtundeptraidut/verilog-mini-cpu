`timescale 1ns/1ps
// ============================================================
// CPU control FSM.
// States: FETCH -> DECODE -> {MEM, EXEC, TX -> WAIT_TX, HALT} -> FETCH
// system_run gates the FETCH/DECODE logic so the CPU does not execute
// while the UART->RAM loader is still filling RAM.
// HALT returns to FETCH once system_run is cleared by cpu_done.
// ============================================================
module CPU_FSM (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       system_run,
    input  wire       tx_busy,
    input  wire [3:0] opcode,
    input  wire [3:0] operand,
    output reg        pc_en,
    output reg        ir_load,
    output reg        en_A,
    output reg        en_B,
    output reg        en_Mode,
    output reg        alu_en,
    output reg        tx_start
);
    localparam LOAD = 4'b0010;
    localparam EXEC = 4'b0011;
    localparam TX   = 4'b0100;
    localparam HALT = 4'b0111;

    localparam S_FETCH   = 3'd0;
    localparam S_DECODE  = 3'd1;
    localparam S_EXEC    = 3'd2;
    localparam S_MEM     = 3'd3;
    localparam S_TX      = 3'd4;
    localparam S_WAIT_TX = 3'd5;
    localparam S_HALT    = 3'd6;

    reg [2:0] state, next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_FETCH;
        else        state <= next;
    end

    always @(*) begin
        next = state;
        case (state)
            S_FETCH: begin
                if (system_run) next = S_DECODE;
                else            next = S_FETCH;
            end

            S_DECODE: begin
                case (opcode)
                    LOAD:    next = S_MEM;
                    EXEC:    next = S_EXEC;
                    TX:      next = S_TX;
                    HALT:    next = S_HALT;
                    default: next = S_FETCH;
                endcase
            end

            S_MEM:     next = S_FETCH;
            S_EXEC:    next = S_FETCH;
            S_TX:      next = S_WAIT_TX;
            S_WAIT_TX: if (!tx_busy) next = S_FETCH;
            S_HALT:    if (!system_run) next = S_FETCH;
                       else             next = S_HALT;
            default:   next = S_FETCH;
        endcase
    end

    always @(*) begin
        pc_en    = 1'b0;
        ir_load  = 1'b0;
        en_A     = 1'b0;
        en_B     = 1'b0;
        en_Mode  = 1'b0;
        alu_en   = 1'b0;
        tx_start = 1'b0;
        case (state)
            S_FETCH: begin
                ir_load = system_run;
                pc_en   = system_run;
            end
            S_MEM: begin
                case (operand)
                    4'b0000: en_A    = 1'b1;
                    4'b0001: en_B    = 1'b1;
                    4'b0010: en_Mode = 1'b1;
                    default: ;
                endcase
            end
            S_EXEC: alu_en   = 1'b1;
            S_TX:   tx_start = 1'b1;
            default: ;
        endcase
    end
endmodule
