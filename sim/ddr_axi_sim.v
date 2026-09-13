//==========================================================================
//  ddr_axi_sim.v
//
//  Functional, simulation-only replacement for the Xilinx MIG "ddr_axi"
//  wrapper that TOP_SYS.v instantiates. It keeps the exact same port list
//  the SoC expects from the MIG, but instead of driving real DDR2/DDR3 pads
//  it backs the AXI slave with a flat byte-addressed behavioural memory.
//
//  This is deliberately simple and purely functional:
//    * no pad-level DDR2/DDR3 signalling,
//    * no refresh, no calibration latency modelling,
//    * one-cycle address/data accept, one-cycle read data return,
//    * honours ARLEN/AWLEN bursts (INCR), ignores AWSIZE/ARSIZE for the
//      address increment (always 4 bytes per beat, matching a 32-bit AXI),
//    * honours WSTRB byte enables on writes,
//    * init_calib_complete asserts after reset so the SoC boot path runs.
//
//  The backing store is shared by all ports of the SoC that map onto the
//  "ram" crossbar slave (instruction fetch, data load/store, plus anything
//  the boot ROM is shadowed over). A separate load file may be preloaded
//  via $readmemh on "ddr_mem" (see ddr_axi_sim_pkg) for bring-up.
//
//  NOTE: this module is for SIMULATION ONLY. Do not synthesise it.
//==========================================================================
`timescale 1ns / 1ps

module ddr_axi (
    // DDR2 pads (kept as ports for port-list compatibility, driven inert)
    inout  wire [15:0] ddr2_dq,
    inout  wire [ 1:0] ddr2_dqs_n,
    inout  wire [ 1:0] ddr2_dqs_p,
    output wire [12:0] ddr2_addr,
    output wire [ 2:0] ddr2_ba,
    output wire        ddr2_ras_n,
    output wire        ddr2_cas_n,
    output wire        ddr2_we_n,
    output wire        ddr2_ck_p,
    output wire        ddr2_ck_n,
    output wire        ddr2_cke,
    output wire        ddr2_cs_n,
    output wire [ 1:0] ddr2_dm,
    output wire        ddr2_odt,
    // MIG clock / status
    input              sys_clk_i,
    input              clk_ref_i,
    output wire        ui_clk,
    output wire        ui_clk_sync_rst,
    output wire        mmcm_locked,
    input              aresetn,
    input              app_sr_req,
    input              app_ref_req,
    input              app_zq_req,
    output wire        app_sr_active,
    output wire        app_ref_ack,
    output wire        app_zq_ack,
    // AXI4 slave (32-bit data), matching the MIG interface TOP_SYS uses
    input  [3:0]       s_axi_awid,
    input  [31:0]      s_axi_awaddr,
    input  [7:0]       s_axi_awlen,
    input  [2:0]       s_axi_awsize,
    input  [1:0]       s_axi_awburst,
    input  [0:0]       s_axi_awlock,
    input  [3:0]       s_axi_awcache,
    input  [2:0]       s_axi_awprot,
    input  [3:0]       s_axi_awqos,
    input              s_axi_awvalid,
    output reg         s_axi_awready,
    input  [31:0]      s_axi_wdata,
    input  [3:0]       s_axi_wstrb,
    input              s_axi_wlast,
    input              s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [3:0]  s_axi_bid,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input              s_axi_bready,
    input  [3:0]       s_axi_arid,
    input  [31:0]      s_axi_araddr,
    input  [7:0]       s_axi_arlen,
    input  [2:0]       s_axi_arsize,
    input  [1:0]       s_axi_arburst,
    input  [0:0]       s_axi_arlock,
    input  [3:0]       s_axi_arcache,
    input  [2:0]       s_axi_arprot,
    input  [3:0]       s_axi_arqos,
    input              s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [3:0]  s_axi_rid,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rlast,
    output reg         s_axi_rvalid,
    input              s_axi_rready,
    output reg         init_calib_complete,
    input              sys_rst
);

    //------------------------------------------------------------------
    // keep DDR2 pads quiet / defined so simulators don't see X states
    //------------------------------------------------------------------
    assign ddr2_dq     = 16'bz;
    assign ddr2_dqs_n  = 2'bzz;
    assign ddr2_dqs_p  = 2'bzz;
    assign ddr2_addr   = 13'b0;
    assign ddr2_ba     = 3'b0;
    assign ddr2_ras_n  = 1'b1;
    assign ddr2_cas_n  = 1'b1;
    assign ddr2_we_n   = 1'b1;
    assign ddr2_ck_p   = 1'b0;
    assign ddr2_ck_n   = 1'b1;
    assign ddr2_cke    = 1'b0;
    assign ddr2_cs_n   = 1'b1;
    assign ddr2_dm     = 2'b11;
    assign ddr2_odt    = 1'b0;

    //------------------------------------------------------------------
    // MIG-style clock / status. Drive ui_clk from sys_clk_i so the SoC
    // has a free-running clock independent of the (absent) MMCM.
    //------------------------------------------------------------------
    assign ui_clk            = sys_clk_i;
    assign mmcm_locked       = 1'b1;
    assign app_sr_active     = 1'b0;
    assign app_ref_ack       = 1'b0;
    assign app_zq_ack        = 1'b0;
    assign ui_clk_sync_rst   = ~init_calib_complete;

    // short calibration delay after reset so rstn_ddr releases cleanly
    reg [3:0] calib_cnt;
    always @(posedge ui_clk) begin
        if (sys_rst) begin
            calib_cnt          <= 4'd0;
            init_calib_complete<= 1'b0;
        end else begin
            if (calib_cnt != 4'd15) calib_cnt <= calib_cnt + 4'd1;
            else init_calib_complete <= 1'b1;
        end
    end

    //------------------------------------------------------------------
    // Backing store: 16 MiB byte-addressable memory (2^24 bytes).
    // Indexed by byte; AXI accesses are 32-bit (4 bytes) per beat.
    //------------------------------------------------------------------
    localparam MEM_BYTES = (1 << 24);
    localparam MEM_WORDS = MEM_BYTES / 4;

    reg [7:0] ddr_mem [0:MEM_BYTES-1];

    // optional preload hook (no-op if the file is absent at elab time)
    initial begin
        ddr_mem[0] = 8'h00; // touch to synthesise the array
    end

    function [31:0] rd_word;
        input [31:0] a;
        begin
            rd_word = {ddr_mem[a+3], ddr_mem[a+2], ddr_mem[a+1], ddr_mem[a+0]};
        end
    endfunction

    task wr_word;
        input [31:0] a;
        input [31:0] d;
        input [3:0]  strb;
        begin
            if (strb[0]) ddr_mem[a+0] <= d[ 7: 0];
            if (strb[1]) ddr_mem[a+1] <= d[15: 8];
            if (strb[2]) ddr_mem[a+2] <= d[23:16];
            if (strb[3]) ddr_mem[a+3] <= d[31:24];
        end
    endtask

    //------------------------------------------------------------------
    // Write address channel
    //------------------------------------------------------------------
    reg [31:0] aw_addr;
    reg [7:0]  aw_len;
    reg [3:0]  aw_id_q;
    reg        aw_busy;

    always @(posedge ui_clk) begin
        if (sys_rst | ~aresetn) begin
            s_axi_awready <= 1'b0;
            aw_busy       <= 1'b0;
            aw_addr       <= 32'b0;
            aw_len        <= 8'b0;
            aw_id_q       <= 4'b0;
        end else begin
            if (s_axi_awvalid & ~aw_busy) begin
                s_axi_awready <= 1'b1;
                aw_addr       <= s_axi_awaddr;
                aw_len        <= s_axi_awlen;
                aw_id_q       <= s_axi_awid;
                aw_busy       <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    //------------------------------------------------------------------
    // Write data channel + commit + B response
    //------------------------------------------------------------------
    reg [7:0] w_beat;
    reg [31:0] w_addr;
    reg [7:0]  w_len;
    reg [3:0]  w_id_q;
    reg        w_busy, b_pending;

    always @(posedge ui_clk) begin
        if (sys_rst | ~aresetn) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
            s_axi_bid    <= 4'b0;
            w_busy       <= 1'b0;
            b_pending    <= 1'b0;
            w_beat       <= 8'b0;
            w_addr       <= 32'b0;
            w_len        <= 8'b0;
            w_id_q       <= 4'b0;
        end else begin
            // latch write transaction descriptor from AW channel
            if (s_axi_awvalid & s_axi_awready & ~w_busy) begin
                w_addr  <= {s_axi_awaddr[31:2], 2'b00};
                w_len   <= s_axi_awlen;
                w_id_q  <= s_axi_awid;
                w_busy  <= 1'b1;
                w_beat  <= 8'b0;
            end

            // accept write beats
            s_axi_wready <= w_busy;
            if (w_busy & s_axi_wvalid & s_axi_wready) begin
                wr_word(w_addr, s_axi_wdata, s_axi_wstrb);
                if (w_beat == w_len) begin
                    w_busy    <= 1'b0;
                    b_pending <= 1'b1;
                    s_axi_wready <= 1'b0;
                end else begin
                    w_beat  <= w_beat + 8'd1;
                    w_addr  <= w_addr + 32'd4;
                end
            end

            // B response
            if (b_pending & ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                s_axi_bid    <= w_id_q;
            end else if (s_axi_bvalid & s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                b_pending    <= 1'b0;
            end
        end
    end

    //------------------------------------------------------------------
    // Read address + read data channels
    //------------------------------------------------------------------
    reg [31:0] ar_addr;
    reg [7:0]  ar_len;
    reg [3:0]  ar_id_q;
    reg [7:0]  r_beat;
    reg        r_busy, r_valid;

    always @(posedge ui_clk) begin
        if (sys_rst | ~aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= 4'b0;
            s_axi_rdata   <= 32'b0;
            ar_addr       <= 32'b0;
            ar_len        <= 8'b0;
            ar_id_q       <= 4'b0;
            r_beat        <= 8'b0;
            r_busy        <= 1'b0;
            r_valid       <= 1'b0;
        end else begin
            // accept read address
            if (s_axi_arvalid & ~r_busy) begin
                s_axi_arready <= 1'b1;
                ar_addr       <= {s_axi_araddr[31:2], 2'b00};
                ar_len        <= s_axi_arlen;
                ar_id_q       <= s_axi_arid;
                r_busy        <= 1'b1;
                r_beat        <= 8'b0;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // produce read data beats
            if (r_busy & ~r_valid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= rd_word(ar_addr);
                s_axi_rid    <= ar_id_q;
                s_axi_rresp  <= 2'b00; // OKAY
                s_axi_rlast  <= (r_beat == ar_len);
            end else if (s_axi_rvalid & s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                if (r_beat == ar_len) begin
                    r_busy      <= 1'b0;
                    s_axi_rlast <= 1'b0;
                end else begin
                    r_beat  <= r_beat + 8'd1;
                    ar_addr <= ar_addr + 32'd4;
                end
            end
        end
    end

    // tie off unused AXI inputs so lint is quiet
    wire _unused = &{1'b0, s_axi_awsize, s_axi_awburst, s_axi_awlock,
                     s_axi_awcache, s_axi_awprot, s_axi_awqos,
                     s_axi_arsize, s_axi_arburst, s_axi_arlock,
                     s_axi_arcache, s_axi_arprot, s_axi_arqos,
                     app_sr_req, app_ref_req, app_zq_req, clk_ref_i};

endmodule
