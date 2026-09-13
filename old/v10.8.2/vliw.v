/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off PINNOCONNECT */
/* verilator lint_off PINMISSING */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */

module vliw (
clk,rstn,instrc, ie,
readio_data,io_add, writeio_data, writeio_req, readio_req, writeio_ack, readio_ack,
read_reqs,read_ack,read_data,over_seg, cr3,cr2,icr2,cr1,cr0,
write_reqs,write_ack,write_data,Daddr,write_sz,read_sz,cs,
add_src, from_acu, to_acu, seg_src, pg_en, ready_vliw, valid_op,
imm, lenpc, pc_out, pc_req, opz, reps, adz, flush_tlb, flush_Dtlb,
terminate,start_up,pg_fault,ipg_fault,wr_fault,pt_fault,repbytecache);

input clk,rstn;
input             read_ack;
input      [31:0] read_data;
input             start_up;
input             write_ack;
input     [127:0] instrc;
input      [31:0] add_src,lenpc;
input      [63:0] imm;
input             pg_fault,ipg_fault,wr_fault,pt_fault;
input       [2:0] seg_src;
input       [2:0] opz;
input       [2:0] reps;
input             adz;
input       [5:0] over_seg;
input       [7:0] from_acu;
input      [31:0] cr2,icr2;
input             valid_op;
output            ready_vliw;

output reg [31:0] cr0,cr1,cr3;
output     [63:0] to_acu;
output     [31:0] pc_out;
output reg        pc_req;
output            ie;
output            read_reqs;
output            pg_en;
output     [31:0] cs;
output            terminate;
output            write_reqs;
output     [31:0] Daddr;
output reg [31:0] write_data;
output reg  [1:0] write_sz;
output reg  [1:0] read_sz;
output reg        flush_tlb,flush_Dtlb;
output reg        writeio_req,readio_req;
output reg        repbytecache;
// IO ports
output reg [31:0] io_add,writeio_data;
input      [31:0] readio_data;
input             readio_ack,writeio_ack;

///////////////////////////
//  internal signals
///////////////////////////
reg [31:0] Daddrs;
reg        write_req,write_reqf,read_req,terms;

wire        [7:0] opcode;
wire       [31:0] eax,ebx,ecx,edx,ebp,esp,edi,esi,epc,eflags,neflags;
wire       [31:0] es,ss,ds,fs,gs;
wire       [15:0] cond,cx;
wire        [3:0] loopcond;
wire        [4:0] idx1,idx2,idx3,idx4,nAF2,nAF3,nAF4,nAF5;

reg               eval_flag,opas,opbs,rep_en1,rep_en2,sema_rw,
                  first_rep,rep_en3,rep_en4,rep_en5,sign_div,had_lgjmp;
reg  	   [31:0] regs [15:0];
wire       [31:0] spe [15:0];
wire       [31:0] spr [15:0];
reg  	    [4:0] vliw_pc;
reg  	    [3:0] calc_sz;
reg         [4:0] fsm,fsmf;
reg  	   [31:0] opa,opb,opc,opd;
reg         [2:0] overr;
wire       [15:0] mul16;
wire       [31:0] mul32;
wire       [63:0] mul64;

wire signed  [7:0] sopa8,sopb8;
wire signed [15:0] smul16,sopa16,sopb16;
wire signed [31:0] smul32,sopa32,sopb32;
wire signed [63:0] smul64;
reg         [63:0] divr,divq;
reg          [3:0] all_cnt;
reg         [31:0] temp_sp,cr2_reg,sav_ecx,sav_edi,sav_esi,temp_ss,sav_epc,sav_esp;
reg nCF ; reg nPF ; reg nAF ; 
reg nSF ; reg nOF ; reg nZF ; 
reg         [31:0] ldtr,gdtr,tr,idtr,desc,errco;
wire        [31:0] add_len_pc32,add_len_pc;
wire        [15:0] add_len_pc16;
wire               pe_en;
reg                tcmp,fecx,tss_esp0,fesp,fepc;
wire         [4:0] jsz;
reg          [1:0] sav_cs;
reg         [63:0] tsc;
reg         [31:0] Daddrgs;
reg          [1:0] pipe_mul;
wire               CFOF_mul8z,CFOF_mul8o;
wire               CFOF_mul16z,CFOF_mul16o;
wire               CFOF_mul32z,CFOF_mul32o;
reg                CFOF_mul;
reg         [2:0]  mask8b;
reg         [7:0]  opcode_f;

wire nCF_shift4box,nCF_shiftbox,nCF_arithbox,nAF_arithbox;
wire [31:0] resa_shiftbox, resb_shiftbox,resa_shift4box, resb_shift4box,resa_arithbox;
wire opas_arithbox,opbs_arithbox,tcmp_arithbox;
wire nCF_arithbox2, nAF_arithbox2, opas_arithbox2, opbs_arithbox2, tcmp_arithbox2;
wire [31:0] resa_arithbox2;

////////////////////////////////
// ASSIGN AND CONNECTIONS
////////////////////////////////

wire signed [63:0] sopa_test;
assign sopa_test = sopa32 *sopb32;

