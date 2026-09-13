//==========================================================================
//  tb_iverilog.v  --  minimal Verilog testbench for Icarus Verilog fallback
//
//  Instantiates TOP_SYS_sim, generates a 100 MHz clock, holds reset, then
//  runs for a bounded number of cycles and dumps a VCD. No external preload
//  of the 128-bit RAM here (the CPU will fetch zeros) -- use the Verilator
//  C++ TB for a richer bring-up; this is just a smoke compile/run.
//==========================================================================
`timescale 1ns / 1ps

module tb_iverilog;
    reg clk;
    reg rstn;
    reg rxd;
    wire txd;
    wire [3:0] r4, g4, b4;
    wire hz, vt;

    TOP_SYS_sim dut (
        .clk(clk), .rstn(rstn), .RXD(rxd), .TXD(txd),
        .r4(r4), .g4(g4), .b4(b4), .hz(hz), .vt(vt)
    );

    // 100 MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rxd  = 1'b1;     // UART idle
        rstn = 1'b0;
        #200;
        rstn = 1'b1;
    end

    initial begin
        $dumpfile("waves/top_sim.vcd");
        $dumpvars(0, tb_iverilog);
        #2000000;        // ~2 ms of sim time
        $display("tb_iverilog: finished");
        $finish;
    end

    // watchdog
    initial begin
        #20000000;
        $display("tb_iverilog: watchdog timeout");
        $finish;
    end
endmodule
