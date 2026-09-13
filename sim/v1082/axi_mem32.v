//==========================================================================
//  axi_mem32.v
//
//  Simple, functional 32-bit AXI4 slave memory for the v10.8.2 simulation.
//  Backs the v586 single 32-bit instruction/data master port (m00) which
//  the on-chip crossbar routes to RAM + boot ROM. Purely behavioural:
//  flat byte-addressed array, one-cycle accept, one-cycle read-data return,
//  honours WSTRB byte enables on writes, INCR bursts.
//
//  Two address windows are supported so one slave backs both:
//    region 0 : [BASE0 .. BASE0 + (1<<AW0))  - main RAM (kernel + initrd +
//               boot_params). For v10.8.2 the kernel is preloaded at 0x100000.
//    region 1 : [BASE1 .. BASE1 + (1<<AW1))  - boot ROM at the reset vector
//               0xFFC00 (boot.mem), which is read-only.
//
//  Each region has its own $readmemh preload file (LOW_FILE / HIGH_FILE).
//  The boot-ROM region ignores writes (read-only). Addresses in neither
//  window return zero / drop writes.
//
//  SIMULATION ONLY. Do not synthesise.
//==========================================================================
`timescale 1ns / 1ps
module axi_mem32 #(
    parameter [31:0] BASE0     = 32'h0000_0000,
    parameter        AW0       = 23,        // 8 MiB main RAM
    parameter        LOW_FILE  = "",
    parameter [31:0] BASE1     = 32'h000f_fc00,
    parameter        AW1       = 10,        // 1 KiB boot ROM at 0xFFC00
    parameter        HIGH_FILE = ""
) (
    input  wire              clk,
    input  wire              rstn,
    input  wire [31:0]       s_axi_awaddr,
    input  wire [7:0]        s_axi_awlen,
    input  wire [2:0]        s_axi_awsize,
    input  wire [1:0]        s_axi_awburst,
    input  wire             s_axi_awvalid,
    output reg              s_axi_awready,
    input  wire [31:0]       s_axi_wdata,
    input  wire [3:0]        s_axi_wstrb,
    input  wire             s_axi_wlast,
    input  wire             s_axi_wvalid,
    output reg              s_axi_wready,
    output reg  [1:0]       s_axi_bresp,
    output reg              s_axi_bvalid,
    input  wire             s_axi_bready,
    input  wire [31:0]      s_axi_araddr,
    input  wire [7:0]       s_axi_arlen,
    input  wire [2:0]       s_axi_arsize,
    input  wire [1:0]       s_axi_arburst,
    input  wire             s_axi_arvalid,
    output reg              s_axi_arready,
    output reg  [31:0]      s_axi_rdata,
    output reg  [1:0]       s_axi_rresp,
    output reg              s_axi_rlast,
    output reg              s_axi_rvalid,
    input  wire             s_axi_rready
);
    localparam MEM0 = (1 << AW0);
    localparam MEM1 = (1 << AW1);
    localparam BEAT = 4;   // 32-bit -> 4 bytes per beat

    reg [7:0] mem0 [0:MEM0-1];
    reg [7:0] mem1 [0:MEM1-1];

    function in0; input [31:0] a; in0 = (a >= BASE0) && (a < BASE0 + MEM0); endfunction
    function in1; input [31:0] a; in1 = (a >= BASE1) && (a < BASE1 + MEM1); endfunction

    function [7:0] rd_byte; input [31:0] a; begin
        if (in1(a))      rd_byte = mem1[(a - BASE1) & (MEM1-1)];
        else if (in0(a)) rd_byte = mem0[(a - BASE0) & (MEM0-1)];
        else             rd_byte = 8'h00;
    end endfunction

    function [31:0] rd_word; input [31:0] a; integer k; begin
        for (k = 0; k < 4; k = k + 1) rd_word[k*8 +: 8] = rd_byte(a + k);
    end endfunction

    task wr_word; input [31:0] a; input [31:0] d; input [3:0] s; integer k; begin
        for (k = 0; k < 4; k = k + 1) begin
            if (!s[k]);
            else if (in0(a + k)) mem0[(a + k - BASE0) & (MEM0-1)] <= d[k*8 +: 8];
            // region 1 (boot ROM) is read-only: ignore writes
        end
    end endtask

    integer i;
    initial begin
        for (i = 0; i < MEM0; i = i + 1) mem0[i] = 8'h00;
        for (i = 0; i < MEM1; i = i + 1) mem1[i] = 8'h00;
        if (LOW_FILE  != "") $readmemh(LOW_FILE,  mem0, 0);
        if (HIGH_FILE != "") $readmemh(HIGH_FILE, mem1, 0);
    end

    // ---- write path ----
    reg [31:0] w_addr; reg [7:0] w_len, w_beat; reg w_busy, b_pending;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_axi_awready <= 0; s_axi_wready <= 0; s_axi_bvalid <= 0;
            s_axi_bresp <= 0; w_busy <= 0; b_pending <= 0;
            w_addr <= 0; w_len <= 0; w_beat <= 0;
        end else begin
            if (s_axi_awvalid & ~w_busy) begin
                s_axi_awready <= 1;
                w_addr <= {s_axi_awaddr[31:2], 2'b00};
                w_len  <= s_axi_awlen;
                w_busy <= 1; w_beat <= 0;
            end else s_axi_awready <= 0;

            s_axi_wready <= w_busy;
            if (w_busy & s_axi_wvalid & s_axi_wready) begin
                wr_word(w_addr, s_axi_wdata, s_axi_wstrb);
                if (w_beat == w_len) begin
                    w_busy <= 0; b_pending <= 1; s_axi_wready <= 0;
                end else begin
                    w_beat <= w_beat + 8'd1; w_addr <= w_addr + BEAT;
                end
            end
            if (b_pending & ~s_axi_bvalid) begin
                s_axi_bvalid <= 1; s_axi_bresp <= 2'b00;
            end else if (s_axi_bvalid & s_axi_bready) begin
                s_axi_bvalid <= 0; b_pending <= 0;
            end
        end
    end

    // ---- read path ----
    reg [31:0] r_addr; reg [7:0] r_len, r_beat; reg r_busy, r_pending;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_axi_arready <= 0; s_axi_rvalid <= 0; s_axi_rlast <= 0;
            s_axi_rresp <= 0; s_axi_rdata <= 0;
            r_addr <= 0; r_len <= 0; r_beat <= 0; r_busy <= 0; r_pending <= 0;
        end else begin
            if (s_axi_arvalid & ~r_busy) begin
                s_axi_arready <= 1;
                r_addr <= {s_axi_araddr[31:2], 2'b00};
                r_len  <= s_axi_arlen;
                r_busy <= 1; r_beat <= 0;
            end else s_axi_arready <= 0;

            if (r_busy & ~r_pending) begin
                r_pending <= 1; s_axi_rvalid <= 1;
                s_axi_rdata <= rd_word(r_addr);
                s_axi_rresp <= 2'b00; s_axi_rlast <= (r_beat == r_len);
            end else if (r_pending & s_axi_rready) begin
                s_axi_rvalid <= 0;
                if (r_beat == r_len) begin
                    r_busy <= 0; r_pending <= 0; s_axi_rlast <= 0;
                end else begin
                    r_beat <= r_beat + 8'd1; r_addr <= r_addr + BEAT; r_pending <= 0;
                end
            end
        end
    end

    wire _unused = &{1'b0, s_axi_awsize, s_axi_awburst, s_axi_arsize,
                     s_axi_arburst, s_axi_wlast};
endmodule
