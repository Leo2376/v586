//==========================================================================
//  axi_mem128.v
//
//  Simple, functional 128-bit AXI4 slave memory for simulation.
//  Backs the v586 instruction/data master port (m00) which is 128-bit data
//  with a 16-bit byte-strobe and INCR bursts. Purely behavioural: flat
//  byte-addressed arrays, one-cycle accept, one-cycle read-data return,
//  honours WSTRB byte enables on writes.
//
//  Two address windows are supported so a single slave can back both the
//  kernel (low memory, ~0x00000000) and the boot code (high memory,
//  0x40d00000, the v586 reset vector) without a 1+ GiB flat array:
//
//    region 0 : [BASE0 .. BASE0 + (1<<AW0))   - kernel + boot_params
//    region 1 : [BASE1 .. BASE1 + (1<<AW1))   - boot code at reset vector
//
//  Each region has its own $readmemh preload file (LOW_FILE / HIGH_FILE).
//  Addresses that fall in neither window return zero / silently drop
//  writes (acceptable for a sim platform).
//
//  SIMULATION ONLY. Do not synthesise.
//==========================================================================
`timescale 1ns / 1ps

module axi_mem128 #(
    parameter DW      = 128,
    parameter SW      = DW/8,            // strobe bits (16)
    // region 0 - low memory (kernel, boot_params, e820, cmdline)
    parameter [31:0] BASE0    = 32'h0000_0000,
    parameter AW0             = 24,      // 16 MiB
    parameter         LOW_FILE = "",
    // region 1 - high memory (boot code at the reset vector)
    parameter [31:0] BASE1    = 32'h40d0_0000,
    parameter AW1             = 20,      // 1 MiB
    parameter         HIGH_FILE = ""
) (
    input  wire              clk,
    input  wire              rstn,

    // AXI4 write address channel
    input  wire [31:0]       s_axi_awaddr,
    input  wire [7:0]        s_axi_awlen,
    input  wire [2:0]       s_axi_awsize,
    input  wire [1:0]       s_axi_awburst,
    input  wire             s_axi_awvalid,
    output reg              s_axi_awready,
    // AXI4 write data channel
    input  wire [DW-1:0]    s_axi_wdata,
    input  wire [SW-1:0]    s_axi_wstrb,
    input  wire             s_axi_wlast,
    input  wire             s_axi_wvalid,
    output reg              s_axi_wready,
    // AXI4 write response channel
    output reg  [1:0]       s_axi_bresp,
    output reg              s_axi_bvalid,
    input  wire             s_axi_bready,
    // AXI4 read address channel
    input  wire [31:0]      s_axi_araddr,
    input  wire [7:0]       s_axi_arlen,
    input  wire [2:0]       s_axi_arsize,
    input  wire [1:0]       s_axi_arburst,
    input  wire             s_axi_arvalid,
    output reg              s_axi_arready,
    // AXI4 read data channel
    output reg  [DW-1:0]    s_axi_rdata,
    output reg  [1:0]       s_axi_rresp,
    output reg              s_axi_rlast,
    output reg              s_axi_rvalid,
    input  wire             s_axi_rready
);

    localparam MEM0 = (1 << AW0);  // bytes in region 0
    localparam MEM1 = (1 << AW1);  // bytes in region 1
    localparam BEAT_BYTES = DW/8;  // 16 bytes per 128-bit beat

    reg [7:0] mem0 [0:MEM0-1];
    reg [7:0] mem1 [0:MEM1-1];

    // resolve a 32-bit address into a region id + offset
    // returns region (0/1/2=none) in high bits of a packed return is awkward,
    // so we compute two candidate offsets and select.
    function [31:0] off0;
        input [31:0] a; begin off0 = (a - BASE0) & (MEM0-1); end
    endfunction
    function [31:0] off1;
        input [31:0] a; begin off1 = (a - BASE1) & (MEM1-1); end
    endfunction
    // is the address in region 0/1?
    function in0;
        input [31:0] a; begin in0 = (a >= BASE0) && (a < BASE0 + MEM0); end
    endfunction
    function in1;
        input [31:0] a; begin in1 = (a >= BASE1) && (a < BASE1 + MEM1); end
    endfunction

    function [DW-1:0] rd_beat;
        input [31:0] a;
        integer k;
        reg [7:0] b;
        begin
            for (k = 0; k < BEAT_BYTES; k = k + 1) begin
                if (in0(a + k))      b = mem0[(a + k - BASE0) & (MEM0-1)];
                else if (in1(a + k)) b = mem1[(a + k - BASE1) & (MEM1-1)];
                else                b = 8'h00;
                rd_beat[k*8 +: 8] = b;
            end
        end
    endfunction

    task wr_beat;
        input [31:0] a;
        input [DW-1:0] d;
        input [SW-1:0] strb;
        integer k;
        begin
            for (k = 0; k < BEAT_BYTES; k = k + 1) begin
                if (!strb[k]);
                else if (in0(a + k)) mem0[(a + k - BASE0) & (MEM0-1)] <= d[k*8 +: 8];
                else if (in1(a + k)) mem1[(a + k - BASE1) & (MEM1-1)] <= d[k*8 +: 8];
            end
        end
    endtask

    integer i;
    initial begin
        for (i = 0; i < MEM0; i = i + 1) mem0[i] = 8'h00;
        for (i = 0; i < MEM1; i = i + 1) mem1[i] = 8'h00;
        if (LOW_FILE  != "") $readmemh(LOW_FILE,  mem0, 0);
        if (HIGH_FILE != "") $readmemh(HIGH_FILE, mem1, 0);
    end

    //------------------------------------------------------------------
    // Write path
    //------------------------------------------------------------------
    reg [31:0] w_addr;
    reg [7:0]  w_len, w_beat;
    reg        w_busy, b_pending;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            w_busy        <= 1'b0;
            b_pending     <= 1'b0;
            w_addr        <= 32'b0;
            w_len         <= 8'b0;
            w_beat        <= 8'b0;
        end else begin
            if (s_axi_awvalid & ~w_busy) begin
                s_axi_awready <= 1'b1;
                w_addr        <= {s_axi_awaddr[31:4], 4'b0000};
                w_len         <= s_axi_awlen;
                w_busy        <= 1'b1;
                w_beat        <= 8'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end

            s_axi_wready <= w_busy;
            if (w_busy & s_axi_wvalid & s_axi_wready) begin
                wr_beat(w_addr, s_axi_wdata, s_axi_wstrb);
                if (w_beat == w_len) begin
                    w_busy        <= 1'b0;
                    b_pending     <= 1'b1;
                    s_axi_wready  <= 1'b0;
                end else begin
                    w_beat  <= w_beat + 8'd1;
                    w_addr  <= w_addr + BEAT_BYTES;
                end
            end

            if (b_pending & ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid & s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                b_pending    <= 1'b0;
            end
        end
    end

    //------------------------------------------------------------------
    // Read path
    //------------------------------------------------------------------
    reg [31:0] r_addr;
    reg [7:0]  r_len, r_beat;
    reg        r_busy, r_pending;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= {DW{1'b0}};
            r_addr        <= 32'b0;
            r_len         <= 8'b0;
            r_beat        <= 8'b0;
            r_busy        <= 1'b0;
            r_pending     <= 1'b0;
        end else begin
            if (s_axi_arvalid & ~r_busy) begin
                s_axi_arready <= 1'b1;
                r_addr        <= {s_axi_araddr[31:4], 4'b0000};
                r_len         <= s_axi_arlen;
                r_busy        <= 1'b1;
                r_beat        <= 8'b0;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (r_busy & ~r_pending) begin
                r_pending     <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rdata   <= rd_beat(r_addr);
                s_axi_rresp   <= 2'b00;
                s_axi_rlast   <= (r_beat == r_len);
            end else if (r_pending & s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                if (r_beat == r_len) begin
                    r_busy     <= 1'b0;
                    r_pending  <= 1'b0;
                    s_axi_rlast<= 1'b0;
                end else begin
                    r_beat  <= r_beat + 8'd1;
                    r_addr  <= r_addr + BEAT_BYTES;
                    r_pending <= 1'b0;
                end
            end
        end
    end

    wire _unused = &{1'b0, s_axi_awsize, s_axi_awburst,
                     s_axi_arsize, s_axi_arburst, s_axi_wlast};

endmodule
