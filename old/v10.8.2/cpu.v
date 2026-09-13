module cpu (
clk,
rstn,
iack,
int_cpu,
ivect,
cr0,
cr2,
icr2,
cr3,
cs,
pg_fault,
ipg_fault,
useq_ptr,
valid_len,
queue,
pg_en,
pc_out,
pc_req,
read_req,
write_req,
read_ack,
write_ack,
flush_Itlb,
flush_Dtlb,
readio_req,
writeio_req,
readio_ack,
writeio_ack,
write_data,
writeio_data,
read_data,
readio_data,
write_sz,
read_sz,
io_add,
Daddr,
pt_fault,
wr_fault
);

input         clk,rstn;
output        iack;
input         int_cpu;
input   [7:0] ivect;
output [31:0] cr0,cr3;
input  [31:0] icr2,cr2;
output [31:0] cs;
input         pg_fault;
input         ipg_fault;
output  [3:0] useq_ptr;
input   [5:0] valid_len;
input [127:0] queue;
output        pg_en;
output [31:0] pc_out;
output        pc_req;
output        read_req;
output        write_req;
input         read_ack;
input         write_ack;
output        flush_Itlb;
output        flush_Dtlb;
output        readio_req;
output        writeio_req;
input         readio_ack;
input         writeio_ack;
output [31:0] write_data;
output [31:0] writeio_data;
input  [31:0] read_data;
input  [31:0] readio_data;
output [31:0] io_add;
output  [1:0] write_sz,read_sz;
output [31:0] Daddr;
input         pt_fault;
input         wr_fault;

wire         ie;
wire  [128+1+1+73+8-1:0] deco2acu;
wire  [63:0] to_acu;
wire   [7:0] from_acu;
wire  [31:0] add_src,lenpc;
wire  [63:0] imm;
wire  [127:0] dec2vliw;
wire  term;
wire  st;
wire   [2:0] opz,seg_src;
wire   [2:0] reps;
wire   [5:0] over_seg;
wire         adz;
wire  [31:0] write_data;
wire   [5:0] valid_len;
wire         ready_vliw,valid_op;

assign adz = cr0[0];

deco i_deco (.clk(clk), .rstn(rstn), .immediate(imm), .term(term), .start(st), .ivect(ivect), .ie(ie), .int_main(int_cpu), .iack(iack),
             .useq_ptr(useq_ptr), .lenpc_out(lenpc), .cpl(cs[1:0]), .valid_len(valid_len), .ready_vliw(ready_vliw), .valid_op(valid_op),
	     .pc_req(pc_req),.to_acu(deco2acu), .in128(queue), .to_vliw(dec2vliw), .cr0(cr0),
	     .operand_size(opz), .reps(reps), .over_seg(over_seg), .adz(adz), .pg_fault(pg_fault),.ipg_fault(ipg_fault));

acu  i_acu  (.clk(clk), .rstn(rstn), .from_regf(to_acu),.add_src(add_src), .to_regf(from_acu),.from_dec(deco2acu), .db67(adz) , .seg_src(seg_src) );
		     
vliw i_vliw (.clk(clk), .rstn(rstn), .ie(ie), .ready_vliw(ready_vliw), .valid_op(valid_op),
             .instrc(dec2vliw) , .from_acu(from_acu), .to_acu(to_acu), .over_seg(over_seg),
	     .read_reqs(read_req), .read_ack(read_ack), .read_data(read_data),
	     .write_reqs(write_req),.write_ack(write_ack),.write_data(write_data),.Daddr(Daddr),.write_sz(write_sz),	     
	     .add_src(add_src), .imm(imm), .lenpc(lenpc), .seg_src(seg_src), .pg_en(pg_en), .read_sz(read_sz),
	     .terminate(term),.start_up(st), .pc_out(pc_out), .pc_req(pc_req), .opz(opz), .reps(reps), .adz(adz),
	     .readio_data(readio_data), .io_add(io_add), .writeio_data(writeio_data), .writeio_req(writeio_req), .readio_req(readio_req), .writeio_ack(writeio_ack), .readio_ack(readio_ack),
	     .cr0(cr0), .cr1(), .cr2(cr2), .cr3(cr3), .cs(cs), .wr_fault(wr_fault),.pt_fault(pt_fault), .flush_Dtlb(flush_Dtlb),
	     .flush_tlb(flush_Itlb), .pg_fault(pg_fault),.ipg_fault(ipg_fault), .icr2(icr2) );

endmodule
