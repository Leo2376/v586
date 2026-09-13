module tb_top ();
wire  [1:0] Ae;
wire [15:0] DB;
wire [23:0] Ad;
wire        LB,UB;
reg         RXD,clk,rstn;


wire	       ck;
wire	       ck_n;
wire	       cke;
wire	       cs_n;
wire	       ras_n;
wire	       cas_n;
wire	       we_n;
wire	 [1:0] dm_rdqs;
wire	 [2:0] ba;
wire	[12:0] addr;
wire	[15:0] dq;
wire	 [1:0] dqs;
wire	 [1:0] dqs_n;
wire     [1:0] rdqs_n;
wire	       odt;


TOP_SYS U_TOP (
.TXD(TXD),.rstn(rstn),.clk100(clk), .RXD(RXD),
// DDR2
.DDR2DQ(dq),
.DDR2DQS_N(dqs_n),
.DDR2DQS_P(dqs),
.DDR2ADDR(addr),
.DDR2BA(ba),
.DDR2RAS_N(ras_n),
.DDR2CAS_N(cas_n),
.DDR2WE_N(we_n),
.DDR2CK_P(ck),
.DDR2CK_N(ck_n),
.DDR2CKE(cke),
.DDR2CS_N(cs_n),
.DDR2DM(dm_rdqs),
.DDR2ODT(odt),

.miso_0(1'b1),
.miso_1(1'b1)
);

initial
begin
RXD =1;
clk=0;
rstn =0;
#1000
rstn = 1;
#100000
$finish;
end

always #5 clk<=~clk;

always @(posedge clk) if ((U_TOP.v586.writeio_req == 1)&&(U_TOP.i_periph.csn_16750 == 0)) $write("%c",U_TOP.i_periph.writeio_data[7:0]);

ddr2 i_ddr2 (
    .ck(ck),
    .ck_n(ck_n),
    .cke(cke),
    .cs_n(cs_n),
    .ras_n(ras_n),
    .cas_n(cas_n),
    .we_n(we_n),
    .dm_rdqs(dm_rdqs),
    .ba(ba),
    .addr({1'b0,addr}),
    .dq(dq),
    .dqs(dqs),
    .dqs_n(dqs_n),
    .rdqs_n(rsqs_n),
    .odt(odt)
);

endmodule
