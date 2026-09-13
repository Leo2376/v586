//==========================================================================
//  axi_mem128.v
//
//  Simple, functional 128-bit AXI4 slave memory for simulation.
//  Backs the v586 instruction/data master port (m00) which is 128-bit data
//  with a 16-bit byte-strobe and INCR bursts. Purely behavioural: a flat
//  byte-addressed array, one-cycle accept, one-cycle read-data return,
//  honours WSTRB byte enables on writes. Intended to replace the
//  Xilinx crossbar + MIG + boot-ROM chain in simulation.
//
//  Address windowing: the v586 core fetches its reset vector at
//  0x40d00000 (see old/v14.0/useq.v, vliw.v). To keep the backing array
//  small, every AXI address is mapped into the array by subtracting BASE
//  and masking to AW bits:  offset = (addr - BASE) & (MEM_BYTES-1).
//  With BASE=0x40d00000 and AW=24 (16 MiB) the reset vector lands at
//  offset 0 and the whole 16 MiB window wraps cleanly.
//
//  Preload: pass MEM_FILE (a $readmemh hex file, one byte per line) and the
//  array is loaded at offset 0 at time 0. Leave empty for a zero-filled
//  RAM. A sample boot image is provided in sim/boot.hex (a tight self-loop
//  so you can confirm the fetch path works).
//
//  SIMULATION ONLY. Do not synthesise.
//==========================================================================
`timescale 1ns / 1ps

module axi_mem128 #(
    parameter AW      = 24,        // address bits used (byte address window)
    parameter DW      = 128,      // data width
    parameter SW      = DW/8,      // strobe bits
    parameter [31:0] BASE     = 32'h40d0_0000, // window base (reset vector)
    parameter         MEM_FILE = ""           // optional $readmemh preload
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

    localparam MEM_BYTES = (1 << AW);
    localparam BEAT_BYTES = DW/8; // 16 bytes per 128-bit beat

    reg [7:0] mem [0:MEM_BYTES-1];

    // window-map a 32-bit AXI address into the array offset
    function [31:0] xlate;
        input [31:0] a;
        begin
            xlate = (a - BASE) & (MEM_BYTES-1);
        end
    endfunction

    function [DW-1:0] rd_beat;
        input [31:0] a;
        integer k;
        begin
            for (k = 0; k < BEAT_BYTES; k = k + 1)
                rd_beat[k*8 +: 8] = mem[(a + k) & (MEM_BYTES-1)];
        end
    endfunction

    task wr_beat;
        input [31:0] a;
        input [DW-1:0] d;
        input [SW-1:0] strb;
        integer k;
        begin
            for (k = 0; k < BEAT_BYTES; k = k + 1)
                if (strb[k]) mem[(a + k) & (MEM_BYTES-1)] <= d[k*8 +: 8];
        end
    endtask

    integer i;
    initial begin
        // zero-fill then optional preload at offset 0 (the reset vector)
        for (i = 0; i < MEM_BYTES; i = i + 1) mem[i] = 8'h00;
        if (MEM_FILE != "") $readmemh(MEM_FILE, mem, 0);
    end

    //------------------------------------------------------------------
    // Write path
    //------------------------------------------------------------------
    reg [31:0] w_addr;
    reg [7:0]  w_len;
    reg [7:0]  w_beat;
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
            // AW accept
            if (s_axi_awvalid & ~w_busy) begin
                s_axi_awready <= 1'b1;
                w_addr        <= xlate(s_axi_awaddr);
                w_len         <= s_axi_awlen;
                w_busy        <= 1'b1;
                w_beat        <= 8'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // W accept
            s_axi_wready <= w_busy;
            if (w_busy & s_axi_wvalid & s_axi_wready) begin
                wr_beat(w_addr, s_axi_wdata, s_axi_wstrb);
                if (w_beat == w_len) begin
                    w_busy        <= 1'b0;
                    b_pending     <= 1'b1;
                    s_axi_wready  <= 1'b0;
                end else begin
                    w_beat  <= w_beat + 8'd1;
                    w_addr  <= (w_addr + BEAT_BYTES) & (MEM_BYTES-1);
                end
            end

            // B response
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
    reg [7:0]  r_len;
    reg [7:0]  r_beat;
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
                r_addr        <= xlate(s_axi_araddr);
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
                    r_addr  <= (r_addr + BEAT_BYTES) & (MEM_BYTES-1);
                    r_pending <= 1'b0;
                end
            end
        end
    end

    // quiet unused AXI inputs
    wire _unused = &{1'b0, s_axi_awsize, s_axi_awburst,
                     s_axi_arsize, s_axi_arburst, s_axi_wlast};

endmodule
