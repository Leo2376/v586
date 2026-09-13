 
module v586(
m00_AXI_RSTN,
m00_AXI_CLK,

// AXI4 INSTRUCTION 128 BIT BUS
m00_AXI_AWADDR, 
m00_AXI_AWVALID, 
m00_AXI_AWREADY, 
m00_AXI_AWBURST, 
m00_AXI_AWLEN,
m00_AXI_AWSIZE,

m00_AXI_ARADDR, 
m00_AXI_ARVALID, 
m00_AXI_ARREADY,
m00_AXI_ARBURST, 
m00_AXI_ARLEN,
m00_AXI_ARSIZE,

m00_AXI_WDATA, 
m00_AXI_WVALID, 
m00_AXI_WREADY, 
m00_AXI_WSTRB,
m00_AXI_WLAST,

m00_AXI_RDATA, 
m00_AXI_RVALID, 
m00_AXI_RREADY,
m00_AXI_RLAST,

m00_AXI_BVALID,
m00_AXI_BREADY,

// AXI4 DATA 128 BIT BUS
m01_AXI_AWADDR, 
m01_AXI_AWVALID, 
m01_AXI_AWREADY, 
m01_AXI_AWBURST, 
m01_AXI_AWLEN,
m01_AXI_AWSIZE,

m01_AXI_ARADDR, 
m01_AXI_ARVALID, 
m01_AXI_ARREADY,
m01_AXI_ARBURST, 
m01_AXI_ARLEN,
m01_AXI_ARSIZE,

m01_AXI_WDATA, 
m01_AXI_WVALID, 
m01_AXI_WREADY, 
m01_AXI_WSTRB,
m01_AXI_WLAST,

m01_AXI_RDATA, 
m01_AXI_RVALID, 
m01_AXI_RREADY,
m01_AXI_RLAST,

m01_AXI_BVALID,
m01_AXI_BREADY,


// PERIPH AXI4 32 BIT BUS
m02_AXI_AWADDR, 
m02_AXI_AWVALID, 
m02_AXI_AWREADY, 
m02_AXI_AWBURST, 
m02_AXI_AWLEN,
m02_AXI_AWSIZE,

m02_AXI_ARADDR, 
m02_AXI_ARVALID, 
m02_AXI_ARREADY,
m02_AXI_ARBURST, 
m02_AXI_ARLEN,
m02_AXI_ARSIZE,

m02_AXI_WDATA, 
m02_AXI_WVALID, 
m02_AXI_WREADY, 
m02_AXI_WSTRB,
m02_AXI_WLAST,

m02_AXI_RDATA, 
m02_AXI_RVALID, 
m02_AXI_RREADY,
m02_AXI_RLAST,

m02_AXI_BVALID,
m02_AXI_BREADY,

// interrupts
int_pic,
iack,
ivect,
debug
);

input            m00_AXI_CLK,m00_AXI_RSTN;

// axi instruction bus
output [31:0] m00_AXI_AWADDR, m00_AXI_ARADDR;
output        m00_AXI_AWVALID,m00_AXI_ARVALID,m00_AXI_WVALID,m00_AXI_RREADY,m00_AXI_WLAST;
input         m00_AXI_AWREADY,m00_AXI_ARREADY,m00_AXI_WREADY,m00_AXI_RVALID,m00_AXI_RLAST;
input  [127:0] m00_AXI_RDATA;
output [127:0] m00_AXI_WDATA;
output  [3:0] m00_AXI_WSTRB;
output  [1:0] m00_AXI_ARBURST;
output  [7:0] m00_AXI_ARLEN;
output  [2:0] m00_AXI_ARSIZE;
output  [1:0] m00_AXI_AWBURST;
output  [7:0] m00_AXI_AWLEN;
output  [2:0] m00_AXI_AWSIZE;
output        m00_AXI_BREADY;
input         m00_AXI_BVALID;
// axi data bus
output [31:0] m01_AXI_AWADDR, m01_AXI_ARADDR;
output        m01_AXI_AWVALID,m01_AXI_ARVALID,m01_AXI_WVALID,m01_AXI_RREADY,m01_AXI_WLAST;
input         m01_AXI_AWREADY,m01_AXI_ARREADY,m01_AXI_WREADY,m01_AXI_RVALID,m01_AXI_RLAST;
input  [127:0] m01_AXI_RDATA;
output [127:0] m01_AXI_WDATA;
output  [3:0] m01_AXI_WSTRB;
output  [1:0] m01_AXI_ARBURST;
output  [7:0] m01_AXI_ARLEN;
output  [2:0] m01_AXI_ARSIZE;
output  [1:0] m01_AXI_AWBURST;
output  [7:0] m01_AXI_AWLEN;
output  [2:0] m01_AXI_AWSIZE;
output        m01_AXI_BREADY;
input         m01_AXI_BVALID;
// axi periph bus
output [31:0] m02_AXI_AWADDR, m02_AXI_ARADDR;
output        m02_AXI_AWVALID,m02_AXI_ARVALID,m02_AXI_WVALID,m02_AXI_RREADY,m02_AXI_WLAST;
input         m02_AXI_AWREADY,m02_AXI_ARREADY,m02_AXI_WREADY,m02_AXI_RVALID,m02_AXI_RLAST;
input  [31:0] m02_AXI_RDATA;
output [31:0] m02_AXI_WDATA;
output  [3:0] m02_AXI_WSTRB;
output  [1:0] m02_AXI_ARBURST;
output  [7:0] m02_AXI_ARLEN;
output  [2:0] m02_AXI_ARSIZE;
output  [1:0] m02_AXI_AWBURST;
output  [7:0] m02_AXI_AWLEN;
output  [2:0] m02_AXI_AWSIZE;
output        m02_AXI_BREADY;
input         m02_AXI_BVALID;