assign CFOF_mul8z = (mul64[63:8]  == 56'h0000_0000_0000_00) ? 1 : 0;
assign CFOF_mul16z= (mul64[63:16] == 48'h0000_0000_0000) ? 1 : 0;
assign CFOF_mul32z= (mul64[63:32] == 32'h0000_0000) ? 1 : 0;

assign CFOF_mul8o = (mul64[63:8]  == 56'hffff_ffff_ffff_ff) ? 1 : 0;
assign CFOF_mul16o= (mul64[63:16] == 48'hffff_ffff_ffff) ? 1 : 0;
assign CFOF_mul32o= (mul64[63:32] == 32'hffff_ffff) ? 1 : 0;

assign terminate = terms;
assign ready_vliw = (fsm == 15) ? 1 : 0;
assign sopa8 = opa[7:0]; assign sopb8 = opb[7:0];
assign sopa16 = opa[15:0]; assign sopb16 = opb[15:0];
assign sopa32 = opa[31:0]; assign sopb32 = opb[31:0];

assign jsz = (opz == 4) ? 5'd31 : 
             (opz == 2) ? 5'd15 :
	                  5'd7;

assign rep_cond = rep_en1 ? ( (opc[7:0] == 0)? 1'b0 : 1'b1) :
                  rep_en2 ? ( (opc[4:0] == 0)? 1'b0 : 1'b1) :
                  rep_en3 ? ( (opc== 0)? 1'b0 : 1'b1) : 
		  rep_en4 ? (((opc[4:0]== jsz)||(opa[0]==1)) ? 1'b0 : 1'b1) :
		  rep_en5 ? (((opc[4:0]== 5'd0)||(opa[31]==1)) ? 1'b0 : 1'b1) :
		            1'b0;

assign CF = eflags[0]; assign PF = eflags[2]; assign AF = eflags[4]; assign ZF = eflags[6]; 
assign SF = eflags[7]; assign TF = eflags[8]; assign IF = eflags[9]; assign DF = eflags[10]; assign OF = eflags[11];
assign ie = IF;

assign add_len_pc16 = regs[14][15:0] + lenpc[15:0];
assign add_len_pc32 = regs[14]       + lenpc;
assign add_len_pc   = (adz== 1) ? add_len_pc32 : {regs[14][31:16],add_len_pc16};

assign opax1 = opa[0] ^opa[1] ^opa[2] ^opa[3] ^opa[4] ^opa[5] ^opa[6] ^opa[7];

assign cond[0] =OF; assign cond[1] =~OF;
assign cond[2] =CF; assign cond[3] =~CF;
assign cond[4] =ZF; assign cond[5] =~ZF;
assign cond[6] =CF|ZF; assign cond[7] =~(CF|ZF);
assign cond[8] =SF; assign cond[9] =~SF;
assign cond[10] =PF; assign cond[11] =~PF;
assign cond[12] = SF^OF ; assign cond[13] = (SF==OF) ? 1:0;
assign cond[14] = ZF|(SF^OF) ; assign cond[15] = (SF==OF) ? ~ZF : 0;

assign nAF2 = opa[3:0]+opb[3:0];
assign nAF3 = opa[3:0]+opb[3:0]+CF;
assign nAF4 = opa[3:0]-opb[3:0];
assign nAF5 = opa[3:0]-opb[3:0]-CF;

assign loopcond[0] = (((adz == 0)&&(cx != 0)          )||((adz == 1)&&(ecx != 0)          )) ? 1'b1 : 1'b0;
assign loopcond[1] = (((adz == 0)&&(cx != 0)&&(nZF==1))||((adz == 1)&&(ecx != 0)&&(nZF==1))) ? 1'b1 : 1'b0;
assign loopcond[2] = (((adz == 0)&&(cx != 0)&&(nZF==0))||((adz == 1)&&(ecx != 0)&&(nZF==0))) ? 1'b1 : 1'b0;
			     
assign neflags = {24'b0,nOF,DF,IF,TF,nSF,nZF,1'b0,nAF,1'b0,nPF,1'b1,nCF};

assign pg_en = cr0[31] & had_lgjmp;
assign pe_en = cr0[0];
assign write_reqs = write_req;
assign read_reqs  = read_req;		    
assign Daddr      = Daddrs;

assign idx1 = instrc[127:124];
assign idx2 = instrc[123:120];
assign idx3 = instrc[119:116];
assign idx4 = instrc[115:112];

assign spe[0] = opz;
assign spe[1] = ~opz+1;
assign spe[2] = 0; // libre
assign spe[3] = 1;
assign spe[4] = 2;
assign spe[5] = 4;
assign spe[6] = imm[31:0];
assign spe[7] = add_src;
assign spe[8] = {{24{imm[7]}},imm[7:0]};
assign spe[9] = {{29{instrc[106]}},instrc[106:104]};
assign spe[10]= {24'b0,imm[7:0]};
assign spe[11] = {29'b0,instrc[106:104]};
assign spe[12] = 32'hffff_ffff;
assign spe[13] = 0; //idx2;
assign spe[14] = {27'b0,jsz};
assign spe[15] = 32'b0;

assign spr[0] = opz;
assign spr[1] = ~opz+1;
assign spr[2] = 0; // libre
assign spr[3] = 1;
assign spr[4] = 2;
assign spr[5] = 4;
assign spr[6] = imm[31:0];
assign spr[7] = 0;
assign spr[8] = {{24{imm[7]}},imm[7:0]};
assign spr[9] = {{29{instrc[106]}},instrc[106:104]};
assign spr[10]= {24'b0,imm[7:0]};
assign spr[11] = {29'b0,instrc[106:104]};
assign spr[12] = 32'hffff_ffff;
assign spr[13] = 0; //idx2;
assign spr[14] = {27'b0,jsz};
assign spr[15] = 32'b0;

assign eax = regs[0];
assign ebx = regs[3];
assign ecx = regs[1];
assign edx = regs[2];
assign esp = regs[4];
assign ebp = regs[5];
assign esi = regs[6];
assign edi = regs[7];
assign  es = regs[8];
assign  cs = regs[9];
assign  ss = regs[10];
assign  ds = regs[11];
assign  fs = regs[12]; // opc select fs is early terminate also
assign  gs = regs[13];
assign epc = regs[14];
assign eflags = regs[15];
assign  cx = ecx[15:0];
assign pc_out = (pe_en ==1'b1) ? epc : {16'b0,epc[15:0]} + {regs[9],4'b0};

assign to_acu[31:0] = (from_acu[3:0]==0)? regs[0] :
                      (from_acu[3:0]==1)? regs[1] :
                      (from_acu[3:0]==2)? regs[2] :
                      (from_acu[3:0]==3)? regs[3] :
                      (from_acu[3:0]==4)? regs[4] :
                      (from_acu[3:0]==5)? regs[5] :
                      (from_acu[3:0]==6)? regs[6] :
                      (from_acu[3:0]==7)? regs[7] :
		                            0 ;
// selector #2
assign to_acu[63:32] = (from_acu[7:4]==0)? regs[0] :
                       (from_acu[7:4]==1)? regs[1] :
                       (from_acu[7:4]==2)? regs[2] :
                       (from_acu[7:4]==3)? regs[3] :
                       (from_acu[7:4]==4)? regs[4] :
                       (from_acu[7:4]==5)? regs[5] :
                       (from_acu[7:4]==6)? regs[6] :
                       (from_acu[7:4]==7)? regs[7] :
		                             0 ;

assign opcode = ( vliw_pc == 0 ) ? instrc[  7:  0] :
                ( vliw_pc == 1 ) ? instrc[ 15:  8] :
                ( vliw_pc == 2 ) ? instrc[ 23: 16] :
                ( vliw_pc == 3 ) ? instrc[ 31: 24] :
                ( vliw_pc == 4 ) ? instrc[ 39: 32] :
                ( vliw_pc == 5 ) ? instrc[ 47: 40] :
                ( vliw_pc == 6 ) ? instrc[ 55: 48] :
                ( vliw_pc == 7 ) ? instrc[ 63: 56] :
                ( vliw_pc == 8 ) ? instrc[ 71: 64] :
                ( vliw_pc == 9 ) ? instrc[ 79: 72] :
                ( vliw_pc ==10 ) ? instrc[ 87: 80] :
                ( vliw_pc ==11 ) ? instrc[ 95: 88] :
                ( vliw_pc ==12 ) ? instrc[103: 96] :
                                   instrc[127:120] ;

///////////////////////////////
// arithmetic sub blocks
///////////////////////////////

synthetic_op synthetic_op ( .clk(clk) , .sel(opcode[2:0]),.opa32(opa[31:0]), .opb32(opb[31:0]) ,.res64(mul64) );

shiftbox shiftbox(
.shiftop(opcode[3:0]),
.calc_sz(calc_sz),
.ci(CF),
.co(nCF_shiftbox),
.co4(nCF_shift4box),
.opa(opa),
.opb(opb),
.resa(resa_shiftbox),
.resb(resb_shiftbox),
.resa4(resa_shift4box),
.resb4(resb_shift4box)
);

arithbox arithbox (
.arithop(opcode[3:0]),
.calc_sz(calc_sz),
.ci(CF),
.co(nCF_arithbox),
.af(nAF_arithbox),
.ai(AF),
.sa(opas_arithbox),
.sb(opbs_arithbox),
.opa(opa),
.opb(opb),
.resa(resa_arithbox),
.cmp(tcmp_arithbox)
);

//////////////////////
// Capture process
//////////////////////

always @(posedge clk or negedge rstn)
if (~rstn) fsmf <= 15; else fsmf <= fsm;

always @(posedge clk or negedge rstn)
if (~rstn)
     begin Daddrgs <= 0; write_reqf <=0; end
else begin 
       if (gs[2] == 1) Daddrgs <= ldtr + {gs[31:3],3'b010}; else Daddrgs <= gdtr + {gs[31:3],3'b010}; 
       write_reqf<= write_req; 
     end

always @(posedge clk or negedge rstn)
if (~rstn)
 begin cr2_reg <=0; errco<= 0; end
else
 if (ipg_fault ==1 ) begin cr2_reg <= icr2; errco <= {27'b0,1'b1,1'b0,cs[1],wr_fault,1'b0}; end 
  else
   if ( pg_fault ==1 ) begin cr2_reg <=  cr2; errco <= {27'b0,1'b0,1'b0,cs[1],wr_fault,pt_fault}; end

//////////////////////
// Execute stage
//////////////////////

//Synopsys infer_multibit 'queue'
//Synopsys infer_multibit 'fault_wptr'
//Synopsys infer_multibit 'wptr'
//Synopsys infer_multibit 'io_add'
//Synopsys infer_multibit 'tsc'

always @(posedge clk or negedge rstn)
if (~rstn)
 begin
      regs[0]  <= 0; regs[1]  <= 0; 
      regs[2]  <= 0; regs[3]  <= 0;  
      regs[4]  <= 0; regs[5]  <= 0;  
      regs[6]  <= 0; regs[7]  <= 0;  
      regs[8]  <= 0; regs[9]  <= 0;
      regs[10] <= 0; regs[11] <= 0;
      regs[12] <= 0; regs[13] <= 0;
      regs[14] <= 32'hffc00; regs[15] <= 0; 
      opa <= 32'h0; opb <=32'h0; fsm <=15; vliw_pc <= 0;  pc_req <= 0; 
      terms <=1; write_req <= 0; read_req <=0; Daddrs <=0;
      nCF <= 0; nPF <= 0; nAF <= 0; write_sz <= 2'b10; read_sz <= 2'b10; sav_ecx <=0; sav_edi<=0; sav_esi<=0;
      nSF <= 0; eval_flag <=0;sema_rw <=0; fepc <=0; fesp <= 0;
      nOF <= 0; nZF <= 0; overr <= 0; calc_sz <=0; sav_cs <=0; tss_esp0 <=0;
      writeio_req <=0; readio_req <=0; io_add <=32'h0; writeio_data <=0;sign_div <=0; CFOF_mul <= 0;
      opas <=0; opbs <=0; rep_en1 <=0; rep_en2 <= 0; rep_en3 <=0; rep_en4 <=0; rep_en5 <=0;
      cr0 <=1; cr1 <=0; cr3 <=32'h0; had_lgjmp <=0; flush_tlb <=0; tsc <= 64'h0; flush_Dtlb <=0;
      gdtr<=0;ldtr <=0; idtr<=0; tr <=0; tcmp <=0; desc <= 0; first_rep  <= 1;
      repbytecache <=0; pipe_mul <=0; mask8b <=0;
      opcode_f <=0;
 end
else
 begin
  tsc <= tsc +1;
  opcode_f <= opcode;
  if (pg_fault ==1)
   begin
    fsm<= 0; 
    vliw_pc <= 0;
    read_req <= 0; write_req <=0;
    if (fecx==1) begin regs[1] <= sav_ecx; regs[6]<=sav_esi; regs[7]<=sav_edi; fecx <= 0; end
    if (fesp==1) begin regs[4] <= sav_esp; end
    if (fepc==1) begin regs[14]<= sav_epc; end
   end
  else if (fsm ==0)
    begin
    if ((reps[2]==1) &&(opcode==8'hff)) vliw_pc <=0; else vliw_pc <= vliw_pc + 1; 
    casex (opcode)
     0 : begin flush_Dtlb <= 0; pipe_mul <= 0; end //nop
     1 : begin // lock regs
          opa<=regs[idx1];
	  if (instrc[107]==0) opb<=regs[idx2]; else opb<=spe[idx2];
	  opc<=regs[idx3];
	  opd<=spe[idx4];
	  calc_sz <=instrc[111:108];
	  overr <=0; pipe_mul <= 0;
	  tcmp  <=0;
	  // wait state for address calculation
	  if (((instrc[107]==1) && (idx2 == 7)) | (idx4 == 7) ) fsm <= 11;
	  
         end
     2 : if (tcmp == 0 ) begin 
          if ( (pe_en==1) && (over_seg[5] ==1'b1) )
	    begin
	     write_data <= opb;
	     fsm <= 25; // update ldtr reg in case of GS segment override & read mem location
             Daddrs <= Daddrgs;
             read_req <= 1;
	     read_sz <= 2'b10;
	     sema_rw <=1;
	     if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];	     
	    end	  
          else
	   begin
            Daddrs <= opd; 
	    write_data <= opb; 
	    write_req <= 1; 
	    fsm <= 3;
	    if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
	   end
	 end
     8'hbb : begin // write opb @ opc adress
              Daddrs <= opc; 
	      write_data <= opb; 
	      write_req <= 1; 
	      fsm <= 3;
	      if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
	      overr <= 1;
	     end
     3 : begin 
          if ( (pe_en==1) && (over_seg[5] ==1'b1) )
	    begin
	     fsm <= 25; // update ldtr reg in case of GS segment override & read mem location
             Daddrs <= Daddrgs;
             read_req <= 1;	
	     read_sz <= 2'b10;	     
	     sema_rw <=0;     
	    end	  
          else
	   begin
         read_req <= 1;
         read_sz <= 2'b10;
         fsm <= 1; 
	    // IF 8 BIT HIGH OR OTHER
	      if (instrc[111:108] == 3'b011) 
	         begin
              mask8b <= {1'b1,opd[1:0]};
              Daddrs <= {opd[31:2],2'b0};
             end
            else
             begin
              mask8b <=0;
              Daddrs <= opd;
             end
	   end
	 end 
     4 : begin // push
          Daddrs <= regs[4]-calc_sz[2:0]; 
	  sav_esp <= esp;fesp <=1;
	  write_data <= opb; 
	  write_req <= 1; 
	  fsm <= 3;
	  if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
	  regs[4]<=regs[4]-calc_sz[2:0];
	  overr <= 3'b011;
	 end
     5 : begin // pop
           read_sz <= 2'b10; 	  
           Daddrs <= regs[4]; 
	   read_req <= 1;
	   fsm <= 1; 
	   regs[4]<=regs[4]+calc_sz[2:0];
	   sav_esp <= esp;fesp <=1;
	   overr <= 3'b011;
	 end	 
     6 : begin     // writeio
          io_add  <= opb;
	  writeio_data <= opa;
	  writeio_req  <= 1;
	  fsm <= 12;
         end	 
     7 : begin     // readio
          io_add  <= opb;
	  opa <= readio_data;
	  readio_req  <= 1;
	  fsm <= 12;
         end
     8 : begin // read long pointer at adress 0:imm*4
	  read_sz <= 2'b10;
          Daddrs <= {22'b0,opd[7:0],2'b0}; 
	  read_req <= 1;
	  fsm <= 1; 
	  overr <= 3'b111;
	 end
     9 : begin // read @opb
	  read_sz <= 2'b10;
          Daddrs <= opb; 
	  read_req <= 1;
	  fsm <= 1; 
	 end
	 
     10 : begin
          case (calc_sz) // ZF &SF & OF & PF calc
           1: begin nSF <= opa[7] ; nPF <=opax1^1; 
	            nOF <= (opas & opbs & ~opa[7]) | (~opas & ~opbs & opa[7]); 
	            if(opa[ 7:0]==0) nZF<=1;  else nZF <= 0; end		    
	   2: begin nSF <= opa[15]; nPF <=opax1^1; 
	            nOF <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	            if(opa[15:0]==0) nZF<=1; else nZF <= 0 ; end		    
	   3: begin nSF <= opa[15]; nPF <=opax1^1; 
	            nOF <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	            if(opa[15:8]==0) nZF<=1; else nZF <= 0; end
	   4: begin nSF <= opa[31]; nPF <=opax1^1; 
	            nOF <= (opas & opbs & ~opa[31]) | (~opas & ~opbs & opa[31]); 
	            if(opa[31:0]==0) nZF<=1; else nZF <= 0; end
          endcase
	  
	  eval_flag <= 1;
	  end

     11 : begin // dec/inc si&di
           if (DF == 0) begin regs[6]<=regs[6] + opd; regs[7] <= regs[7] + opd; end
	           else begin regs[6]<=regs[6] - opd; regs[7] <= regs[7] - opd; end
          end
     12 : begin // dec/inc si
           if (DF == 0) begin regs[6] <= regs[6] + opd; end
	           else begin regs[6] <= regs[6] - opd; end
          end
     13 : begin // dec/inc di
           if (DF == 0) begin regs[7] <= regs[7] + opd; end
	           else begin regs[7] <= regs[7] - opd; end
          end

     14 : begin
          case (calc_sz) // Bit Scan
	   2: if(opa[15:0]==0) nZF<=1; else nZF <= 0;			
	   4: if(opa[31:0]==0) nZF<=1; else nZF <= 0;
          endcase
	  eval_flag <= 1;
	  end
     15 : begin // Recalc default address pointer
 	   opd<=spe[idx4];
	   fsm <=11;
	  end

     // 8 bit read = 8'h1e @ opd
     8'b0001_1110 : begin 
          if ( (pe_en==1) && (over_seg[5] ==1'b1) )
	    begin
	     fsm <= 25; // update ldtr reg in case of GS segment override & read mem location
             Daddrs <= Daddrgs;
             read_req <= 1;	
	     read_sz <= 2'b10;	     
	     sema_rw <=0;     
	    end	  
          else
	   begin
            read_req <= 1;
	    read_sz <= 2'b10;
	    fsm <= 1; 
	    mask8b <= {1'b1,opd[1:0]};
	    Daddrs <= {opd[31:2],2'b0}; 
	   end
	 end 

     // 8 bit read = 8'h1f @ opb
     8'b0001_1111 : begin 
          if ( (pe_en==1) && (over_seg[5] ==1'b1) )
	    begin
	     fsm <= 25; // update ldtr reg in case of GS segment override & read mem location
             Daddrs <= Daddrgs;
             read_req <= 1;	
	     read_sz <= 2'b10;	     
	     sema_rw <=0;     
	    end	  
          else
	   begin
            read_req <= 1;
	    read_sz <= 2'b10;
	    fsm <= 1; 
	    mask8b <= {1'b1,opb[1:0]};
	    Daddrs <= {opb[31:2],2'b0}; 
	   end
	 end 
     	  
     /////////////
     //  arith
     /////////////
    
     8'b0001_0000 ,8'b0001_0001,8'b0001_0010,
     8'b0001_0011,8'b0001_0100,8'b0001_0111,8'b0001_0101,
     8'b0001_0110 : begin  // arithbox
                     opa  <= resa_arithbox;
		     nCF  <= nCF_arithbox;
		     opas <= opas_arithbox;
		     opbs <= opbs_arithbox;
		     nAF  <= nAF_arithbox;
		     tcmp <= tcmp_arithbox;
                    end
                     
     8'b0001_1000 : if (calc_sz==4) {nCF,opa} <= opa + opd; 
               else if (calc_sz==2) {nCF,opa[15:0]} <= opa[15:0] + opd[15:0];
	       else                 {nCF,opa[7:0]} <= opa[7:0] + opd[7:0]; // add calc
     
     8'b0001_1001 : if (calc_sz==4) {nCF,opb} <= opb + {{29{instrc[106]}},instrc[106:104]}; 
                               else {nCF,opb[15:0]} <= opb[15:0] + {{13{instrc[106]}},instrc[106:104]};    // loop
     8'b0001_1010 : if (calc_sz==4) {nCF,opa} <= opa + {{29{instrc[106]}},instrc[106:104]}; 
                               else {nCF,opa[15:0]} <= opa[15:0] + {{13{instrc[106]}},instrc[106:104]};    // loop
     8'b0001_1011 : if (calc_sz==4) {nCF,opa} <= opa - {{29{instrc[106]}},instrc[106:104]}; 
                               else {nCF,opa[15:0]} <= opa[15:0] - {{13{instrc[106]}},instrc[106:104]};    // loop    
			        
     8'b0001_1100 : opd <= opb+{24'b0,opa[7:0]};    // xlat    

     8'b0001_1101 : if (calc_sz==4) {nCF,opd} <= opd + {{29{instrc[106]}},instrc[106:104]}; 
                               else {nCF,opd[15:0]} <= opd[15:0] + {{13{instrc[106]}},instrc[106:104]};    // +2 on opd for lgdt
      
     // MUL DIV
     8'b0101_0000 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin opa[15:0]	        <= mul64[15:0]; CFOF_mul <= CFOF_mul8z;  end  // MUL unsigned byte       
     8'b0101_0001 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin {opc[15:0],opa[15:0]} <= mul64[31:0]; CFOF_mul <= CFOF_mul16z; end  // MUL unsigned word 
     8'b0101_0010 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin {opc[31:0],opa[31:0]} <= mul64;       CFOF_mul <= CFOF_mul32z; end     // MUL unsigned dword 
      
     8'b0101_0100 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin     	     opa[15:0]  <= mul64[15:0]; if (mul64[7]  == 0) CFOF_mul <= CFOF_mul8z;  else CFOF_mul <= CFOF_mul8o;  end  // MUL signed byte	     
     8'b0101_0101 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin {opc[15:0],opa[15:0]} <= mul64[31:0]; if (mul64[15] == 0) CFOF_mul <= CFOF_mul16z; else CFOF_mul <= CFOF_mul16o; end // MUL signed word   
     8'b0101_0110 : if (pipe_mul != 2 ) pipe_mul <=pipe_mul+1; else begin {opc[31:0],opa[31:0]} <= mul64;       if (mul64[31] == 0) CFOF_mul <= CFOF_mul32z; else CFOF_mul <= CFOF_mul32o; end // MUL signed dword	
 
     8'b0101_1000 :    begin opd <= 0; opc <= 0; sign_div <=0;			
                             divr <= {opc,opa};divq <= {32'b0,opb};
			     if (opb!=32'h0) fsm <= 6;
                       end
 
     8'b0101_1001 :    begin opd <= {opc[31]^opb[31],31'b0}; opc <= 0; fsm <= 6; sign_div <=1;		
                             if (opc[31]==1) divr <= ~{opc,opa}+1; else divr <= { opc , opa};
			     if (opb[31]==1) divq <= {32'b0 , ~opb}+1; else divq <= {32'b0, opb};
                       end
		       
     //  bit test
     8'b0101_1010 : begin eval_flag <=1;
                          if ((opa & (1<<opb[4:0])) == 32'h0 ) nCF <=0; else nCF <=1; // Bit test  
	            end  
     8'b0101_1011 : opa <= opa & (~(1<<opb[4:0])); // Bit Reset
     8'b0101_1100 : opa <= opa | (1<<opb[4:0]); // Bit Set
     8'b0101_1101 : opd <= opd + {3'b0,opc[31:5],2'b0}; // off set update
     
     8'b1011_0100 : begin // NEG complement 2's
                          if (calc_sz==4) begin opa[31:0] <= ~opa[31:0] + 1; if (opa[31:0] == 0) nCF <=0; else nCF <= 1; end
                     else if (calc_sz==2) begin opa[15:0] <= ~opa[15:0] + 1; if (opa[15:0] == 0) nCF <=0; else nCF <= 1; end
	             else                 begin opa[ 7:0] <= ~opa[ 7:0] + 1; if (opa[ 7:0] == 0) nCF <=0; else nCF <= 1; end	 
                    end
		            
     ///////////////
     //mov
     ///////////////
     8'b0010_0000 : opa <= opd; //imm
     8'b0010_0001 : opa <= {opa[31:24],opd[7:0]}; // imm8 low
     8'b0010_0010 : opa <= {opa[31:16],opd[7:0],opa[7:0]}; //imm8 high
     8'b0010_0011 : opa <= opb;
     8'b0010_0100 : opa <= {opa[31:16],opb[7:0],opa[7:0]}; // movb low to high
     8'b0010_0101 : opa <= {opa[31:8],opb[15:8]}; // movb high to low
     8'b0010_0110 : opb <= {opb[31:8],opb[15:8]}; // movb high to ramb
     8'b0010_0111 : opb <= {16'h0,opd[31:16]}; // jmp far 16bit ea/imm
     8'b0010_1000 : opa <= {16'h0,opb[31:16]}; // jmp far 16bit ff/modrm
     8'b0010_1001 : opd <= opa; // push
     8'b0010_1010 : opb <= instrc[103:72]; // sti/std/cli/...
     8'b0010_1011 : opb <= opd; // sti/std/cli/...
     8'b0010_1100 : opb <= opa; // loop
     8'b0010_1101 : begin opb <= opc; opc <= opb; end // call
     8'b0010_1110 : opa <= {opa[31:16],opa[7:0],opa[15:8]}; // arith 8b
     8'b0010_1111 : opb <= {{24{opb[7]}},opb[7:0]}; // add immediate 8b into (d)word r/m
     8'b0100_0000 : begin opb <= {opb[31:16],opc[7:0],opb[7:0]}; opc <= {opc[31:24],opb[15:8]}; end // xchg
     8'b0100_0001 : begin opc <= {opc[31:16],opb[7:0],opc[7:0]}; opb <= {opb[31:24],opc[15:8]}; end // xchg
     8'b0100_0010 : opd <= opc; //movs
     
     8'b0100_0011 : begin {opc,opa} <= { 56'b0       ,opa[7:0]}; opb <= { 24'b0       ,opb[7:0]} ; end // div 8 bit unsigned
     8'b0100_0100 : begin {opc,opa} <= {{56{opa[ 7]}},opa[7:0]}; opb <= {{24{opb[ 7]}},opb[7:0]} ; end // div 8 bit   signed

     8'b0100_0101 : if (calc_sz == 2) begin {opc,opa} <= {32'b0,opc[15:0],opa[15:0]}; opb <= {16'b0 ,opb[15:0]} ; end // div 16 bit unsigned
     8'b0100_0110 : if (calc_sz == 2) begin {opc,opa} <= {{32{opc[15]}},opc[15:0],opa[15:0]}; opb <= {{16{opb[15]}},opb[15:0]} ; end // div 16 bit   signed
     8'b0100_0111 : begin opa <= opb; opc <= opb; opb <=opc; end // 13 07 2015

     8'b0100_1000 : if (calc_sz == 2) opc <= {32{opa[15]}}; else opc <= {32{opa[31]}};
     8'b0100_1001 : if (idx2 == 0 ) opa <= cr0; else 
                    if (idx2 == 1 ) opa <= cr1; else
		    if (idx2 == 2 ) opa <= cr2_reg; else
		    if (idx2 == 3 ) opa <= cr3;

     8'b0100_1010 : if (idx2 == 0 ) cr0 <= opa; else 
                    if (idx2 == 1 ) cr1 <= opa; else
		    if (idx2 == 2 ) begin  end  else  // cr2 read only
		    if (idx2 == 3 ) cr3 <= opa;

     8'b0100_1011 : opb[15:0] <= imm[47:32]; // jmp far 32bit           
     8'b0100_1100 : opb <= {{16{opb[15]}},opb[15:0]}; // movsx
     8'b0100_1101 : opb <= {24'h000000,opb[ 7:0]}; // movzx
     8'b0100_1110 : opb <= {16'h0000,opb[15:0]}; // movzx

     8'b0100_1111 : opc <= {opc[7:0],opc[15:8],opc[23:16],opc[31:24]}; // bswap

     8'b0110_0000 : gdtr <= opb; // lgdt
     8'b0110_0001 : ldtr <= opb; // lldt
     8'b0110_0010 : idtr <= opb; // lidt
     8'b0110_0011 : tr   <= {16'b0,opb[15:0]}; // ltrw
     8'b0110_0100 : begin Daddrs <=  idtr+{instrc[95:80],3'b000}; read_req <= 1; regs[15][9] <= 0; fsm <= 16;  read_sz <= 2'b10; end // commit IDT address for vector -- ici trial removed : 
     8'b0110_0101 : begin regs[9]<=opc; regs[14] <= opd; end // jump IDT address for timer/IRQ0
     8'b0110_0110 : begin Daddrs <=  gdtr+{tr[15:3],3'b010}; read_sz <= 2'b10; read_req <= 1; sema_rw <=0; opd<=4;fsm <= 25; temp_sp <=regs[4]; temp_ss<=regs[10]; end // task mmgnt
     8'b0110_0111 : begin Daddrs <=  gdtr+{tr[15:3],3'b010}; read_sz <= 2'b10; read_req <= 1; sema_rw <=0; opd<=8;fsm <= 25; regs[4]  <= opb; end // read&update ESP0/SS0 from TSS
     8'b0110_1000 : begin tss_esp0 <= 1;                                                                   regs[10] <= opb; end // read&update ESP0/SS0 from TSS
     8'b0110_1001 : begin Daddrs <=  idtr+{instrc[95:80],3'b000}; read_req <= 1; fsm <= 16;  read_sz <= 2'b10; end // commit IDT address for vector -- ici trial removed : regs[15][9] <= 0;
                     
     ///////////////
     // Shifts
     ///////////////
     8'b0011_0000 ,8'b0011_0001 ,8'b0011_0010,
     8'b0011_0011,8'b0011_0100,8'b0011_0101,
     8'b0011_0110,8'b0011_0111,8'b0011_1000,
     8'b0011_1001 : begin opa <= resa_shiftbox; opb <= resb_shiftbox; nCF <= nCF_shiftbox; end
 

     ///////////////
     // Flags for multiply
     ///////////////

     8'b0011_1010 : if (CFOF_mul == 1) begin nCF <=0; nOF <=0; eval_flag <=1; end else begin nCF <=1; nOF <=1; eval_flag <=1; end
     	       
     ///////////////
     // Reps & CTRLs
     ///////////////
     8'b1100_0000 : begin rep_en1 <=1; fsm <=13; end
     8'b1100_0001 : begin rep_en2 <=1; fsm <=13; opc[7:5] <=0; end
     8'b1100_0010 : begin rep_en3 <=1; fsm <=13; opc[7:5] <=0; end
     8'b1100_0011 : if (reps[2]) begin 
                                   fsm <=10; 
				   sav_ecx <= ecx; sav_edi <=edi; sav_esi <= esi; 
				   fecx <= 1; 
				   if (calc_sz == 1) repbytecache <=1;
				 end


     ///////////////
     // Advanced
     ///////////////
      
     8'b1100_0100 : begin // push all
                      all_cnt <=0; fsm <=20; calc_sz <=instrc[111:108]; 
		      if (tss_esp0==0) begin temp_sp <= regs[4]; temp_ss <= regs[10]; end 
                    end // pusha
		    
     8'b1100_0101 : begin // pop all
                      all_cnt <=0; fsm <=22; calc_sz <=instrc[111:108]; 
		      sav_cs <= cs[1:0]; temp_sp <= 32'h0  ; temp_ss <= 0;
		    end // popa

     8'b1100_0110 : begin rep_en4 <=1; fsm <=13; opc[7:5]<=0; end // Bit Scan forward
     8'b1100_0111 : begin rep_en5 <=1; fsm <=13; opc[7:5]<=0; end // Bit Scan forward

     8'b1100_1001 : flush_tlb <= 1'b1; // flush tlb
     8'b1100_1000 : begin all_cnt <=0; fsm <=20; calc_sz <=instrc[111:108]; end // pusha , no temp_sp/ss


     8'b1100_1010 : if (nZF==1) opb <=opc; else begin opa <= opb; tcmp <= 0; end // cmpxchg reg		     		    
     8'b1100_1011 : if (nZF==0) begin opa <= opb; tcmp <= 0; end // cmpxchg mem
                     else
		      begin
                       Daddrs <= opd; 
	               write_data <= opc; 
	               write_req <= 1; 
	               fsm <= 3;
	               if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
		      end

     8'b1100_1100 : if (opa==32'h0) begin  // CPUID
                                     regs[0] <=32'h1;
				     regs[3] <=32'h756e6547;
				     regs[2] <=32'h49656e69;
				     regs[1] <=32'h6c65746e;
                                    end
		    else if (opa == 32'h1) begin
				     regs[3] <=32'h0;
				     regs[2] <=32'h0000_8010; // 32'h0000_8130; // bit8 = cmpxchg8b , bit5 = msr , bit4 = tsc , bit15 cmov
				     regs[1] <=32'h0;		    
				     regs[0] <=32'h617; //617
		                    end

     8'b1100_1101 : begin // RDTSC
                     regs[2] <= tsc[63:32];
                     regs[0] <= tsc[31:0];		     
		    end

     8'b1100_1110 : begin mask8b <=0; end
     8'b1100_1111 : had_lgjmp <= cr0[31];

     8'b1011_0000 : begin opd <= opd + 4;  opc <= opb; end                      // CMPXCHG8B - instrc a
     8'b1011_0001 : if ({opb,opc} == {regs[2],regs[0]}) nZF <= 1; else nZF <=0; // CMPXCHG8B - instrc b
     8'b1011_0010 : if (nZF == 0) begin regs[2] <= opb; regs[0] <= opc; end     // CMPXCHG8B - instrc c
                     else
		      begin
                       Daddrs <= opd; 
	               write_data <= regs[1]; 
	               write_req <= 1; 
	               fsm <= 3;
	               if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
		      end
     8'b1011_0011 : if (nZF == 0) begin regs[2] <= opb; regs[0] <= opc; end     // CMPXCHG8B - instrc d
                     else
		      begin
                       Daddrs <= opd - 4; 
	               write_data <= regs[3]; 
	               write_req <= 1; 
	               fsm <= 3;
	               if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
		      end

     8'b1011_0101 : flush_Dtlb <= 1'b1; // flush tlb
     
     ///////////////
     // abort cond
     ///////////////
     8'b1101_xxxx : begin
	             calc_sz <=instrc[111:108];
	             overr <=0; pipe_mul <= 0;
	             tcmp  <=0;  
		     opa <= opb; // Only usefull For CMOV 
		     if (cond[opcode[3:0]] == 0) begin fsm<= 15; terms <= 1; regs[14] <= add_len_pc; end   
                    end
     ///////////////
     // copy back
     ///////////////
     8'b1110_xxxx : if (tcmp == 0 ) begin
                     case(calc_sz)
		       2: begin
		           if (opcode[0]) regs[idx1]<={regs[idx1][31:16],opa[15:0]};
		           if (opcode[1]) regs[idx2]<={regs[idx2][31:16],opb[15:0]};
		           if (opcode[2]) regs[idx3]<={regs[idx3][31:16],opc[15:0]};
		           if (opcode[3]) regs[idx4]<={regs[idx4][31:16],opd[15:0]};
		          end
		       1: begin
		           if (opcode[0]) regs[idx1]<={regs[idx1][31:8],opa[7:0]};
		           if (opcode[1]) regs[idx2]<={regs[idx2][31:8],opb[7:0]};
		           if (opcode[2]) regs[idx3]<={regs[idx3][31:8],opc[7:0]};
		           if (opcode[3]) regs[idx4]<={regs[idx4][31:8],opd[7:0]};
			  end
		       3: begin
		           if (opcode[0]) regs[idx1]<={regs[idx1][31:16],opa[15:8],regs[idx1][7:0]};
		           if (opcode[1]) regs[idx2]<={regs[idx2][31:16],opb[15:8],regs[idx2][7:0]};
		           if (opcode[2]) regs[idx3]<={regs[idx3][31:16],opc[15:8],regs[idx3][7:0]};
		           if (opcode[3]) regs[idx4]<={regs[idx4][31:16],opd[15:8],regs[idx4][7:0]};
			  end
                       default: begin
		           if (opcode[0]) regs[idx1]<=opa;
		           if (opcode[1]) regs[idx2]<=opb;
		           if (opcode[2]) regs[idx3]<=opc;
		           if (opcode[3]) regs[idx4]<=opd;
		          end
		     endcase	  
                    end

     8'b1011_0110 : begin
                     if (tcmp == 0 ) // exit and copy back register opa
                      case(calc_sz)
		       2: regs[idx1]<={regs[idx1][31:16],opa[15:0]};
		       1: regs[idx1]<={regs[idx1][31:8],opa[7:0]};
		       3: regs[idx1]<={regs[idx1][31:16],opa[15:8],regs[idx1][7:0]};
                       default: regs[idx1]<=opa;
		      endcase
                       fsm<= 15; terms <= 1; regs[14] <= add_len_pc;  fecx <= 0; fesp<=0; fepc<=0;  
	               if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end
                    end

     8'b1011_0111 : begin
                     if (tcmp == 0 ) // exit and copy back register opb
                      case(calc_sz)
		       2: regs[idx2]<={regs[idx2][31:16],opb[15:0]};
		       1: regs[idx2]<={regs[idx2][31:8],opb[7:0]};
		       3: regs[idx2]<={regs[idx2][31:16],opb[15:8],regs[idx2][7:0]};
                       default: regs[idx2]<=opb;
		      endcase
                      fsm<= 15; terms <= 1; regs[14] <= add_len_pc;  fecx <= 0; fesp<=0; fepc<=0;  
	              if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end
                    end

     8'b1011_1000 : begin // Jump conditional
		       regs[14]    <= spr[idx4] + add_len_pc;
		       fsm         <= 15;
		       terms       <= 1;
		       pc_req      <= 1;	
		    end

     8'b1011_1001 : begin     
                     if (tcmp == 0 ) // exit and copy back register opa
                      case(calc_sz)
		       1: regs[idx1]<={regs[idx1][31:8],opa[7:0]};
		       2: regs[idx1]<={regs[idx1][31:16],opa[15:0]};
		       3: regs[idx1]<={regs[idx1][31:16],opa[15:8],regs[idx1][7:0]};
                       default: regs[idx1]<=opa;
		      endcase
                      fepc <= 0 ; fsm  <= 15; terms <= 1; regs[14] <= add_len_pc;  
		      fecx <= 0 ; fesp <= 0 ; eval_flag <= 0;
		      regs[15][0] <= nCF; 
		      regs[15][4] <= nAF; 
           	      case (calc_sz) // ZF &SF & OF & PF calc
           	       1: begin regs[15][7] <= opa[7] ; nPF <=opax1^1; 
	   	   	    	regs[15][11] <= (opas & opbs & ~opa[7]) | (~opas & ~opbs & opa[7]); 
	   	   	    	if(opa[ 7:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end			
	   	       2: begin regs[15][7] <= opa[15]; regs[15][2] <=opax1^1; 
	   	   	    	regs[15][11] <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	   	   	    	if(opa[15:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0 ; end			
	   	       3: begin regs[15][7] <= opa[15]; regs[15][2] <=opax1^1; 
	   	   	    	regs[15][11] <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	   	   	    	if(opa[15:8]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end
	   	       4: begin regs[15][7] <= opa[31]; regs[15][2] <=opax1^1; 
	   	   	    	regs[15][11] <= (opas & opbs & ~opa[31]) | (~opas & ~opbs & opa[31]); 
	   	   	    	if(opa[31:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end
                      endcase
		    end

     8'b1011_1010 : begin     
                     fepc <= 0 ; fsm  <= 15; terms <= 1; regs[14] <= add_len_pc;  
		     fecx <= 0 ; fesp <= 0 ; eval_flag <= 0;
		     regs[15][0] <= nCF; 
		     regs[15][4] <= nAF; 
           	     case (calc_sz) // ZF &SF & OF & PF calc
           	      1: begin regs[15][7] <= opa[7] ; nPF <=opax1^1; 
	   	   	       regs[15][11] <= (opas & opbs & ~opa[7]) | (~opas & ~opbs & opa[7]); 
	   	   	       if(opa[ 7:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end		      
	   	      2: begin regs[15][7] <= opa[15]; regs[15][2] <=opax1^1; 
	   	   	       regs[15][11] <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	   	   	       if(opa[15:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0 ; end		      
	   	      3: begin regs[15][7] <= opa[15]; regs[15][2] <=opax1^1; 
	   	   	       regs[15][11] <= (opas & opbs & ~opa[15]) | (~opas & ~opbs & opa[15]); 
	   	   	       if(opa[15:8]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end
	   	      4: begin regs[15][7] <= opa[31]; regs[15][2] <=opax1^1; 
	   	   	       regs[15][11] <= (opas & opbs & ~opa[31]) | (~opas & ~opbs & opa[31]); 
	   	   	       if(opa[31:0]==0) regs[15][6]<=1;  else regs[15][6] <= 0; end
                     endcase
		    end

     8'b1011_1100 : begin
                     if (tcmp == 0 ) // exit and copy back register opb into what was opa
                      case(calc_sz)
		       2: regs[idx1]<={regs[idx1][31:16],opb[15:0]};
		       1: regs[idx1]<={regs[idx1][31:8],opb[7:0]};
		       3: regs[idx1]<={regs[idx1][31:16],opb[15:8],regs[idx1][7:0]};
                       default: regs[idx1]<=opb;
		      endcase
                       fsm<= 15; terms <= 1; regs[14] <= add_len_pc;  fecx <= 0; fesp<=0; fepc<=0;  
	               if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end
                    end
     
     240 : overr <= 1;     
     241 : overr <= 3;     
     242 : overr <= 4;     
     243 : overr <= 5;     
     244 : overr <= 6;
     245 : if (loopcond[0]==0 ) fsm<= 14;
     246 : if (loopcond[1]==0 ) fsm<= 14;
     247 : if (loopcond[2]==0 ) fsm<= 14;
     248 : if (loopcond[0]==1 ) fsm<= 14;
     249 : overr <= 0;
     250 : begin end
     251 : begin regs[14] <= add_len_pc; sav_epc <= epc; fepc <=1; end // terms     
     252 : begin fsm<= 15; terms <= 1; pc_req <= 1; end // terms     
     253 : begin fsm<= 15; terms <= 1; regs[14] <= add_len_pc; pc_req <= 1; end // terms     
     254 : begin 
             fsm<= 15; terms <= 1; pc_req <= 1;     
	     regs[15][8] <= 0; regs[15][9] <= 0; 
	   end // terms with IF & TF =0
     255 : if (reps[2]!=1) 
           begin
              fsm<= 15; terms <= 1; regs[14] <= add_len_pc;  fecx <= 0; fesp<=0; fepc<=0;  
	      if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end
           end // terms     
    endcase
   end
  else if (fsm==1)
   begin
    if (read_ack ==0 ) fsm <=1; else 
         begin 
	   if (mask8b[2] ==0) opb <= read_data; else begin
	                                              mask8b <=0;
	                                              if (mask8b[1:0]==0) opb <= {24'b0,read_data[7:0]}; else
	                                              if (mask8b[1:0]==1) opb <= {24'b0,read_data[15:8]}; else
	                                              if (mask8b[1:0]==2) opb <= {24'b0,read_data[23:16]}; else
	                                              if (mask8b[1:0]==3) opb <= {24'b0,read_data[31:24]};						      
	                                             end
	   fsm <=0; 
	   read_req <= 0; 
	   read_sz <= 2'b10; 
	 end
   end
   else if (fsm==3)
   begin
    if (write_ack ==0 ) fsm <=3; else begin fsm <= 0; write_req <= 0; end
   end 
   else if (fsm==4)
   begin
    opb <= read_data; fsm <=0;
   end 
   else if (fsm==6) // DIV step 1
   begin
    if (divq<={1'b0,divr[63:1]}) begin
                                 divq <= {divq[62:0],1'b0};
			         fsm <= 6;
			         opd[5:0] <= opd[5:0] + 1; 
                                end
		                else fsm <= 7;
   end   
   else if (fsm==7) // DIV step 2
   begin
    if (divr >= divq) begin divr <= divr - divq; fsm<=7; opc<= opc + (1<< opd[5:0]); end
              else begin
	            if (opd[5:0] !=0) begin opd[5:0] <= opd[5:0] -1; divq <= {1'b0,divq[63:1]}; fsm<= 7; end
		                 else begin fsm <= 8; end
	           end
   end
   else if (fsm==8) // REPxy
   begin
    if ((sign_div == 1)&&(opd[31]==1)) begin opa<=~opc+1; opc<=~divr[31:0]+1; end 
                                  else begin opa<= opc  ; opc<= divr[31:0]  ; end
    fsm <= 0;
   end
   else if (fsm==10) // REPxy
   begin
    if ( ((reps==3'b100) && (loopcond[0]            ) ) |    // movs lods stos outs ins REP
         ((reps==3'b110) && (loopcond[0]            ) ) |    // movs lods stos outs ins REP
         ((reps==3'b101) && (loopcond[2] | first_rep) ) |    // scas cmps REPNZ
         ((reps==3'b111) && (loopcond[1] | first_rep) ) )    // scas cmps REPZ
	 begin
	  if (adz == 1) regs[1] <= ecx -1 ; else regs[1][15:0] <= cx -1;
	  vliw_pc <=1; first_rep <= 0;
	  fsm <=0;
	  if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end
	 end
	else
	 begin
          fsm<= 15; terms <= 1; regs[14] <= add_len_pc; fecx <=0; fepc <=1; sav_epc <= epc;
	  if (eval_flag ==1) begin eval_flag <=0; regs[15] <= neflags; end	   
	 end
   end
   else if (fsm==11) // wait state address calculation
   begin
    	  if ((instrc[107]==1) && (idx2 == 7)) opb<=spe[7];
	  if  (idx4 == 7) opd <= spe[7];
	  fsm <=0;
   end    
   else if (fsm==12) // wait state address calculation
   begin
    	 if ( readio_ack == 1) begin fsm<=0; writeio_req <=0; readio_req <=0; opa <= readio_data; end else
    	  if ( writeio_ack == 1) begin fsm<=0; writeio_req <=0; readio_req <=0; end
   end    
   else if (fsm==14) // bypass
   begin
    fsm<= 15; terms <= 1; regs[14] <= add_len_pc;
   end    
   else if (fsm==16) // GDTR/IDTR -> opd step 1
   begin
    if (read_ack ==0 ) fsm <=16; else begin opd[15: 0] <= read_data[15: 0]; opc<= {15'b0,read_data[31:16]}; fsm <= 17; read_req <= 1; Daddrs <= Daddrs +4; read_sz <= 2'b10; end
   end    
   else if (fsm==17) // GDTR/IDTR -> opd step 2
   begin
    if (read_ack ==0 ) fsm <=17; else begin opd[31:16] <= read_data[31:16]; fsm <= 0; read_req <= 0; end
   end    
   else if (fsm==20) // push all
   begin
          Daddrs <= regs[4]-calc_sz[2:0];	  
	  case (all_cnt)
	   0: if (instrc[127:124]==4) write_data <= temp_sp; else if (instrc[127:124]==10) write_data <= temp_ss; else if (instrc[127:124]==13) write_data <= errco; else if (instrc[127:124]==12) write_data <= errco; else write_data <= regs[(instrc[127:124])];       
	   1: if (instrc[123:120]==4) write_data <= temp_sp; else if (instrc[123:120]==10) write_data <= temp_ss; else if (instrc[123:120]==13) write_data <= errco; else if (instrc[123:120]==12) write_data <= errco; else write_data <= regs[(instrc[123:120])];
	   2: if (instrc[119:116]==4) write_data <= temp_sp; else if (instrc[119:116]==10) write_data <= temp_ss; else if (instrc[119:116]==13) write_data <= errco; else if (instrc[119:116]==12) write_data <= errco; else write_data <= regs[(instrc[119:116])];
	   3: if (instrc[107:104]==4) write_data <= temp_sp; else if (instrc[107:104]==10) write_data <= temp_ss; else if (instrc[107:104]==13) write_data <= errco; else if (instrc[107:104]==12) write_data <= errco; else write_data <= regs[(instrc[107:104])];
	   4: if (instrc[103:100]==4) write_data <= temp_sp; else if (instrc[103:100]==10) write_data <= temp_ss; else if (instrc[103:100]==13) write_data <= errco; else if (instrc[103:100]==12) write_data <= errco; else write_data <= regs[(instrc[103:100])];
	   5: if (instrc[ 99: 96]==4) write_data <= temp_sp; else if (instrc[ 99: 96]==10) write_data <= temp_ss; else if (instrc[ 99: 96]==13) write_data <= errco; else if (instrc[ 99: 96]==12) write_data <= errco; else write_data <= regs[(instrc[ 99: 96])];
	   6: if (instrc[ 95: 92]==4) write_data <= temp_sp; else if (instrc[ 95: 92]==10) write_data <= temp_ss; else if (instrc[ 95: 92]==13) write_data <= errco; else if (instrc[ 95: 92]==12) write_data <= errco; else write_data <= regs[(instrc[ 95: 92])];
	   7: if (instrc[ 91: 88]==4) write_data <= temp_sp; else if (instrc[ 91: 88]==10) write_data <= temp_ss; else if (instrc[ 91: 88]==13) write_data <= errco; else if (instrc[ 91: 88]==12) write_data <= errco; else write_data <= regs[(instrc[ 91: 88])];
	   default : write_data <= 32'b0;
	  endcase
	  if (all_cnt < (instrc[115:112])) begin
	                                    if (calc_sz == 3'b011) write_sz <= 0; else write_sz <= calc_sz[2:1];
	                                    regs[4]<=regs[4]-calc_sz[2:0];
	                                    overr <= 3'b011; 
	                                    all_cnt<= all_cnt +1; fsm <= 21; write_req <= 1; 
					   end 
					   else 
					   begin 
					    fsm <=0; 
					    write_req <= 0; 
	                                    overr <= 3'b000; 
					   end
   end    
   else if (fsm==21) // push all
   begin
    if (write_ack ==0 ) fsm <=21; else begin fsm <= 20; write_req <= 0; end
   end    
   else if (fsm==22) // pop all
   begin
          Daddrs <= regs[4]; 	   	  
	   
	  if ( ((all_cnt < (instrc[115:112])  ) && (sav_cs == cs[1:0])) |
	       ((all_cnt < (instrc[115:112])+2) && (sav_cs != cs[1:0])) )
	                                   begin 
	                                    fsm <= 23;
					    read_req <= 1;
					    read_sz <= 2'b10; 
					    regs[4]<=regs[4]+calc_sz[2:0];
					    overr <= 3'b011;
					   end
					  else 
					   begin 
					    if (temp_sp != 32'h0) regs[4]<= temp_sp; 
					    fsm <=0;
					    read_req <= 0;
					   end
   end    
   else if (fsm==23) // pop all
   begin
    if (read_ack ==0 ) fsm <=23; else begin fsm <= 24;  read_req <= 0; end
   end    
   else if (fsm==24) // pop all
   begin
     case (all_cnt)
      0: if (instrc[127:124]==4) temp_sp <= read_data; else regs[(instrc[127:124])] <= read_data;
      1: if (instrc[123:120]==4) temp_sp <= read_data; else regs[(instrc[123:120])] <= read_data;
      2: if (instrc[119:116]==4) temp_sp <= read_data; else regs[(instrc[119:116])] <= read_data;
      3: if (instrc[107:104]==4) temp_sp <= read_data; else regs[(instrc[107:104])] <= read_data;
      4: if (instrc[103:100]==4) temp_sp <= read_data; else regs[(instrc[103:100])] <= read_data;
      5: if (instrc[ 99: 96]==4) temp_sp <= read_data; else regs[(instrc[ 99: 96])] <= read_data;
      6: if (instrc[ 95: 92]==4) temp_sp <= read_data; else regs[(instrc[ 95: 92])] <= read_data;
      7: if (instrc[ 91: 88]==4) temp_sp <= read_data; else regs[(instrc[ 91: 88])] <= read_data;
     endcase   
    fsm <=22;
    all_cnt<= all_cnt +1;   
   end   
   else if (fsm==25) // read gdtr
   begin
    if (read_ack ==0 ) fsm <=25; else begin 
                                       fsm <= 26; read_req <= 1; 
				       read_sz <= 2'b10; 
				       desc[23:0] <= read_data[23:0]; 
				       Daddrs <= Daddrs +2;
				      end
   end    
   else if (fsm==26) // read gdtr
   begin
    if (read_ack ==0 ) fsm <=26; else begin 
                                       fsm <= 27; read_req <= 0; desc[31:24] <= read_data[31:24]; 
				      end
   end    
   else if (fsm==27) // read/write gdtr after normal
   begin
    Daddrs <= opd + desc; 
    if (sema_rw == 0) begin read_req <= 1; read_sz <= 2'b10;  fsm <= 1; end else begin write_req <= 1; fsm <= 3; end
   end   
   else if (fsm==28) // read esp0 in TSS
   begin
    if (read_ack ==0 ) fsm <=28; else begin 
                                       fsm <= 29; read_req <= 1; read_sz <= 2'b10; 
				       temp_sp <= regs[4];
				       regs[4] <= read_data[31:0]; 
				       Daddrs <= Daddrs +4;
				      end
   end        
   else if (fsm==29) // read esp0 in TSS
   begin
    if (read_ack ==0 ) fsm <=29; else begin 
                                       fsm <= 0; read_req <= 0; 
				       temp_ss <= regs[10];
				       regs[10] <= read_data[31:0]; 
				      end
   end           
   else if (fsm==15)
   begin
    pc_req <= 0; write_sz <= 2'b10; overr <= 0; fecx <=0; fepc<=0;fesp <=0;
    flush_tlb <= 0; flush_Dtlb <= 0; first_rep <= 1; tss_esp0 <= 0; tcmp <=0;
    regs[15][1] <= 1; regs[15][3] <= 0; regs[15][5] <= 0; regs[15][15]<= 0; pipe_mul <= 0;
    io_add <= 32'h0;  repbytecache <=0;
    if (start_up) begin fsm <=0; terms <= 0; vliw_pc <= 0; end
   end
  else if (fsm==13) // Micro Rep
   if (rep_cond==0) 
    begin 
     fsm <=0; vliw_pc <= vliw_pc + 1; 
     rep_en1 <=0; rep_en2 <=0; rep_en3 <=0; rep_en4 <=0; rep_en5 <=0;
    end 
   else
    begin   
     if ((opc[4:2]!=0) &&(rep_en2 == 1) )
      begin
        opc[4:0]  <= opc[4:0]-4;
	opa       <= resa_shift4box;
	opb       <= resb_shift4box;
	nCF       <= nCF_shift4box;
      end
    else
      begin
       if (rep_en1==1) opc[7:0]  <= opc[7:0]-1; else
       if (rep_en2==1) opc[4:0]  <= opc[4:0]-1; else
       if (rep_en3==1) opc	 <= opc-1     ; else
       if (rep_en4==1) opc[4:0]  <= opc[4:0]+1; else
       if (rep_en5==1) opc[4:0]  <= opc[4:0]-1;
       opa <= resa_shiftbox;
       opb <= resb_shiftbox;
       nCF <= nCF_shiftbox;
      end              
   end
  else fsm <=0;
 end
 
endmodule
