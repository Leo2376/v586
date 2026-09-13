/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off PINNOCONNECT */
/* verilator lint_off PINMISSING */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTH */

module useq (iaddr,idata,code_req,code_ack,clk,rstn,useq_ptr,squeue,pc_in,pc_req,cs,pg_en,pg_fault,pc_pg_fault,valid_len);
//ports
input         clk , rstn;
output [31:0] iaddr;
input  [31:0] cs;
input [127:0] idata;
input   [3:0] useq_ptr;
output  [127:0] squeue;
input  [31:0] pc_in;
input         pc_req;
input         code_ack;
output reg    code_req;
input         pg_en,pg_fault;
output reg    pc_pg_fault;
output [5:0]  valid_len;
// internal ties
reg    [1:0] wptr;
reg   [31:0] addr;
reg  [255:0] queue;
reg    [1:0] fault_wptr;
reg          fault_wptr_en;
reg    [5:0] addrshft;

// Cache signals
wire [127:0] cout,cout1,cout2;
reg  [31:11] tagA1,tagA2;
reg  [127:0] tagD1,tagD2;
reg          wen1,wen2,hit_ack,hit_ackf;
reg          wen1f,wen2f;
reg    [3:0] last1,last2;
reg  [127:0] wdata;
reg    [6:0] waddr;
wire   [6:0] raddr1,raddr2;
wire   [3:0] selb,sel;
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
  addr<=32'h0ffc00; addrshft<=0; queue <=0; code_req <=0;
  wptr<=0; fault_wptr_en <=0; fault_wptr <=0; pc_pg_fault <=0;
  hit_ack <=0; hit_ackf <=0;
 end
else 
 begin 
  // some regs delay
  hit_ackf <= hit_ack;
  addrf <= addr;
  // Manage prefetch fault
  if((pg_fault == 1)&&(fault_wptr_en==0)&&(pc_pg_fault==0)) begin fault_wptr_en <= 1; fault_wptr <= wptr; code_req <=0; end else 
  if((fault_wptr_en == 1) && (fault_wptr == 0)) begin pc_pg_fault <= 1; fault_wptr_en <= 0; end else 
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
     queue <= {cout, queue[255:128]};
     if ((sel !=0) && (hit_ackf ==0) && (addr == addrf) ) addr <= addr + 16; else 
       begin
        if (wptr !=0) wptr <= wptr -1;
        if (fault_wptr !=0) fault_wptr <= fault_wptr -1;
       end
    end
  else
  // perform queue refill
  if ((wptr < 2) && (code_req==0) && (hit_ack ==0)) 
   begin 
    if (pg_fault) wptr <= wptr +1; else 
      if (sel ==0) code_req <=1; else begin hit_ack <=1; end
    if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
   end
  else 
  if (((code_req ==1) && (code_ack==1)) | ((sel !=0) && (hit_ack==1)))
   begin
    if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
    wptr     <= wptr + 1;
    code_req <= 0;
    hit_ack  <= 0;
    addr <= addr + 16;  
    case (wptr)
     0: if (hit_ack) queue[127:  0] <= cout; else queue[127:  0] <= idata;
     1: if (hit_ack) queue[255:128] <= cout; else queue[255:128] <= idata;
     default: queue <= queue;    
    endcase
   end
  else     
  if (useq_ptr >0) addrshft <= addrshft + useq_ptr;
 end

///////////////////////////////////////// 
// Cache Instruction of Level 0 : L0 I$
// Read cache hit
/////////////////////////////////////////

assign sel = ( (tagA1 == addr[31:11]) &&  (tagD1[addr[10:4]] == 1) &&  (wen1f==1) ) ? 1 :
             ( (tagA2 == addr[31:11]) &&  (tagD2[addr[10:4]] == 1) &&  (wen2f==1) ) ? 2 : 0;

assign selb= (tagA1 == addr[31:11]) ? 1 :
             (tagA2 == addr[31:11]) ? 2 : 0;

assign cout = (selb==1)  ? cout1 : cout2 ;

assign raddr1 = (wen1 ==0) ? waddr : addr[10:4];
assign raddr2 = (wen2 ==0) ? waddr : addr[10:4];

// 4kByte instruction cache
cacheram c1 (.clk(clk), .A(raddr1), .D(wdata), .Q(cout1) , .WEN(wen1) );
cacheram c2 (.clk(clk), .A(raddr2), .D(wdata), .Q(cout2) , .WEN(wen2) );

always @(posedge clk or negedge rstn)
if (~rstn) 
   begin
    wen1 <=1; wen2 <=1; 
    tagA1<=0; tagA2<=0; 
    tagD1<=0; tagD2<=0; 
    last1<=1; last2<=2; 
    waddr<=0; wdata<=0;
   end
else
   begin
    // Sort LRU hit
    if (selb == last2) begin last1 <=last2;  last2 <=last1; end			  
    // Write&Update Cache
    {wen1f,wen2f}<={wen1,wen2};
    if (code_ack ==1)
      begin
       if (tagA1 == addr[31:11]) begin tagD1[addr[10:4]]<=1'b1; {wen1,wen2}<= 2'b01; waddr<=addr[10:4]; wdata<=idata; end else
       if (tagA2 == addr[31:11]) begin tagD2[addr[10:4]]<=1'b1; {wen1,wen2}<= 2'b10; waddr<=addr[10:4]; wdata<=idata; end else
        // Create New Line 
        begin
	 wen1<=1;wen2<=1;
	 if (last2== 1) begin tagD1 <=0; tagA1 <= addr[31:11]; end else
	 if (last2== 2) begin tagD2 <=0; tagA2 <= addr[31:11]; end
	end       
      end
     else begin wen1<=1;wen2<=1; end 
    end

endmodule
