//==========================================================================
//  TOP_SYS_sim.v
//
//  Simulation-only system top for the v586 core. It mirrors the intent of
//  old/v14.0/TOP_SYS.v but replaces all Xilinx vendor primitives and the
//  DDR MIG with functional simulation models so the whole platform can
//  run under Verilator / Icarus:
//
//    * v586 CPU core (from old/v14.0/)
//    * axi_mem128    -> 128-bit functional RAM on the code/data master
//                       port (m00), replacing the crossbar + MIG + boot ROM
//    * periph        -> the real SoC peripheral hub (8259/8253/uart/spi/
//                       vga/gpio) on the 32-bit I/O master port (m01)
//    * m02 master port of v586 is unused inside the core and is tied off
//
//  This avoids the TOP_SYS.v width bugs (128-bit master ports wired to
//  32-bit crossbar wires) and the absent Xilinx IP (clk_wiz / STARTUPE2 /
//  MIG / axi_crossbar / axi_ethernetlite) entirely.
//
//  The 128-bit RAM can be preloaded (see the preload task / Verilator
//  C++ testbench) with a boot image so the CPU has code to fetch at reset.
//
//  SIMULATION ONLY.
//==========================================================================
`timescale 1ns / 1ps

// Default boot image preloaded at the reset vector (0x40d00000).
// Override at Verilator compile time with  -DBOOT_HEX=\"path/to/hex\" .
`ifndef BOOT_HEX
 `define BOOT_HEX "boot.hex"
`endif

