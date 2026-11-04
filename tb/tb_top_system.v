`timescale 1ns/1ps
// ============================================================
// Self-checking testbench for TOP_SYSTEM.
// CLKS_PER_BIT is reduced to 16 for a fast simulation.
// ============================================================
module tb_top_system;
    localparam integer CLKS_PER_BIT = 16;
    localparam integer CLK_PERIOD   = 10;

    reg clk;
    reg rst_n;
    reg rx_drv;
    reg [1:0] sw;
    wire tx;
    wire [7:0] led_out;

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    TOP_SYSTEM #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .rx      (rx_drv),
        .tx      (tx),
        .sw      (sw),
        .led_out (led_out)
    );

    // Monitor UART to capture the result byte transmitted by the CPU.
    wire [7:0] mon_data;
    wire       mon_ready;
    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) mon_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (tx),
        .rx_data  (mon_data),
        .rx_ready (mon_ready)
    );

    integer errors;
    integer i;

    task check;
        input        cond;
        input [8*80-1:0] msg;
        begin
            if (cond)
                $display("PASS  %0s", msg);
            else begin
                $display("FAIL  %0s  (t=%0t)", msg, $time);
                errors = errors + 1;
            end
        end
    endtask

    task send_byte;
        input [7:0] data;
        integer idx;
        begin
            rx_drv = 1'b0;                       // start bit
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (idx = 0; idx < 8; idx = idx + 1) begin
                rx_drv = data[idx];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            rx_drv = 1'b1;                       // stop bit
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_bytes;
        input [7:0] a, b, mode;
        begin
            send_byte(a);
            send_byte(b);
            send_byte(mode);
        end
    endtask

    task recv_byte;
        output [7:0] data;
        begin
            wait (mon_ready === 1'b1);
            data = mon_data;
            @(posedge clk);
            // Wait until the CPU finishes HALT and re-arms the loader.
            while (dut.system_run !== 1'b0) @(posedge clk);
        end
    endtask

    task run_case;
        input [7:0] a, b, mode, expected;
        input [8*80-1:0] name;
        reg [7:0] got;
        begin
            send_bytes(a, b, mode);
            recv_byte(got);
            $display("CASE %0s : got=0x%02h expected=0x%02h", name, got, expected);
            check(got === expected, name);
            check(led_out === expected, name);
        end
    endtask



    initial begin
        $dumpfile("build/tb_top_system.vcd");
        $dumpvars(0, tb_top_system);

        errors = 0;
        rst_n  = 1'b0;
        rx_drv = 1'b1;
        sw     = 2'b00;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        check(tx === 1'b1, "reset: UART TX idles high");
        check(led_out === 8'h00, "reset: LED output is zero");

        run_case(8'h05, 8'h03, 8'h00, 8'h08, "ADD  5+3");
        run_case(8'h05, 8'h03, 8'h01, 8'h02, "SUB  5-3");
        run_case(8'hF0, 8'h0F, 8'h02, 8'h00, "AND  F0&0F");
        run_case(8'hF0, 8'h0F, 8'h03, 8'hFF, "OR   F0|0F");
        run_case(8'hFF, 8'h0F, 8'h04, 8'hF0, "XOR  FF^0F");
        run_case(8'h0F, 8'h00, 8'h05, 8'hF0, "NOT  ~0F");
        run_case(8'h05, 8'h03, 8'h07, 8'h04, "CMP  5>3");
        run_case(8'h03, 8'h05, 8'h07, 8'h01, "CMP  3<5");
        run_case(8'h04, 8'h04, 8'h07, 8'h02, "CMP  4==4");

        // status_reg after the last compare (zero=1, carry=0)
        sw = 2'b11;
        #1;
        check(led_out === 8'h02, "status_reg: zero flag set for 4==4");
        sw = 2'b00;

        $display("========================================");
        if (errors == 0) begin
            $display("SUMMARY: ALL TESTS PASSED");
            $finish;
        end else begin
            $display("SUMMARY: %0d TEST(S) FAILED", errors);
            $fatal(1, "simulation failed");
        end
    end

    // Watchdog to catch hangs.
    initial begin
        #2_000_000;
        $display("TIMEOUT: simulation did not finish");
        $fatal(1, "timeout");
    end
endmodule
