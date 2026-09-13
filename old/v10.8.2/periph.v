module periph(
s00_AXI_RSTN,
s00_AXI_CLK,
cfg,
// spi
spi_mosi,
spi_miso,
spi_clk,
spi_cs,
// tiny spi
mosi,
miso,
sclk,
// AXI4 32 BIT BUS
s00_AXI_AWADDR, 
s00_AXI_AWVALID, 
s00_AXI_AWREADY, 
s00_AXI_AWBURST, 
s00_AXI_AWLEN,
s00_AXI_AWSIZE,

s00_AXI_ARADDR, 
s00_AXI_ARVALID, 
s00_AXI_ARREADY,
s00_AXI_ARBURST, 
s00_AXI_ARLEN,
s00_AXI_ARSIZE,

s00_AXI_WDATA, 
s00_AXI_WVALID, 
s00_AXI_WREADY, 
s00_AXI_WSTRB,
s00_AXI_WLAST,

s00_AXI_RDATA, 
s00_AXI_RVALID, 
s00_AXI_RREADY,
s00_AXI_RLAST,

s00_AXI_BVALID,
s00_AXI_BREADY,

// interrupts
int_pic,
ivect,
iack,
int_bus,
// gpio
gpioA_in,
gpioB_in,
gpioA_dir,
gpioB_dir,
gpioA_out,
gpioB_out,
//uart
TXD,
RXD,
//kbd 8042
ps2data,
ps2clk
);

input            s00_AXI_CLK,s00_AXI_RSTN;
input    [6:0]   cfg;
output           spi_mosi,spi_clk,spi_cs;
input            spi_miso;
//  tiny spi
output mosi;
input miso;
output sclk;

// axi bus
input  [31:0] s00_AXI_AWADDR, s00_AXI_ARADDR;
input         s00_AXI_AWVALID,s00_AXI_ARVALID,s00_AXI_WVALID,s00_AXI_RREADY,s00_AXI_WLAST;
output reg    s00_AXI_AWREADY,s00_AXI_ARREADY,s00_AXI_WREADY,s00_AXI_RVALID,s00_AXI_RLAST;
output reg [31:0] s00_AXI_RDATA;
input  [31:0] s00_AXI_WDATA;
input   [3:0] s00_AXI_WSTRB;
input   [1:0] s00_AXI_ARBURST;
input   [3:0] s00_AXI_ARLEN;
input   [2:0] s00_AXI_ARSIZE;
input   [1:0] s00_AXI_AWBURST;
input   [3:0] s00_AXI_AWLEN;
input   [2:0] s00_AXI_AWSIZE;
input         s00_AXI_BREADY;
output        s00_AXI_BVALID;

output        int_pic;
output  [7:0] ivect;
input         iack;
input   [3:0] int_bus;

output  [7:0] gpioA_out,gpioB_out;
output  [7:0] gpioA_dir,gpioB_dir;
input   [7:0] gpioA_in,gpioB_in;

output TXD;
input RXD;

output ps2clk;
input ps2data;

//internal wires a regs

// Internal IO BUS 
reg         write_reqf,write_reqff;
wire        rdn_16750;
wire  [7:0] rdio_8042,rdio_16750,rdio_pic,rdio_pic1,rdio_pic2,rdio_spk,rdio_pit;
wire        wrn_8042,csn_8042,wrn_16750,csn_16750,wrn_pic,int_uart,pit_irq;
reg  [31:0] readio_data_f,rdio_16750_f;
wire [31:0] readio_data;
reg   [7:0] superIO_idx,superIOa_dir,superIOb_dir,reg290,reg291,superIOa,superIOb;
wire  [7:0] superIO_read;

reg [31:0] io_add;
reg [31:0] writeio_data;


