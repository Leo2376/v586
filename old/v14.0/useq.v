
module useq (iaddr,idata,code_req,code_ack,clk,rstn,useq_ptr,squeue,pc_in,pc_req,cs,pg_en,pg_fault,pc_pg_fault,dpg_fault,valid_len,busy_ram,flush_tlb);
//ports
input           clk , rstn;
output   [31:0] iaddr;
input    [31:0] cs;
input   [127:0] idata;
input     [3:0] useq_ptr;
output  [127:0] squeue;
input    [31:0] pc_in;
input           pc_req;
input           code_ack;
output reg      code_req;
input           pg_en,pg_fault;
output reg      pc_pg_fault;
output [5:0]    valid_len;
input           dpg_fault;
input           busy_ram;
input           flush_tlb;

// internal ties
reg    [1:0] wptr;
reg   [31:0] addr;
reg  [255:0] queue;
reg    [1:0] fault_wptr;
reg          fault_wptr_en;
reg    [5:0] addrshft;

// Cache signals
wire [127:0] cout;
wire         hit;
wire   [3:0] tagV;
wire  [17:0] tagA;
reg          purge;
reg    [10:0] purge_cnt;
reg    [31:0] addrf;

assign valid_len =  (wptr == 2) ? 5'd31 - addrshft : 
                   ((wptr == 1) && (addrshft < 16)) ? 5'd16 - addrshft : 0 ;

assign squeue     = (addrshft == 1) ? queue[135:8]:
                    (addrshft == 2) ? queue[143:16]:
                    (addrshft == 3) ? queue[151:24]:
                    (addrshft == 4) ? queue[159:32]:
                    (addrshft == 5) ? queue[167:40]:
                    (addrshft == 6) ? queue[175:48]:
                    (addrshft == 7) ? queue[183:56]:
                    (addrshft == 8) ? queue[191:64]:
                    (addrshft == 9) ? queue[199:72]:
                    (addrshft ==10) ? queue[207:80]:
                    (addrshft ==11) ? queue[215:88]:
                    (addrshft ==12) ? queue[223:96]:
                    (addrshft ==13) ? queue[231:104]:
                    (addrshft ==14) ? queue[239:112]:
                    (addrshft ==15) ? queue[247:120]:
		    queue[127:0];

assign iaddr      = addr;
 
always @(posedge clk or negedge rstn)
if (~rstn)
 begin
  addr<=32'h40d00000; addrshft<=0; queue <=0; code_req <=0; 
  wptr<=0; fault_wptr_en <=0; fault_wptr <=0; pc_pg_fault <=0; addrf <= 0;
 end
else 
 begin 
  addrf <= addr;
  // Manage prefetch fault
  if((pg_fault == 1)&&(fault_wptr_en==0)&&(pc_pg_fault==0)) begin fault_wptr_en <= 1; fault_wptr <= wptr; code_req <=0; end else 
  if((fault_wptr_en == 1) && (fault_wptr == 0)) begin pc_pg_fault <= 1; fault_wptr_en <= 0; if ((code_req == 1) && (code_ack ==1)) code_req <= 0; end else 
  // Manage sync'ed requests
  if ( pc_req == 1 ) 
   begin
    code_req   <= 0;
    addrshft   <= {2'b0,pc_in[3:0]};
    wptr <= 0;
    addr       <= {pc_in[31:4],4'b0000};
    fault_wptr_en <=0;
    fault_wptr <= 0;
    pc_pg_fault <=0;
   end
  else
  if ((addrshft + useq_ptr)> 15)  
    begin
     addrshft <= addrshft + useq_ptr -16;
     queue[127:0] <= queue[255:128];
     //queue <= {cout, queue[255:128]};
     //if ((hit ==1) && (addr == addrf)) addr <= addr + 16; else 
     // begin 
       if (wptr !=0) wptr <= wptr -1;
       if (fault_wptr !=0) fault_wptr <= fault_wptr -1;
       if ((code_req == 1) && (code_ack ==1)) code_req <= 0;
     // end  
    end
  else
  // perform queue refill
  if ((wptr < 2) && (code_req==0)) 
   begin 
    if (pg_fault) wptr <= wptr +1; else
     begin 
       if ((addrf == addr) && (hit ==1))
        begin 
         wptr <= wptr + 1;
         addr <= addr + 16;
         case (wptr)
          0: queue[127:  0] <= cout;
          1: queue[255:128] <= cout;
         endcase
	    end
       else 
       if (hit == 0) 
        begin
         if ((busy_ram == 1'b0) && (addrf == addr)) code_req <=1;
        end
     end 
    if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
   end
  else 
  if ((code_req ==1) && (code_ack==1))
   begin
    if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
    wptr     <= wptr + 1;
    code_req <= 0;
    addr <= addr + 16;
    case (wptr)
     0: queue[127:  0] <= idata;
     1: queue[255:128] <= idata;
    endcase
   end
  else     
  if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
 end

assign hit   = ((tagA == addrf[31:14]) &&  (tagV == 4'b0100) && (purge ==0) ) ? 1 : 0;
wire codeWEN = ((purge == 1'b1) || ((hit == 0) && (code_ack ==1) && (code_req ==1) &&(fault_wptr_en ==0) &&(pg_fault == 0) && (dpg_fault==0) &&(flush_tlb == 0)  )) ? 1'b0 : 1'b1;
wire   [9:0] cacheA = (purge == 1'b1) ? purge_cnt[9:0] : addr[13:4];
wire [149:0] cacheD = (purge == 1'b1) ? 150'b0 : {4'b0100,addr[31:14],idata};

datacache c1 (.clk(clk), .A(cacheA), .D(cacheD), .Q({tagV,tagA,cout}) , .WEN(codeWEN) , .M(16'hffff) );

always @(posedge clk or negedge rstn)
if (~rstn)
begin
 purge <= 1; 
 purge_cnt <=0;
end
else
begin
  if (flush_tlb   == 1) begin purge <= 1; purge_cnt <= 0; end  else
  if (pc_pg_fault == 1) begin purge <= 1; purge_cnt <= 0; end  else
  if (dpg_fault   == 1) begin purge <= 1; purge_cnt <= 0; end  else
  if (purge)
  begin
   purge_cnt <= purge_cnt +1;
   if (purge_cnt[10] == 1'b1) begin purge <=0; purge_cnt <= 0; end
  end
end

endmodule