input         int_pic;
input   [7:0] ivect;
output        iack;

output   [4:0] debug;

// biu connections
wire [127:0] code_data;
wire [127:0] code_wdata;
wire  [31:0] code_addr;
wire         code_req,code_ack,code_wack,code_wreq;
wire         write_req,read_req,writeio_req,readio_req,writeio_ack,readio_ack;
wire         write_ack,read_ack;
wire  [31:0] Daddr,io_add, readio_data, writeio_data;
wire [127:0] write_data,read_data;
wire   [1:0] write_sz,read_sz;
wire         busy_ram;
wire         repbytecache;
wire  [15:0] write_msk;

wire clk = m00_AXI_CLK;
wire rstn = m00_AXI_RSTN;
assign m00_AXI_BREADY = 1;

core ucore (
.rstn(rstn),.clk(clk), .ivect(ivect)        , .int_main(int_pic)     , .iack(iack)        ,
.code_addr(code_addr), .code_data(code_data), .code_req(code_req)    , .code_ack(code_ack),
.write_req(write_req), .write_ack(write_ack), .write_data(write_data), .Daddr(Daddr)      ,.write_sz(write_sz),
.read_req(read_req)  , .read_ack(read_ack)  , .read_data(read_data)  , .read_sz(read_sz)  ,.write_msk(write_msk),
.code_wreq(code_wreq), .code_wack(code_wack), .code_wdata(code_wdata), 
.writeio_data(writeio_data), .readio_data(readio_data), .io_add(io_add), 
.writeio_req(writeio_req), .readio_req(readio_req),.writeio_ack(writeio_ack), .readio_ack(readio_ack),
.busy_ram(busy_ram)
);
 
biu32_axi ubiu(
.rstn(rstn),.clk(clk), 
.write_req(write_req), .write_ack(write_ack), .write_data(write_data), .write_msk(write_msk),
.read_req(read_req)  , .read_ack(read_ack)  , .read_data(read_data)  , .Daddr(Daddr) ,
.code_req(code_req)  , .code_ack(code_ack)  , .code_data(code_data)  , .code_addr(code_addr) ,
.code_wreq(code_wreq), .code_wack(code_wack), .code_wdata(code_wdata),
.writeio_data(writeio_data), .readio_data(readio_data), .io_add(io_add), 
.writeio_req(writeio_req), .readio_req(readio_req),.writeio_ack(writeio_ack), .readio_ack(readio_ack),
.busy(busy_ram), .outstanding(1'b0),
// axi interface 32bit
.axi_AW(m00_AXI_AWADDR), .axi_AWVALID(m00_AXI_AWVALID), .axi_AWREADY(m00_AXI_AWREADY), 
.axi_AWBURST(m00_AXI_AWBURST), .axi_AWLEN(m00_AXI_AWLEN), .axi_AWSIZE(m00_AXI_AWSIZE),
.axi_W(m00_AXI_WDATA), .axi_WVALID(m00_AXI_WVALID), .axi_WREADY(m00_AXI_WREADY), .axi_WSTRB(m00_AXI_WSTRB), .axi_WLAST(m00_AXI_WLAST),
.axi_AR(m00_AXI_ARADDR), .axi_ARVALID(m00_AXI_ARVALID), .axi_ARREADY(m00_AXI_ARREADY), .axi_RLAST(m00_AXI_RLAST),
.axi_ARBURST(m00_AXI_ARBURST), .axi_ARLEN(m00_AXI_ARLEN), .axi_ARSIZE(m00_AXI_ARSIZE),
.axi_R(m00_AXI_RDATA), .axi_RVALID(m00_AXI_RVALID), .axi_RREADY(m00_AXI_RREADY),
// io interface
.axi_io_AW(m01_AXI_AWADDR), .axi_io_AWVALID(m01_AXI_AWVALID), .axi_io_AWREADY(m01_AXI_AWREADY), 
.axi_io_AWBURST(m01_AXI_AWBURST), .axi_io_AWLEN(m01_AXI_AWLEN), .axi_io_AWSIZE(m01_AXI_AWSIZE),
.axi_io_W(m01_AXI_WDATA), .axi_io_WVALID(m01_AXI_WVALID), .axi_io_WREADY(m01_AXI_WREADY), .axi_io_WSTRB(m01_AXI_WSTRB), .axi_io_WLAST(m01_AXI_WLAST),
.axi_io_AR(m01_AXI_ARADDR), .axi_io_ARVALID(m01_AXI_ARVALID), .axi_io_ARREADY(m01_AXI_ARREADY), .axi_io_RLAST(m01_AXI_RLAST),
.axi_io_ARBURST(m01_AXI_ARBURST), .axi_io_ARLEN(m01_AXI_ARLEN), .axi_io_ARSIZE(m01_AXI_ARSIZE),
.axi_io_R(m01_AXI_RDATA), .axi_io_RVALID(m01_AXI_RVALID), .axi_io_RREADY(m01_AXI_RREADY)
);

endmodule
