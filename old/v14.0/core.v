
module core(
clk,rstn, ivect, int_main, iack,
code_addr,code_data, code_req , code_ack,  code_wreq , code_wack, code_wdata,
readio_data,io_add, writeio_data, writeio_req, readio_req, writeio_ack, readio_ack,
write_req , write_ack , write_data , write_sz, read_sz, write_msk,
read_req  , read_ack  , read_data  , Daddr , busy_ram , ipg_fault , outstanding);

input         clk , rstn, int_main;
output [31:0] writeio_data,code_addr;
input [127:0] code_data;
output        write_req,read_req,writeio_req,code_req,code_wreq,readio_req;
input         write_ack,read_ack,code_ack,code_wack;
output [127:0] write_data,code_wdata;
input  [127:0] read_data;
input  [31:0] Daddr,io_add,readio_data;
output  [1:0] write_sz,read_sz;
output        iack;
input   [7:0] ivect;
input         busy_ram,readio_ack,writeio_ack;
output  [3:0] write_msk;
output        ipg_fault;
output        outstanding;

wire [127:0] queue;
wire   [3:0] useq_ptr;
wire  [31:0] int_Daddr,add_src,lenpc,pc_out,cr0,cr2,cr3,icr2;
wire         pc_req;
wire         int_read_req,int_write_req,int_read_ack,int_write_ack;
wire         pg_en,int_code_req,int_code_ack,flush_Itlb;
wire  [31:0] cs,int_code_addr,iwrite_data;
wire         pg_fault,wr_fault,pt_fault,flush_Dtlb;
wire   [1:0] read_sz_tlb,int_write_sz;
wire   [5:0] valid_len;


wire [31:0] Daddr_realign;
wire [31:0] read_data_realign, write_data_realign;
wire        read_ack_realign, write_ack_realign, read_req_realign, write_req_realign;
wire  [1:0] write_sz_realign;
wire        outstand;
wire        pc_pg_fault;

assign outstanding = outstand | ipg_fault | pg_fault | pc_pg_fault; 

useq i_useq (.clk(clk), .rstn(rstn),
	     .iaddr(int_code_addr),.idata(code_data), .code_req(int_code_req), .code_ack(int_code_ack),
	     .useq_ptr(useq_ptr),.cs(cs), .pg_en(pg_en), .pc_pg_fault(pc_pg_fault),
	     .squeue(queue), .valid_len(valid_len),
	     .pc_in(pc_out), .pc_req(pc_req), .pg_fault(ipg_fault), .dpg_fault(pg_fault), .flush_tlb(flush_Itlb|flush_Dtlb ),
	     .busy_ram(busy_ram)
	     );

cpu i_cpu (
.clk(clk),
.rstn(rstn),
.iack(iack),
.int_cpu(int_main),
.ivect(ivect),
.cr0(cr0),
.cr2(cr2),
.icr2(icr2),
.cr3(cr3),
.cs(cs),
.pg_fault(pg_fault),
.ipg_fault(pc_pg_fault),
.useq_ptr(useq_ptr),
.valid_len(valid_len),
.queue(queue),
.pg_en(pg_en),
.pc_out(pc_out),
.pc_req(pc_req),
.read_req(int_read_req),
.write_req(int_write_req),
.read_ack(int_read_ack),
.write_ack(int_write_ack),
.flush_Itlb(flush_Itlb),
.flush_Dtlb(flush_Dtlb),
.readio_req(readio_req),
.writeio_req(writeio_req),
.readio_ack(readio_ack),
.writeio_ack(writeio_ack),
.write_data(iwrite_data),
.writeio_data(writeio_data),
.read_data(read_data_realign),
.readio_data(readio_data),
.write_sz(int_write_sz),
.read_sz(read_sz_tlb),
.io_add(io_add),
.Daddr(int_Daddr),
.pt_fault(pt_fault),
.wr_fault(wr_fault)
);


Dtlb i_Dtlb (.clk(clk), .rstn(rstn) ,  .cr3(cr3), .cr0(cr0), .pg_en(pg_en),.cs(cs),
      .addr_phys(Daddr_realign), .iDaddr(int_Daddr), .iread_sz(read_sz_tlb) , .oread_sz(read_sz), .iwrite_sz(int_write_sz), .owrite_sz(write_sz),
	  .iread_req(int_read_req), .iread_ack(read_ack_realign), .iwrite_req(int_write_req), .iwrite_ack(write_ack_realign),
	  .oread_req(read_req_realign), .oread_ack(int_read_ack), .owrite_req(write_req_realign), .owrite_ack(int_write_ack),	  
	  .data_miss(read_data_realign), .flush_tlb(flush_Dtlb), .iwrite_data(iwrite_data), .owrite_data(write_data_realign),
	  .pg_fault(pg_fault), .cr2(cr2), .wr_fault(wr_fault) , .pt_fault(pt_fault) , .busy_ram(busy_ram) , .outstanding(outstand) );
		    
Itlb i_Itlb (.clk(clk), .rstn(rstn) ,  .cr3(cr3), .cr0(cr0), .pg_en(pg_en),.cs(cs),
          .addr_phys(code_addr), .iDaddr(int_code_addr), .iread_sz(2'b10), .oread_sz(),
	  .iread_req(int_code_req), .iread_ack(code_ack), .iwrite_req(1'b0), .iwrite_ack(code_wack),
	  .oread_req(code_req), .oread_ack(int_code_ack), .owrite_req(code_wreq), .owrite_ack(),	  
	  .data_miss(code_data[31:0]), .flush_tlb(flush_Itlb), .iwrite_data(32'b0), .owrite_data(code_wdata),
	  .pg_fault(ipg_fault), .cr2(icr2) , .wr_fault() , .pt_fault() , .busy_ram(busy_ram) );


realign i_realign (.clk(clk), .rstn(rstn), .write_msk_out(write_msk),
                   .addr_in(Daddr_realign),.addr_out(Daddr), .write_sz_in(write_sz),
                   .write_req_in(write_req_realign),.write_req_out(write_req),
                   .write_ack_in(write_ack),.write_ack_out(write_ack_realign),
                   .read_req_in(read_req_realign),.read_req_out(read_req),
                   .read_ack_in(read_ack),.read_ack_out(read_ack_realign),
                   .read_data_in(read_data),.read_data_out(read_data_realign),
                   .write_data_in(write_data_realign),.write_data_out(write_data)
                  );
                  
endmodule
