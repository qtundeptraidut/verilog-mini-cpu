`timescale 1ns/1ps
// ============================================================
// UART receiver, 8N1, LSB first.
// - 2-flop synchronizer + falling-edge start detection
// - samples each bit at its midpoint
// - returns to IDLE immediately after the last data bit
//   so back-to-back bytes are accepted
// - rx_ready is a one-clock pulse
// ============================================================
module UART_RX #(
    parameter CLKS_PER_BIT = 434
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_ready
);
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;

    reg rx_sync_0, rx_sync_1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;
        end
    end
    wire rx_clean = rx_sync_1;

    reg rx_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_prev <= 1'b1;
        else        rx_prev <= rx_clean;
    end
    wire start_edge = (rx_prev == 1'b1) && (rx_clean == 1'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            rx_ready  <= 1'b0;
            rx_data   <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    rx_ready  <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (start_edge) state <= START;
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx_clean == 1'b0) begin
                            clk_count <= 16'd0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE;   // glitch / false start
                        end
                    end else begin
                        clk_count <= clk_count + 16'd1;
                    end
                end

                DATA: begin
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 16'd1;
                    end else begin
                        clk_count <= 16'd0;
                        rx_data[bit_index] <= rx_clean;

                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 3'd1;
                        end else begin
                            // Last data bit received: assert rx_ready and
                            // return to IDLE so the next frame can start.
                            bit_index <= 3'd0;
                            rx_ready  <= 1'b1;
                            state     <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
