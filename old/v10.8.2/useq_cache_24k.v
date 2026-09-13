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
wire [127:0] cout,cout1,cout2,cout3,cout4,cout5,cout6,cout7,cout8,cout9,cout10,cout11,cout12;
reg  [31:11] tagA1,tagA2,tagA3,tagA4,tagA5,tagA6,tagA7,tagA8,tagA9,tagA10,tagA11,tagA12;
reg  [127:0] tagD1,tagD2,tagD3,tagD4,tagD5,tagD6,tagD7,tagD8,tagD9,tagD10,tagD11,tagD12;
reg          wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12,hit_ack,hit_ackf;
reg          wen1f,wen2f,wen3f,wen4f,wen5f,wen6f,wen7f,wen8f,wen9f,wen10f,wen11f,wen12f;
reg    [3:0] last1,last2,last3,last4,last5,last6,last7,last8,last9,last10,last11,last12;
reg  [127:0] wdata;
reg    [6:0] waddr;
wire   [6:0] raddr1,raddr2,raddr3,raddr4,raddr5,raddr6,raddr7,raddr8,raddr9,raddr10,raddr11,raddr12;
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
             ( (tagA2 == addr[31:11]) &&  (tagD2[addr[10:4]] == 1) &&  (wen2f==1) ) ? 2 :
             ( (tagA3 == addr[31:11]) &&  (tagD3[addr[10:4]] == 1) &&  (wen3f==1) ) ? 3 :   
	     ( (tagA4 == addr[31:11]) &&  (tagD4[addr[10:4]] == 1) &&  (wen4f==1) ) ? 4 : 
	     ( (tagA5 == addr[31:11]) &&  (tagD5[addr[10:4]] == 1) &&  (wen5f==1) ) ? 5 : 
	     ( (tagA6 == addr[31:11]) &&  (tagD6[addr[10:4]] == 1) &&  (wen6f==1) ) ? 6 : 
	     ( (tagA7 == addr[31:11]) &&  (tagD7[addr[10:4]] == 1) &&  (wen7f==1) ) ? 7 : 
	     ( (tagA8 == addr[31:11]) &&  (tagD8[addr[10:4]] == 1) &&  (wen8f==1) ) ? 8 : 
	     ( (tagA9 == addr[31:11]) &&  (tagD9[addr[10:4]] == 1) &&  (wen9f==1) ) ? 9 : 
	     ( (tagA10== addr[31:11]) && (tagD10[addr[10:4]] == 1) && (wen10f==1) ) ? 10: 
	     ( (tagA11== addr[31:11]) && (tagD11[addr[10:4]] == 1) && (wen11f==1) ) ? 11: 
	     ( (tagA12== addr[31:11]) && (tagD12[addr[10:4]] == 1) && (wen12f==1) ) ? 12: 
	     0;

assign selb= (tagA1 == addr[31:11]) ? 1 :
             (tagA2 == addr[31:11]) ? 2 :
             (tagA3 == addr[31:11]) ? 3 :   
	     (tagA4 == addr[31:11]) ? 4 : 
	     (tagA5 == addr[31:11]) ? 5 : 
	     (tagA6 == addr[31:11]) ? 6 : 
	     (tagA7 == addr[31:11]) ? 7 : 
	     (tagA8 == addr[31:11]) ? 8 : 
	     (tagA9 == addr[31:11]) ? 9 : 
	     (tagA10== addr[31:11]) ? 10: 
	     (tagA11== addr[31:11]) ? 11: 
	     (tagA12== addr[31:11]) ? 12: 0;

assign cout = (selb==1)  ? cout1 :
              (selb==2)  ? cout2 :
              (selb==3)  ? cout3 :
              (selb==4)  ? cout4 :
              (selb==5)  ? cout5 :
              (selb==6)  ? cout6 :
              (selb==7)  ? cout7 :
              (selb==8)  ? cout8 :
              (selb==9)  ? cout9 :
              (selb==10) ? cout10:
              (selb==11) ? cout11:
                           cout12;

assign raddr1 = (wen1 ==0) ? waddr : addr[10:4];
assign raddr2 = (wen2 ==0) ? waddr : addr[10:4];
assign raddr3 = (wen3 ==0) ? waddr : addr[10:4];
assign raddr4 = (wen4 ==0) ? waddr : addr[10:4];
assign raddr5 = (wen5 ==0) ? waddr : addr[10:4];
assign raddr6 = (wen6 ==0) ? waddr : addr[10:4];
assign raddr7 = (wen7 ==0) ? waddr : addr[10:4];
assign raddr8 = (wen8 ==0) ? waddr : addr[10:4];
assign raddr9 = (wen9 ==0) ? waddr : addr[10:4];
assign raddr10= (wen10==0) ? waddr : addr[10:4];
assign raddr11= (wen11==0) ? waddr : addr[10:4];
assign raddr12= (wen12==0) ? waddr : addr[10:4];

// 24kByte instruction cache
cacheram c1 (.clk(clk), .A(raddr1), .D(wdata), .Q(cout1) , .WEN(wen1) );
cacheram c2 (.clk(clk), .A(raddr2), .D(wdata), .Q(cout2) , .WEN(wen2) );
cacheram c3 (.clk(clk), .A(raddr3), .D(wdata), .Q(cout3) , .WEN(wen3) );
cacheram c4 (.clk(clk), .A(raddr4), .D(wdata), .Q(cout4) , .WEN(wen4) );
cacheram c5 (.clk(clk), .A(raddr5), .D(wdata), .Q(cout5) , .WEN(wen5) );
cacheram c6 (.clk(clk), .A(raddr6), .D(wdata), .Q(cout6) , .WEN(wen6) );
cacheram c7 (.clk(clk), .A(raddr7), .D(wdata), .Q(cout7) , .WEN(wen7) );
cacheram c8 (.clk(clk), .A(raddr8), .D(wdata), .Q(cout8) , .WEN(wen8) );
cacheram c9 (.clk(clk), .A(raddr9), .D(wdata), .Q(cout9) , .WEN(wen9) );
cacheram c10(.clk(clk), .A(raddr10),.D(wdata), .Q(cout10), .WEN(wen10));
cacheram c11(.clk(clk), .A(raddr11),.D(wdata), .Q(cout11), .WEN(wen11));
cacheram c12(.clk(clk), .A(raddr12),.D(wdata), .Q(cout12), .WEN(wen12));