// uart wires	
reg   [5:0] div_clke;
wire        rclk;
wire        baudout;
// spi wires
reg    [8:0] bit_bang;
reg          bit_bang_sclk;
reg  [31:0]  bit_bang_shift;
reg [7:0] gpio_out;
wire [31:0] dat_o_spi_0;
wire cs_spi_0;
wire we_spi_0;
reg [3:0] int_reg;


assign s00_AXI_BVALID = 1;

// Internal IO BUS : read back
assign readio_data = (io_add[15:2] == 14'b0000_0000_0100_00  ) ? rdio_pit  :
                     (io_add[15:1] == 15'b0000_0000_0010_000 ) ? rdio_pic1 :
                     (io_add[15:1] == 15'b0000_0000_1010_000 ) ? rdio_pic2 :
                     (io_add[15:1] == 15'b0000_0000_0111_000 ) ? 32'h0  :		     
                     (io_add == 32'h80) ? 32'hffff_ffff :
                     (io_add == 32'h2e8) ? 32'hffff_ffff :
                     (io_add == 32'h3e8) ? 32'hffff_ffff :
                     (io_add[15:0] == 16'b0000_0000_0110_0001 ) ? rdio_spk :
                     (io_add[15:0] == 16'h0500) ? {24'b0,spi_miso,cfg[6:0]} : // cfg
                     (io_add[15:0] == 16'h0504) ? bit_bang_shift:  // spi derialized read
                     (io_add[15:0] == 16'h002f) ? {24'b0,superIO_read} : // superIO read register (60/61/F0/F1/20/21)
                     (io_add[15:0] == 16'h0290) ? {24'b0,reg290} : // superIO gpio input bank a
                     (io_add[15:0] == 16'h0291) ? {24'b0,reg291} : // superIO gpio input bank b
	             ({io_add[15:3],3'b000} == 16'h0060) ? {24'b0,rdio_8042} :
	             ({io_add[15:3],3'b000} == 16'h03f8) ? {24'b0,rdio_16750} :
	             ({io_add[15:6],6'b0} == 16'h0100) ? dat_o_spi_0 :
			          32'hffff_ffff;

assign superIO_read = (superIO_idx == 8'h60) ? 8'h02:
                      (superIO_idx == 8'h61) ? 8'h90:
		      (superIO_idx == 8'h20) ? 8'h87:
		      (superIO_idx == 8'h21) ? 8'h61:
		      (superIO_idx == 8'hf0) ? superIOa_dir:
		      (superIO_idx == 8'hf1) ? superIOb_dir: 8'h0;


//
// Internal IO BUS :  write generate & decode
//
always @(posedge s00_AXI_CLK or negedge s00_AXI_RSTN)
if (s00_AXI_RSTN == 0)
 begin 
  s00_AXI_AWREADY <= 0;
  s00_AXI_ARREADY <= 0;
  s00_AXI_WREADY  <= 0;
  s00_AXI_RVALID  <= 0;
  s00_AXI_RLAST   <= 0;
  io_add <=0;
  s00_AXI_RDATA   <= 32'hffffffff;
  readio_data_f   <= 0;
 end
else
begin
 if ( ((s00_AXI_AWVALID == 1) && (s00_AXI_AWREADY ==0)) ) begin s00_AXI_AWREADY <=1; io_add <= {16'b0,s00_AXI_AWADDR[17:2]}; end else
 if ( ((s00_AXI_ARVALID == 1) && (s00_AXI_ARREADY ==0)) ) begin s00_AXI_ARREADY <=1; io_add <= {16'b0,s00_AXI_ARADDR[17:2]}; end else
                                                          begin s00_AXI_ARREADY <=0; s00_AXI_AWREADY <=0; end

 if ( ((s00_AXI_WVALID  == 1) && (s00_AXI_WREADY  ==0)) ) begin s00_AXI_WREADY <=1; writeio_data <= s00_AXI_WDATA; if (io_add !=32'h80) readio_data_f <= writeio_data; end else
                                                          begin s00_AXI_WREADY <=0; writeio_data <= 0; readio_data_f <= {24'b0,rdio_16750}; end
 
 if (s00_AXI_ARREADY ==1) s00_AXI_RVALID <=1; else s00_AXI_RVALID <=0;
 
 s00_AXI_RDATA <= readio_data;
end

//
// SPI/GPIO/SuperIO
//

always @(posedge s00_AXI_CLK or negedge s00_AXI_RSTN)
if (s00_AXI_RSTN == 0) 
 begin 
  gpio_out <=0; bit_bang <= 0; 
  bit_bang_sclk <=0; bit_bang_shift <= 0;
  superIO_idx <=0; 
  superIOa_dir<=0; superIOb_dir<=0;
  superIOa    <=0; superIOb    <=0;
  reg290      <=0; reg291      <=0;
end 
else
  begin 
  reg290 <= (superIOa_dir & superIOa) | (gpioA_in & ~superIOa_dir);
  reg291 <= (superIOb_dir & superIOb) | (gpioB_in & ~superIOb_dir);
  if ((io_add[15:0]==16'h0500) && (s00_AXI_WREADY == 1)) gpio_out <= writeio_data[7:0]; else 
  if ((io_add[15:0]==16'h0504) && (s00_AXI_WREADY == 1)) bit_bang <= {writeio_data[5:0],3'b0}; else
  if ((io_add[15:0]==16'h002e) && (s00_AXI_WREADY == 1)) superIO_idx <= writeio_data[7:0]; else
  if ((io_add[15:0]==16'h002f) && (s00_AXI_WREADY == 1) &&(superIO_idx == 8'hf0)) superIOa_dir <= writeio_data[7:0]; else
  if ((io_add[15:0]==16'h002f) && (s00_AXI_WREADY == 1) &&(superIO_idx == 8'hf1)) superIOb_dir <= writeio_data[7:0]; else
  if ((io_add[15:0]==16'h0290) && (s00_AXI_WREADY == 1)) superIOa <= writeio_data[7:0]; else
  if ((io_add[15:0]==16'h0291) && (s00_AXI_WREADY == 1)) superIOb <= writeio_data[7:0]; else
  if (bit_bang != 0) 
      begin
       bit_bang <= bit_bang -1;
		 if ((bit_bang[2:0] >2) && (bit_bang[2:0]<6)) bit_bang_sclk <= 1'b1; else bit_bang_sclk<=1'b0;
		 if (bit_bang[2:0] == 3'b000) bit_bang_shift <= {bit_bang_shift[30:0],spi_miso};
      end
  end
  
// External IOs

assign spi_mosi = gpio_out[0];
assign spi_cs   = gpio_out[2];
assign spi_clk  = gpio_out[1]|bit_bang_sclk;

assign gpioA_out = reg290;
assign gpioB_out = reg291;

assign gpioA_dir = superIOa_dir;
assign gpioB_dir = superIOb_dir;

//
// uarts
//
always @(posedge s00_AXI_CLK or negedge s00_AXI_RSTN)
if (s00_AXI_RSTN == 0) div_clke <= 0; else
 if (div_clke == 6'd53) div_clke <= 0; else div_clke <= div_clke + 1;
   
assign clke      = (div_clke == 6'd5) ? 1'b1 : 1'b0;   
assign csn_16750 = ({io_add[15:3],3'b0} == 16'h03f8) ? 1'b0 : 1'b1;
assign wrn_16750 = (s00_AXI_WREADY == 1)      ? 1'b0 : 1'b1;
assign rdn_16750 = (s00_AXI_ARREADY == 1) ? 1'b0 : 1'b1 ;

uart_16750 A16750 (
        .CLK(s00_AXI_CLK),
        .RST(~s00_AXI_RSTN),
        .BAUDCE(clke),
        .CS(~csn_16750),
        .WR(~wrn_16750),
        .RD(~rdn_16750),
        .A(io_add[2:0]),
        .DIN(writeio_data[7:0]),
        .DOUT(rdio_16750),
        .DDIS(),
        .INT(int_uart),
        .OUT1N(),
        .OUT2N(),
        .RCLK(baudout),
        .BAUDOUTN(baudout),
        .RTSN(),
        .DTRN(),
        .CTSN(1'b1),
        .DSRN(1'b1),
        .DCDN(1'b1),
        .RIN(1'b1),
        .SIN(RXD),
        .SOUT(TXD)
    );

//
// Interrupt Controller : 8259
//
assign rd_pic1 =(({io_add[15:1]} == 15'b0010_000) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign wr_pic1 =(({io_add[15:1]} == 15'b0010_000) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;
assign rd_pic2 =(({io_add[15:1]} == 15'b1010_000) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign wr_pic2 =(({io_add[15:1]} == 15'b1010_000) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;

v8259 U8259(.clk(s00_AXI_CLK),
.rst_n(s00_AXI_RSTN),.ms_address(io_add[0]),.ms_read(rd_pic1),.ms_readdata(rdio_pic1),
.ms_write(wr_pic1),
.ms_writedata(writeio_data[7:0]),.sl_address(io_add[0]),.sl_read(rd_pic2),.sl_readdata(rdio_pic2),
.sl_write(wr_pic2),.sl_writedata(writeio_data[7:0]),
.inter_input({7'b0,int_reg[3:0],int_uart,1'b0,1'b0,1'b0,~pit_irq}),
.inter_do(int_pic),.inter_vector(ivect),.inter_done(iack)
);

always @(posedge s00_AXI_CLK or negedge s00_AXI_RSTN)
 if (s00_AXI_RSTN == 0) int_reg <= 0; else int_reg <= int_bus;


// PIT : i8253
assign rd_pit =(({io_add[15:2]} == 14'b0100_00  ) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign wr_pit =(({io_add[15:2]} == 14'b0100_00  ) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;
assign rd_spk =(({io_add[15:0]} == 16'b0110_0001) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign wr_spk =(({io_add[15:0]} == 16'b0110_0001) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;

v8253 U8253(.rst_n(s00_AXI_RSTN), .clk(s00_AXI_CLK), .irq(pit_irq),
.io_address(io_add[1:0]),.io_read(rd_pit),.io_readdata(rdio_pit),.io_write(wr_pit),.io_writedata(writeio_data[7:0]),
.port_61h_read(rd_spk),.port_61h_readdata(rdio_spk),.port_61h_write(wr_spk),.port_61h_writedata(writeio_data[7:0]),
.cyc_ratio(8'd83),.cyc_ratio2(8'd7));

// 8042 stub
assign csn_8042 =(({io_add[15:6],6'b0} == 16'h0060 ) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign wrn_8042 =(({io_add[15:6],6'b0} == 16'h0060 ) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;
v8042 U8042(
.rst_n(s00_AXI_RSTN), .clk(s00_AXI_CLK), 
.io_address(io_add[2:0]),.io_read(csn_8042),.io_readdata(rdio_8042),.io_write(wrn_8042),.io_writedata(writeio_data[7:0]),
.ps2clk(ps2clk), .ps2data(ps2data) );


// TINY SPI INTERFACE
assign cs_spi_0 =(({io_add[15:6],6'b0} == 16'h0100 ) && (s00_AXI_WREADY == 0)) ? 1'b1 : 1'b0;	      
assign we_spi_0 =(({io_add[15:6],6'b0} == 16'h0100 ) && (s00_AXI_WREADY == 1)) ? 1'b1 : 1'b0;

tiny_spi uspi_0 (.rst_i(~s00_AXI_RSTN), .clk_i(s00_AXI_CLK), .stb_i(cs_spi_0|we_spi_0), .we_i(we_spi_0), .dat_o(dat_o_spi_0), .dat_i(writeio_data), .adr_i(io_add[5:2]), .MOSI(mosi), .SCLK(sclk) , .MISO(miso) , .int_o(int_spi) );

endmodule
