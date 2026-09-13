//==========================================================================
//  TOP_SYS_sim.v  --  v10.8.2 simulation system top
//
//  Replaces old/v10.8.2/TOP_SYS.v (which used Xilinx clk_wiz / STARTUPE2 /
//  MIG ddr_axi / axi_crossbar / axi_ethernetlite / IOBUF) with functional
//  simulation models so the v10.8.2 core boots under Verilator/Icarus:
//
//    * v586 CPU core (single 32-bit AXI master m00)   -> axi_mem32
//        - region 0 : RAM 0x000000..0x800000 (kernel @0x100000, initrd,
//                      boot_params @0x90000)
//        - region 1 : boot ROM @0xFFC00 (boot.mem, read-only reset vector)
//    * periph hub (8259/8253/uart16750/spi/gpio) on the 32-bit I/O master
//      port (m01)
//
//  The kernel is preloaded directly into RAM at 0x100000 (see
//  mk_boot_image_v1082.py), so the boot stub does not need to bit-bang the
//  SPI flash. A patched boot stub (boot_v1082.hex) skips the SPI flash copy
//  but still builds boot_params and does `ljmp $0x10:0x100000`.
//
//  SIMULATION ONLY.
//==========================================================================
`timescale 1ns / 1ps
`ifndef LOW_HEX
`define LOW_HEX  "kernel.hex"
`endif
`ifndef HIGH_HEX
`define HIGH_HEX "boot_v1082.hex"
`endif

module TOP_SYS_sim (
    input  wire clk, rstn, RXD,
    output wire TXD,
    output wire [3:0] r4, g4, b4,
    output wire hz, vt,
    output wire [4:0] debug,
    output wire [31:0] dbg_fetch_addr,
    output wire [31:0] dbg_eip,
    output wire        dbg_pc_req,
    output wire [31:0] dbg_lenpc,
    output wire [15:0] dbg_inst,
    output wire [3:0]  dbg_cr0pe,
    output wire [31:0] dbg_ecx,
    output wire [4:0]  dbg_vliw_pc,
    output wire        dbg_pg_fault,
    output wire        dbg_pc_pg_fault,
    output wire [31:0] dbg_Daddr
);
    wire clk_core = clk;
    wire rstn_ddr;
    reg [3:0] calib_cnt;
    wire init_calib;
    always @(posedge clk_core) begin
        if (~rstn) calib_cnt <= 4'd0;
        else if (calib_cnt != 4'd15) calib_cnt <= calib_cnt + 4'd1;
    end
    assign init_calib = (calib_cnt == 4'd15);
    assign rstn_ddr   = rstn & init_calib;

    // m00 (32-bit memory)
    wire [31:0] m00_AW, m00_AR;
    wire        m00_AWVALID, m00_AWREADY, m00_WVALID, m00_WREADY;
    wire        m00_WLAST, m00_RVALID, m00_RREADY, m00_RLAST;
    wire [31:0] m00_WDATA, m00_RDATA;
    wire [3:0]  m00_WSTRB;
    wire [1:0]  m00_AWBURST, m00_ARBURST;
    wire [7:0]  m00_AWLEN, m00_ARLEN;
    wire [2:0]  m00_AWSIZE, m00_ARSIZE;
    wire        m00_BREADY, m00_BVALID;

    // m01 (32-bit I/O)
    wire [31:0] m01_AW, m01_AR;
    wire        m01_AWVALID, m01_AWREADY, m01_WVALID, m01_WREADY;
    wire        m01_WLAST, m01_RVALID, m01_RREADY, m01_RLAST;
    wire [31:0] m01_WDATA, m01_RDATA;
    wire [3:0]  m01_WSTRB;
    wire [1:0]  m01_AWBURST, m01_ARBURST;
    wire [7:0]  m01_AWLEN, m01_ARLEN;
    wire [2:0]  m01_AWSIZE, m01_ARSIZE;
    wire        m01_BREADY, m01_BVALID;

    wire int_pic, iack;
    wire [7:0] ivect;

    v586 cpu (
        .m00_AXI_RSTN(rstn_ddr), .m00_AXI_CLK(clk_core),
        .m00_AXI_AWADDR(m00_AW),  .m00_AXI_AWVALID(m00_AWVALID), .m00_AXI_AWREADY(m00_AWREADY),
        .m00_AXI_AWBURST(m00_AWBURST), .m00_AXI_AWLEN(m00_AWLEN), .m00_AXI_AWSIZE(m00_AWSIZE),
        .m00_AXI_WDATA(m00_WDATA), .m00_AXI_WVALID(m00_WVALID), .m00_AXI_WREADY(m00_WREADY),
        .m00_AXI_WSTRB(m00_WSTRB), .m00_AXI_WLAST(m00_WLAST),
        .m00_AXI_ARADDR(m00_AR),   .m00_AXI_ARVALID(m00_ARVALID), .m00_AXI_ARREADY(m00_ARREADY),
        .m00_AXI_ARBURST(m00_ARBURST), .m00_AXI_ARLEN(m00_ARLEN), .m00_AXI_ARSIZE(m00_ARSIZE),
        .m00_AXI_RDATA(m00_RDATA), .m00_AXI_RVALID(m00_RVALID), .m00_AXI_RREADY(m00_RREADY),
        .m00_AXI_RLAST(m00_RLAST),
        .m00_AXI_BVALID(m00_BVALID), .m00_AXI_BREADY(m00_BREADY),
        .m01_AXI_AWADDR(m01_AW),   .m01_AXI_AWVALID(m01_AWVALID), .m01_AXI_AWREADY(m01_AWREADY),
        .m01_AXI_AWBURST(m01_AWBURST), .m01_AXI_AWLEN(m01_AWLEN), .m01_AXI_AWSIZE(m01_AWSIZE),
        .m01_AXI_WDATA(m01_WDATA), .m01_AXI_WVALID(m01_WVALID), .m01_AXI_WREADY(m01_WREADY),
        .m01_AXI_WSTRB(m01_WSTRB), .m01_AXI_WLAST(m01_WLAST),
        .m01_AXI_ARADDR(m01_AR),   .m01_AXI_ARVALID(m01_ARVALID), .m01_AXI_ARREADY(m01_ARREADY),
        .m01_AXI_ARBURST(m01_ARBURST), .m01_AXI_ARLEN(m01_ARLEN), .m01_AXI_ARSIZE(m01_ARSIZE),
        .m01_AXI_RDATA(m01_RDATA), .m01_AXI_RVALID(m01_RVALID), .m01_AXI_RREADY(m01_RREADY),
        .m01_AXI_RLAST(m01_RLAST),
        .m01_AXI_BVALID(m01_BVALID), .m01_AXI_BREADY(m01_BREADY),
        .int_pic(int_pic), .ivect(ivect), .iack(iack),
        .debug(debug)
    );

    axi_mem32 #(.BASE0(32'h0000_0000), .AW0(23), .LOW_FILE(`LOW_HEX),
                .BASE1(32'h000f_fc00), .AW1(10), .HIGH_FILE(`HIGH_HEX)) ram (
        .clk(clk_core), .rstn(rstn_ddr),
        .s_axi_awaddr(m00_AW),   .s_axi_awlen(m00_AWLEN),
        .s_axi_awsize(m00_AWSIZE),.s_axi_awburst(m00_AWBURST),
        .s_axi_awvalid(m00_AWVALID), .s_axi_awready(m00_AWREADY),
        .s_axi_wdata(m00_WDATA),  .s_axi_wstrb(m00_WSTRB),
        .s_axi_wlast(m00_WLAST),  .s_axi_wvalid(m00_WVALID),
        .s_axi_wready(m00_WREADY),
        .s_axi_bresp(),           .s_axi_bvalid(m00_BVALID),
        .s_axi_bready(m00_BREADY),
        .s_axi_araddr(m00_AR),    .s_axi_arlen(m00_ARLEN),
        .s_axi_arsize(m00_ARSIZE), .s_axi_arburst(m00_ARBURST),
        .s_axi_arvalid(m00_ARVALID), .s_axi_arready(m00_ARREADY),
        .s_axi_rdata(m00_RDATA),  .s_axi_rresp(),
        .s_axi_rlast(m00_RLAST),  .s_axi_rvalid(m00_RVALID),
        .s_axi_rready(m00_RREADY)
    );

    wire [7:0] gpioA_dir, gpioB_dir, gpioA_out, gpioB_out;
    assign gpioA_out = 0; assign gpioB_out = 0;
    periph i_periph (
        .s00_AXI_CLK(clk_core), .s00_AXI_RSTN(rstn_ddr),
        .cfg(7'b0),
        .spi_mosi(), .spi_miso(1'b1), .spi_clk(), .spi_cs(),
        .mosi(), .miso(1'b1), .sclk(),
        .s00_AXI_AWADDR(m01_AW),  .s00_AXI_AWVALID(m01_AWVALID), .s00_AXI_AWREADY(m01_AWREADY),
        .s00_AXI_AWBURST(m01_AWBURST), .s00_AXI_AWLEN(m01_AWLEN[3:0]), .s00_AXI_AWSIZE(m01_AWSIZE),
        .s00_AXI_ARADDR(m01_AR),  .s00_AXI_ARVALID(m01_ARVALID), .s00_AXI_ARREADY(m01_ARREADY),
        .s00_AXI_ARBURST(m01_ARBURST), .s00_AXI_ARLEN(m01_ARLEN[3:0]), .s00_AXI_ARSIZE(m01_ARSIZE),
        .s00_AXI_WDATA(m01_WDATA), .s00_AXI_WVALID(m01_WVALID), .s00_AXI_WREADY(m01_WREADY),
        .s00_AXI_WSTRB(m01_WSTRB), .s00_AXI_WLAST(m01_WLAST),
        .s00_AXI_RDATA(m01_RDATA), .s00_AXI_RVALID(m01_RVALID), .s00_AXI_RREADY(m01_RREADY),
        .s00_AXI_RLAST(m01_RLAST),
        .s00_AXI_BVALID(m01_BVALID), .s00_AXI_BREADY(m01_BREADY),
        .int_pic(int_pic), .ivect(ivect), .iack(iack), .int_bus(4'b0),
        .gpioA_in(8'b0), .gpioB_in(8'b0),
        .gpioA_out(gpioA_out), .gpioB_out(gpioB_out),
        .gpioA_dir(gpioA_dir), .gpioB_dir(gpioB_dir),
        .RXD(RXD), .TXD(TXD),
        .ps2data(1'b1), .ps2clk()
    );

    assign r4 = 4'b0; assign g4 = 4'b0; assign b4 = 4'b0;
    assign hz = 1'b0; assign vt = 1'b0;

    // debug taps into the core (v10.8.2 hierarchy)
    assign dbg_fetch_addr = cpu.ucore.i_useq.addr;
    assign dbg_eip        = cpu.ucore.i_cpu.i_vliw.regs[14];
    assign dbg_pc_req     = cpu.ucore.pc_req;
    assign dbg_lenpc      = cpu.ucore.lenpc;
    assign dbg_inst       = cpu.ucore.queue[15:0];
    assign dbg_cr0pe      = cpu.ucore.cr0[0];
    assign dbg_ecx        = cpu.ucore.i_cpu.i_vliw.regs[1];
    assign dbg_vliw_pc    = cpu.ucore.i_cpu.i_vliw.vliw_pc;
    assign dbg_pg_fault   = cpu.ucore.pg_fault;
    assign dbg_pc_pg_fault = cpu.ucore.pc_pg_fault;
    assign dbg_Daddr      = cpu.ucore.Daddr;
endmodule