always @(posedge clk or negedge rstn)
if (~rstn) 
   begin
    wen1 <=1;wen2 <=1;wen3 <=1;wen4 <=1; wen5 <=1;wen6 <=1;wen7 <=1;wen8 <=1; wen9 <=1;wen10 <=1;wen11 <=1;wen12 <=1; 
    tagA1<=0;tagA2<=0;tagA3<=0;tagA4<=0; tagA5<=0;tagA6<=0;tagA7<=0;tagA8<=0; tagA9<=0;tagA10<=0;tagA11<=0;tagA12<=0; 
    tagD1<=0;tagD2<=0;tagD3<=0;tagD4<=0; tagD5<=0;tagD6<=0;tagD7<=0;tagD8<=0; tagD9<=0;tagD10<=0;tagD11<=0;tagD12<=0; 
    last1<=1;last2<=2;last3<=3;last4<=4; last5<=5;last6<=6;last7<=7;last8<=8; last9<=9;last10<=10;last11<=11;last12<=12;
    waddr <=0; wdata <=0;
   end
else
   begin
    // Sort LRU hit
    if (selb!=0) begin
                  if (last12== selb) begin last11<=last12; last12<=last11; end else
                  if (last11== selb) begin last10<=last11; last11<=last10; end else
                  if (last10== selb) begin last9 <=last10; last10<=last9;  end else
                  if (last9 == selb) begin last8 <=last9;  last9 <=last8;  end else
                  if (last8 == selb) begin last7 <=last8;  last8 <=last7;  end else
                  if (last7 == selb) begin last6 <=last7;  last7 <=last6;  end else
                  if (last6 == selb) begin last5 <=last6;  last6 <=last5;  end else
                  if (last5 == selb) begin last4 <=last5;  last5 <=last4;  end else
                  if (last4 == selb) begin last3 <=last4;  last4 <=last3;  end else
                  if (last3 == selb) begin last2 <=last3;  last3 <=last2;  end else
                  if (last2 == selb) begin last1 <=last2;  last2 <=last1;  end 			  
                  end
    // Write&Update Cache
    {wen1f,wen2f,wen3f,wen4f,wen5f,wen6f,wen7f,wen8f,wen9f,wen10f,wen11f,wen12f}<={wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12};
    if (code_ack ==1)
      begin
       if (tagA1 == addr[31:11]) begin  tagD1[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'h7ff; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA2 == addr[31:11]) begin  tagD2[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hbff; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA3 == addr[31:11]) begin  tagD3[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hdff; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA4 == addr[31:11]) begin  tagD4[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'heff; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA5 == addr[31:11]) begin  tagD5[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hf7f; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA6 == addr[31:11]) begin  tagD6[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hfbf; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA7 == addr[31:11]) begin  tagD7[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hfdf; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA8 == addr[31:11]) begin  tagD8[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hfef; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA9 == addr[31:11]) begin  tagD9[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hff7; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA10== addr[31:11]) begin tagD10[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hffb; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA11== addr[31:11]) begin tagD11[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hffd; waddr<=addr[10:4];wdata<=idata; end else
       if (tagA12== addr[31:11]) begin tagD12[addr[10:4]]<=1; {wen1,wen2,wen3,wen4,wen5,wen6,wen7,wen8,wen9,wen10,wen11,wen12}<= 12'hffe; waddr<=addr[10:4];wdata<=idata; end else
        // Create New Line
        begin
	 wen1<=1;wen2<=1;wen3<=1;wen4<=1;wen5<=1;wen6<=1;wen7<=1;wen8<=1;wen9<=1;wen10<=1;wen11<=1;wen12<=1;
	 if (last12== 1) begin tagD1 <=0; tagA1 <= addr[31:11]; end else
	 if (last12== 2) begin tagD2 <=0; tagA2 <= addr[31:11]; end else
	 if (last12== 3) begin tagD3 <=0; tagA3 <= addr[31:11]; end else
	 if (last12== 4) begin tagD4 <=0; tagA4 <= addr[31:11]; end else
	 if (last12== 5) begin tagD5 <=0; tagA5 <= addr[31:11]; end else
	 if (last12== 6) begin tagD6 <=0; tagA6 <= addr[31:11]; end else
	 if (last12== 7) begin tagD7 <=0; tagA7 <= addr[31:11]; end else
	 if (last12== 8) begin tagD8 <=0; tagA8 <= addr[31:11]; end else
	 if (last12== 9) begin tagD9 <=0; tagA9 <= addr[31:11]; end else
	 if (last12==10) begin tagD10<=0; tagA10<= addr[31:11]; end else
	 if (last12==11) begin tagD11<=0; tagA11<= addr[31:11]; end else
	 if (last12==12) begin tagD12<=0; tagA12<= addr[31:11]; end 
	end       
      end
    else begin wen1<=1;wen2<=1;wen3<=1;wen4<=1;wen5<=1;wen6<=1;wen7<=1;wen8<=1;wen9<=1;wen10<=1;wen11<=1;wen12<=1; end 
   end

endmodule