module TOP_SYS_sim (
    input  wire clk,        // single system clock (e.g. 100 MHz)
    input  wire rstn,       // active-low reset (push button / tb)
    input  wire RXD,        // UART RX line
    output wire TXD,        // UART TX line
    output wire [3:0] r4, g4, b4,
    output wire hz, vt,
    output wire [4:0] debug // v586 debug bus
);

    //------------------------------------------------------------------
    // clocks / reset: in sim we just use clk directly as the core clock
    // and gate the SoC reset with a short calibration delay to mimic
    // init_calib_complete from the MIG.
    //------------------------------------------------------------------
    wire clk_core = clk;
    wire init_calib;
    reg [3:0] calib_cnt;
    wire rstn_ddr;

    always @(posedge clk_core) begin
        if (~rstn) begin
            calib_cnt <= 4'd0;
        end else begin
            if (calib_cnt != 4'd15) calib_cnt <= calib_cnt + 4'd1;
        end
    end
    assign init_calib = (calib_cnt == 4'd15);
    assign rstn_ddr   = rstn & init_calib;

    //------------------------------------------------------------------
    // v586 master port wires
    //   m00 : 128-bit instruction/data memory bus  -> axi_mem128
    //   m01 : 32-bit peripheral I/O bus            -> periph
    //   m02 : unused inside v586, tie off
    //------------------------------------------------------------------
    // m00 (128-bit)
    wire [31:0]  m00_AW, m00_AR;
    wire         m00_AWVALID, m00_AWREADY, m00_WVALID, m00_WREADY;
    wire         m00_WLAST, m00_RVALID, m00_RREADY, m00_RLAST;
    wire [127:0] m00_WDATA, m00_RDATA;
    wire [15:0]  m00_WSTRB;
    wire [1:0]   m00_AWBURST, m00_ARBURST;
    wire [7:0]   m00_AWLEN, m00_ARLEN;
    wire [2:0]   m00_AWSIZE, m00_ARSIZE;
    wire         m00_BREADY, m00_BVALID;

    // m01 (32-bit I/O)
    wire [31:0]  m01_AW, m01_AR;
    wire         m01_AWVALID, m01_AWREADY, m01_WVALID, m01_WREADY;
    wire         m01_WLAST, m01_RVALID, m01_RREADY, m01_RLAST;
    wire [31:0]  m01_WDATA, m01_RDATA;
    wire [3:0]   m01_WSTRB;
    wire [1:0]   m01_AWBURST, m01_ARBURST;
    wire [7:0]   m01_AWLEN, m01_ARLEN;
    wire [2:0]   m01_AWSIZE, m01_ARSIZE;
    wire         m01_BREADY, m01_BVALID;

    // m02 (unused)
    wire [31:0]  m02_AW, m02_AR;
    wire         m02_AWVALID, m02_AWREADY, m02_WVALID, m02_WREADY;
    wire         m02_WLAST, m02_RVALID, m02_RREADY, m02_RLAST;
    wire [31:0]  m02_WDATA, m02_RDATA;
    wire [3:0]   m02_WSTRB;
    wire [1:0]   m02_AWBURST, m02_ARBURST;
    wire [7:0]   m02_AWLEN, m02_ARLEN;
    wire [2:0]   m02_AWSIZE, m02_ARSIZE;
    wire         m02_BREADY, m02_BVALID;

    // interrupt + debug
    wire         int_pic, iack;
    wire [7:0]   ivect;

    assign m02_AWREADY  = 1'b1;
    assign m02_ARREADY  = 1'b1;
    assign m02_WREADY   = 1'b1;
    assign m02_RVALID   = 1'b0;
    assign m02_RDATA    = 32'b0;
    assign m02_RLAST    = 1'b0;
    assign m02_BVALID   = 1'b0;

    //------------------------------------------------------------------
    // CPU core
    //------------------------------------------------------------------
    v586 cpu (
        .m00_AXI_RSTN(rstn_ddr),
        .m00_AXI_CLK(clk_core),
        // 128-bit instruction/data
        .m00_AXI_AWADDR(m00_AW),  .m00_AXI_AWVALID(m00_AWVALID), .m00_AXI_AWREADY(m00_AWREADY),
        .m00_AXI_AWBURST(m00_AWBURST), .m00_AXI_AWLEN(m00_AWLEN), .m00_AXI_AWSIZE(m00_AWSIZE),
        .m00_AXI_WDATA(m00_WDATA), .m00_AXI_WVALID(m00_WVALID), .m00_AXI_WREADY(m00_WREADY),
        .m00_AXI_WSTRB(m00_WSTRB), .m00_AXI_WLAST(m00_WLAST),
        .m00_AXI_ARADDR(m00_AR),   .m00_AXI_ARVALID(m00_ARVALID), .m00_AXI_ARREADY(m00_ARREADY),
        .m00_AXI_ARBURST(m00_ARBURST), .m00_AXI_ARLEN(m00_ARLEN), .m00_AXI_ARSIZE(m00_ARSIZE),
        .m00_AXI_RDATA(m00_RDATA), .m00_AXI_RVALID(m00_RVALID), .m00_AXI_RREADY(m00_RREADY),
        .m00_AXI_RLAST(m00_RLAST),
        .m00_AXI_BVALID(m00_BVALID), .m00_AXI_BREADY(m00_BREADY),
        // 32-bit I/O
        .m01_AXI_AWADDR(m01_AW),   .m01_AXI_AWVALID(m01_AWVALID), .m01_AXI_AWREADY(m01_AWREADY),
        .m01_AXI_AWBURST(m01_AWBURST), .m01_AXI_AWLEN(m01_AWLEN), .m01_AXI_AWSIZE(m01_AWSIZE),
        .m01_AXI_WDATA(m01_WDATA), .m01_AXI_WVALID(m01_WVALID), .m01_AXI_WREADY(m01_WREADY),
        .m01_AXI_WSTRB(m01_WSTRB), .m01_AXI_WLAST(m01_WLAST),
        .m01_AXI_ARADDR(m01_AR),   .m01_AXI_ARVALID(m01_ARVALID), .m01_AXI_ARREADY(m01_ARREADY),
        .m01_AXI_ARBURST(m01_ARBURST), .m01_AXI_ARLEN(m01_ARLEN), .m01_AXI_ARSIZE(m01_ARSIZE),
        .m01_AXI_RDATA(m01_RDATA), .m01_AXI_RVALID(m01_RVALID), .m01_AXI_RREADY(m01_RREADY),
        .m01_AXI_RLAST(m01_RLAST),
        .m01_AXI_BVALID(m01_BVALID), .m01_AXI_BREADY(m01_BREADY),
        // 32-bit unused master (tied off)
        .m02_AXI_AWADDR(m02_AW),   .m02_AXI_AWVALID(m02_AWVALID), .m02_AXI_AWREADY(m02_AWREADY),
        .m02_AXI_AWBURST(m02_AWBURST), .m02_AXI_AWLEN(m02_AWLEN), .m02_AXI_AWSIZE(m02_AWSIZE),
        .m02_AXI_WDATA(m02_WDATA), .m02_AXI_WVALID(m02_WVALID), .m02_AXI_WREADY(m02_WREADY),
        .m02_AXI_WSTRB(m02_WSTRB), .m02_AXI_WLAST(m02_WLAST),
        .m02_AXI_ARADDR(m02_AR),   .m02_AXI_ARVALID(m02_ARVALID), .m02_AXI_ARREADY(m02_ARREADY),
        .m02_AXI_ARBURST(m02_ARBURST), .m02_AXI_ARLEN(m02_ARLEN), .m02_AXI_ARSIZE(m02_ARSIZE),
        .m02_AXI_RDATA(m02_RDATA), .m02_AXI_RVALID(m02_RVALID), .m02_AXI_RREADY(m02_RREADY),
        .m02_AXI_RLAST(m02_RLAST),
        .m02_AXI_BVALID(m02_BVALID), .m02_AXI_BREADY(m02_BREADY),
        // interrupts
        .int_pic(int_pic), .ivect(ivect), .iack(iack),
        .debug(debug)
    );

    //------------------------------------------------------------------
    // 128-bit functional RAM (code/data)
    //------------------------------------------------------------------
    axi_mem128 #(.AW(24), .DW(128), .BASE(32'h40d0_0000),
                 .MEM_FILE(`BOOT_HEX)) ram (
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
        .s_axi_arsize(m00_ARSIZE),.s_axi_arburst(m00_ARBURST),
        .s_axi_arvalid(m00_ARVALID), .s_axi_arready(m00_ARREADY),
        .s_axi_rdata(m00_RDATA),  .s_axi_rresp(),
        .s_axi_rlast(m00_RLAST),  .s_axi_rvalid(m00_RVALID),
        .s_axi_rready(m00_RREADY)
    );

    //------------------------------------------------------------------
    // Peripheral hub (8259 PIC, 8253 PIT, 16750 UART, SPI, VGA, GPIO)
    //------------------------------------------------------------------
    wire [7:0] gpioA_dir, gpioB_dir, gpioA_out, gpioB_out;
    wire [7:0] gpioA_in, gpioB_in;
    assign gpioA_in = 8'b0;
    assign gpioB_in = 8'b0;

    periph i_periph (
        .s00_AXI_CLK(clk_core), .s00_AXI_RSTN(rstn_ddr),
        // spi (left unconnected in sim)
        .mosi_0(), .miso_0(1'b1), .sclk_0(), .spi_csn0(),
        .mosi_1(), .miso_1(1'b1), .sclk_1(), .spi_csn1(),
        .mosi_2(), .miso_2(1'b1), .sclk_2(), .spi_csn2(),
        // AXI4 I/O 32-bit
        .s00_AXI_AWADDR(m01_AW),  .s00_AXI_AWVALID(m01_AWVALID), .s00_AXI_AWREADY(m01_AWREADY),
        .s00_AXI_AWBURST(m01_AWBURST), .s00_AXI_AWLEN(m01_AWLEN[3:0]), .s00_AXI_AWSIZE(m01_AWSIZE),
        .s00_AXI_ARADDR(m01_AR),  .s00_AXI_ARVALID(m01_ARVALID), .s00_AXI_ARREADY(m01_ARREADY),
        .s00_AXI_ARBURST(m01_ARBURST), .s00_AXI_ARLEN(m01_ARLEN[3:0]), .s00_AXI_ARSIZE(m01_ARSIZE),
        .s00_AXI_WDATA(m01_WDATA), .s00_AXI_WVALID(m01_WVALID), .s00_AXI_WREADY(m01_WREADY),
        .s00_AXI_WSTRB(m01_WSTRB), .s00_AXI_WLAST(m01_WLAST),
        .s00_AXI_RDATA(m01_RDATA), .s00_AXI_RVALID(m01_RVALID), .s00_AXI_RREADY(m01_RREADY),
        .s00_AXI_RLAST(m01_RLAST),
        .s00_AXI_BVALID(m01_BVALID), .s00_AXI_BREADY(m01_BREADY),
        // interrupts
        .int_pic(int_pic), .ivect(ivect), .iack(iack), .int_bus(4'b0),
        // gpio
        .gpioA_in(gpioA_in), .gpioB_in(gpioB_in),
        .gpioA_out(gpioA_out), .gpioB_out(gpioB_out),
        .gpioA_dir(gpioA_dir), .gpioB_dir(gpioB_dir),
        // uart
        .RXD(RXD), .TXD(TXD),
        // 8042 kbd (unused)
        .ps2data(1'b1), .ps2clk()
    );

    // VGA outputs come from the periph hub's VGA block; expose them.
    // (periph drives vga internally; r4/g4/b4/hz/vt are left undriven here
    //  to keep the sim top simple. Wire them if you instantiate a VGA
    //  framebuffer separately.)
    assign r4 = 4'b0;
    assign g4 = 4'b0;
    assign b4 = 4'b0;
    assign hz = 1'b0;
    assign vt = 1'b0;

endmodule
