/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off PINNOCONNECT */
/* verilator lint_off PINMISSING */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off COMBDLY */
/* verilator lint_off UNDRIVEN */

`define STARTDEC 0
`define SKIPFIX 1
`define PUSHDEC 2
`define POPDEC  3
`define WAITEXE 4
`define TERMDEC 31

module deco(
clk,rstn,useq_ptr,in128,adz,
pc_req,ivect,int_main,iack,ie,pg_fault,ipg_fault,cpl,cr0,
valid_len,
// outputs to execution into vliw & acu
to_vliw,lenpc_out,immediate,to_acu,operand_size,reps,over_seg,valid_op,term,start,ready_vliw
);

input [127:0] in128;
input	      clk,rstn,term;
input	      adz;
input         pc_req;
input	      ie,int_main,pg_fault,ipg_fault;
input	[1:0] cpl;
input	[7:0] ivect;
input  [31:0] cr0;
input   [5:0] valid_len;

output reg        iack;
output     [31:0] lenpc_out;
output     [63:0] immediate;
output      [2:0] operand_size;

output [3:0] useq_ptr;
output [128+1+1+73+8-1:0] to_acu;
output    [127:0] to_vliw;
output            start;
output      [2:0] reps;
output      [5:0] over_seg;
output            valid_op;
input             ready_vliw;

reg  [63:0] imm;
wire [72:0] indic;
wire  [7:0] func,indrm;
reg   [2:0] displc,imm_sz;
reg   [4:0] fsm,pfx_sz,fsmf;
reg         fpu,twobyte,sib_dec,imm_dec,mod_dec;
reg   [3:0] i_ptr;
reg         rep,db67,repz;
wire  [7:0] op;
wire  [7:0] modrm,sib;
reg         overes,overcs,overss,overfs,overgs,overds,it_fault;
wire  [3:0] jsz;
wire        term_rise;
reg         term_f;
wire  [7:0] opcode;
reg   [7:0] fpu_indrm,fpu_modrm;

// interrupt fifo mem
reg    [7:0] ififo_rvect1,ififo_rvect2,ififo_rvect3,ififo_rvect4,ivect_f;
reg    [5:0] int_excl;
wire [127:0] udeco;
reg          trig_itf,trig_it,ief,intf,intff;

// fifo pipe output
reg    [1:0] idx_deco;
reg   [31:0] lenpc,lenpc1,lenpc2;
reg  [127:0] inst_deco,inst_deco1,inst_deco2;
reg  [128+1+1+73+8-1:0] to_acu0,to_acu1,to_acu2;
reg   [63:0] imm0,imm1,imm2;
reg    [2:0] opz0,opz1,opz2,opz;
reg    [2:0] reps0,reps1,reps2;
reg    [5:0] over_seg0,over_seg1,over_seg2;
reg  [127:0] f128;
reg    [7:0] opf;
reg    [7:0] modrmf;

// arguments

deco8   i_deco_1 (.in8(in128[7:0])  , .indic(indic) );
deco_rm i_deco_3 (.in8(in128[15:8]) , .indic(indrm) );
udecox  i_udeco  (.op(op), .modrm(modrm), .twobyte(twobyte), .fpu(fpu), .cpl(cpl), .adz(adz), .opz(opz), .jsz(jsz), .udeco(udeco), .emul(cr0[2]) , .ipg_fault(ipg_fault) );

assign lenpc_out = (term) ? lenpc1 : lenpc;
assign operand_size = (term) ? opz1 : opz0;
assign opcode   = (term) ? to_acu1[90:83] : to_acu0[90:83];
assign immediate= (term) ? imm1 : imm0;
assign to_vliw  = (term) ? inst_deco1 : inst_deco;
assign op       = in128[7:0];
assign modrm    = in128[15:8];
assign to_acu   = (term) ? to_acu1 : to_acu0; //{in128,mod_dec,sib_dec,indic,indrm};
assign reps = (term) ? reps1 : reps0; // {rep&inst_deco[103],repz,&op[2:1]};
assign over_seg = (term) ? over_seg1 : over_seg0;  //{overgs,overfs,overds,overss,overcs,overes};

assign useq_ptr = ((valid_len > i_ptr+imm_sz) &&(i_ptr >0))? i_ptr+imm_sz : 0;

assign start    = ((term == 1) && (term_f == 0) && (pc_req == 0) && (fsm==`WAITEXE)) ? 1'b1 :
                  ((term == 1) && (term_f == 1) && (pc_req == 0) && ( (idx_deco==3) | (idx_deco==2) | (idx_deco==1) | 
		                                                      ((idx_deco==0)&&(fsm==`PUSHDEC)&&(valid_len>(i_ptr+imm_sz)))
								    ) && !((idx_deco==1)&&(fsm==`POPDEC)) ) ? 1'b1 : 1'b0;

assign valid_op = ((idx_deco > 0)  && !((idx_deco==1)&&(fsm==`POPDEC))  && (pc_req == 0) ) ? 1 :
                  ((idx_deco==0)&&(fsm==`PUSHDEC)&&(valid_len>(i_ptr+imm_sz))) ? 1 : 0;

assign jsz = (adz == 1) ? 4'h4 : 4'h2;

// interupt delay/vector manager
always @(posedge clk or negedge rstn)
if (rstn == 0)
   begin
     intf <=0; iack <=0; trig_itf <=0; ief <= 0;  int_excl <=0;
     ififo_rvect1 <= 0 ; ififo_rvect2 <=0; ififo_rvect3 <=0; ififo_rvect4 <= 0;
   end
else
  begin
   intf <= int_main; intff <=intf; ief <= ie; trig_itf <= trig_it; // edge detectors
      
   if (( int_excl !=0 ) &&(start ==1))  int_excl <= int_excl -1; else // exclusion time window for 15 instructions
	 if ((trig_it  ==1) && (trig_itf ==0)) int_excl <= 20;
   	
   if ((trig_it  ==1) && (trig_itf ==0))   // pop interrupt vector
      begin
       ififo_rvect1 <= ififo_rvect2 ; ififo_rvect2 <=ififo_rvect3; 
       ififo_rvect3 <= ififo_rvect4 ; ififo_rvect4 <=0;
       iack <= 0;
      end
   else
   if (  ((int_main  ==1) && (intf ==1) && (intff==0)  && (trig_it == 0)) ) // push interrupt vector
      begin
        iack <= 1;		 
        ififo_rvect1 <= ivect       ; ififo_rvect2 <=ififo_rvect1; 
	    ififo_rvect3 <= ififo_rvect2; ififo_rvect4 <=ififo_rvect3;
      end
    else iack <=0;
  end

// edge detector in terminate instruction
always @(posedge clk or negedge rstn)
if (rstn == 0) term_f<=0; else term_f <= term;
assign term_rise = ((term ==1) && (term_f ==0)) ? 1 : 0;

always @(in128 or mod_dec or sib_dec or displc or imm_sz)
if (imm_sz!=0)		
   case (mod_dec+sib_dec+displc)
     0 : if (imm_sz == 4) imm<={32'b0,in128[39: 8]}; 
    else if (imm_sz == 6) imm<={16'b0,in128[55: 8]};
    else if (imm_sz == 2) imm<={48'b0,in128[23: 8]};
    else                  imm<={56'b0,in128[15: 8]};		    
    
     1 : if (imm_sz == 4) imm<={32'b0,in128[47:16]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[31:16]}; 
    else if (imm_sz == 1) imm<={56'b0,in128[23:16]};
    else if (imm_sz == 5) imm<={24'b0,in128[55:16]};
    else if (imm_sz == 3) imm<={40'b0,in128[39:16]};
    else if (imm_sz == 6) imm<={16'b0,in128[63:16]};
    else                  imm<=in128[79:16]	  ;
    
     2 : if (imm_sz == 4) imm<={32'b0,in128[55:24]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[39:24]};
    else                  imm<={56'b0,in128[31:24]};
    
     3 : if (imm_sz == 4) imm<={32'b0,in128[63:32]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[47:32]}; 
    else                  imm<={56'b0,in128[39:32]};
    
     4 : if (imm_sz == 4) imm<={32'b0,in128[71:40]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[55:40]}; 
    else                  imm<={56'b0,in128[47:40]};
    
     5 : if (imm_sz == 4) imm<={32'b0,in128[79:48]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[63:48]}; 
    else                  imm<={56'b0,in128[55:48]};
    
     6 : if (imm_sz == 4) imm<={32'b0,in128[87:56]}; 
    else if (imm_sz == 2) imm<={48'b0,in128[71:56]}; 
    else                  imm<={56'b0,in128[63:56]};
    
     default : begin imm <=0; end
   endcase      
else imm <= 0;

// task
task popdec ;
  begin
  i_ptr <=0;				
  fsm <= `STARTDEC;
  if (idx_deco ==3 ) idx_deco <=2; else 
  if (idx_deco ==2 ) idx_deco <=1; else 
  if (idx_deco ==1 ) idx_deco <=0; 
  inst_deco  <= inst_deco1; inst_deco1 <= inst_deco2; inst_deco2 <= 0;
  lenpc      <= lenpc1    ; lenpc1     <= lenpc2    ; lenpc2	 <= 0;
  imm0       <= imm1	  ; imm1       <= imm2      ; imm2	 <= 0;
  reps0      <= reps1	  ; reps1      <= reps2     ; reps2	 <= 0;
  to_acu0    <= to_acu1   ; to_acu1    <= to_acu2   ; to_acu2	 <= 0;
  opz0       <= opz1	  ; opz1       <= opz2      ; opz2	 <= 0;
  over_seg0  <= over_seg1 ; over_seg1  <= over_seg2 ; over_seg2  <= 0;
  trig_it <=0;
end
endtask
    
// main fsm
always @(posedge clk or negedge rstn)
if (rstn == 0)
 begin 
    sib_dec <= 0; fsm <= 0; twobyte  <= 0; displc <= 0; rep <=0;
    mod_dec <= 0; opz <= 4; imm_sz <= 0; i_ptr<=0; idx_deco <=0; 
    imm_dec <= 0; fpu <= 0; pfx_sz <= 0; fsmf<=0; it_fault<=0;
    inst_deco <= 128'hffffffffffffffffffffffffffffffff; 
    db67 <= 0; repz <=0;trig_it<=1'b0;
    overfs <= 0; overgs <=0; overes <=0; overcs<=0;overss<=0;overds<=0;
    inst_deco1<=0; inst_deco2 <=0; lenpc1 <= 0; lenpc2 <=0; lenpc <=0;
    imm0 <=0; imm1 <=0; imm2 <=0;
    reps0 <=0; reps1 <=0; reps2<=0;
    to_acu0 <=0; to_acu1 <=0; to_acu2 <=0;
    opz0 <=4; opz1 <=4; opz2 <=4; f128 <= 0; opf <=0; modrmf <=0;
    over_seg0 <=0; over_seg1<=0; over_seg2 <=0;
 end
else
begin
 fsmf <= fsm;
 opf  <= op;
 modrmf <= modrm;
 f128 <= in128;
 if (pg_fault==1)
 begin idx_deco <=0;
 if (cpl==3)  inst_deco <={4'ha,4'h4,4'hf,4'h6,4'h4,4'h9,4'he,4'hc,8'h0,8'he,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};	// int vector idt protected
 	 else inst_deco <={4'hf,4'h9,4'he,4'h4,4'h4,4'hc,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};		// int vector idt protected
 end
 else
 if (pc_req == 1) begin
     		   sib_dec <= 0; fsm <= 0; twobyte  <= 0; displc <= 0; rep <=0;
     		   mod_dec <= 0; opz <= 4; imm_sz <= 0; i_ptr<=0; idx_deco <=0; 
     		   imm_dec <= 0; fpu <= 0; pfx_sz <= 0; fsmf<=0; it_fault<=0;
     		   inst_deco <= 128'hffffffffffffffffffffffffffffffff; 
     		   db67 <= adz; repz <=0;trig_it<=1'b0; 
     		   overfs <= 0; overgs <=0; overes <=0; overcs<=0;overss<=0;overds<=0;
     		   inst_deco1<=0; inst_deco2 <=0; lenpc1 <= 0; lenpc2 <=0;
     		   imm0    <=0; imm1    <=0; imm2    <=0;
                   reps0   <=0; reps1   <=0; reps2   <=0;
                   to_acu0 <=0; to_acu1 <=0; to_acu2 <=0;
		   over_seg0 <=0; over_seg1<=0; over_seg2 <=0;
                   opz0    <=4; opz1    <=4; opz2    <=4;
		   fpu_indrm <=0; fpu_modrm <=0;
                  end
  else
  case (fsm)
   `SKIPFIX   :  begin i_ptr <=0; if (term_rise ==0) fsm <= `STARTDEC; else fsm <= `POPDEC; end

   `STARTDEC  : if (ipg_fault) fsm <= `PUSHDEC; else
	        if (term_rise ==1) fsm <= `POPDEC; else					 
                if (idx_deco  ==3) fsm <= `WAITEXE; else
		if ((valid_len > 2)  && (valid_len>(i_ptr+imm_sz))) begin
                if ((|indic[3:0]) && (fpu ==0) && (twobyte ==0))
		      begin 
		      fsm<= `SKIPFIX; pfx_sz   <= pfx_sz+1;
		      fpu<=0; i_ptr<=1;
		      if (indic[62]) begin opz[1]<=opz[2]; opz[2]<=opz[1]; end
		      if (indic[67]) db67<=adz ^ 1;
		      if (indic[63]) begin rep <=1; repz<= in128[0]; end		      
		      if ((indic[3])&&(in128[4]==0)) begin overes <= 1; end // es override
		      if ((indic[2])&&(in128[4]==0)) begin overcs <= 1; end // cs override
		      if ((indic[3])&&(in128[4]==1)) begin overds <= 1; end // ds override
		      if ((indic[2])&&(in128[4]==1)) begin overss <= 1; end // ss override		      		      
		      if ((indic[1])&&(in128[1:0]=={2'b00})) begin overfs <= 1; end // fs override
		      if ((indic[1])&&(in128[1:0]=={2'b01})) begin overgs <= 1; end // gs override
	             end 
            else if (( indic[61] ) && (fpu ==0) && (twobyte ==0)) begin fsm<=`SKIPFIX; fpu    <= 1; i_ptr<= 1; fpu_indrm <= indrm; fpu_modrm <= in128[23:16]; end
	    else if (( indic[54] ) && (fpu ==0) && (twobyte ==0)) begin fsm<=`SKIPFIX; twobyte<= 1; i_ptr<= 1; end 
	    else
            begin
              if (fpu)
	       begin
		  mod_dec<=0;
		  if (db67)
		   begin
		    if (fpu_indrm[0] == 1) sib_dec <= 1 ;
		    if((fpu_indrm[0]==1'b1)&&(fpu_indrm[7]==1'b1)&&(fpu_modrm[2:0]==3'b101)) begin displc <= 4 ; i_ptr <= 1+1+4; end
		    else if (|fpu_indrm[3:2]) begin displc <= 4 ; i_ptr <= 1+1+4; end else 
		    if ( fpu_indrm[4]  ) begin displc <= 1 ; i_ptr <= 1+1; end
		    else begin displc <= 0 ; i_ptr <= 1; end
		   end
		  else
		   begin
		    if (indrm[4]) begin displc <= 1 ; i_ptr <= 1+1; end
		    if (indrm[3]) begin displc <= 1 ; i_ptr <= 1+2; end
		    if ({modrm[7:6],modrm[2:0]}==5'b00110) begin displc <= 1 ; i_ptr <= 1+2; end
		   end	  	       
	       end
	      else
              if (~twobyte)          // one byte opcode 
	       begin
	        // check if immediate needed and its size
                if((|indic[39:26]) | (indic[71]) |                                     
	                ( indic[40]&indrm[5]))  imm_sz <=  1 ;  // imm8
	        else if (indic[42])             imm_sz <=  2 ;  // imm16
		else if (indic[64]|indic[68])   imm_sz <= opz+2;// jmp|call far
		else if (indic[65]) begin if(indrm[1]) imm_sz <= opz; else imm_sz <= opz; end // mov imm,mem w
		else if (indic[66]) begin if(indrm[1]) imm_sz <= 1; else imm_sz <= 1  ; end// mov imm,mem b
	        else if(( (|indic[50:49])| (|indic[47:43])) |                      //
	                ( indic[51]&indrm[5])) imm_sz <=opz ;  // DB66
	        else if (indic[48])  imm_sz <= jsz;  // DB66
			
		// check modrm + sib  
                if(( indic[4]    ) |            // (opcode & 0xC4) == 0x00
                   ( indic[5] & |indic[7:6]) |  // (opcode & 0xF4) == 0x60 && ((opcode & 0x0A) == 0x02 || (opcode & 0x09) == 0x9) ||
	           ( indic[8]    ) |            // (opcode & 0xF0) == 0x80 ||
	           (&indic[10:9] ) |            // (opcode & 0xF8) == 0xC0 && (opcode & 0x0E) != 0x02 || 
	           ( indic[11]   ) |            // (opcode & 0xFC) == 0xD0 ||
	           ( indic[12]   ) )            // (opcode & 0xF6) == 0xF6)
	         begin   // modrm one byte
		  mod_dec<=1;
		  if (db67)
		   begin
		         if (&indrm[1:0]) begin 
			                    sib_dec <= 1 ;
					   if((indrm[7]==1'b1)&&(in128[18:16]==3'b101)) begin displc <= 4 ; i_ptr <= 1+1+1+4; end else 
					   if (|indrm[3:2]) begin displc <= 4; i_ptr <= 1+1+1+4; end else 
					   if ( indrm[4]  ) begin displc <= 1; i_ptr <= 1+1+1+1; end else 
					                    begin displc <= 0; i_ptr <= 1+1+1;   end
			                  end
					 else begin
					   if (|indrm[3:2]) begin displc <= 4; i_ptr <= 1+1+4; end else
					   if ( indrm[4]  ) begin displc <= 1; i_ptr <= 1+1+1; end else
		                                            begin displc <=0; i_ptr <=1+1; end
					 end
		   end
		  else
		   begin
		    if (indrm[4]) begin displc <= 1; i_ptr <= 1+1+1; end else
		    if (indrm[3]) begin displc <= 2; i_ptr <= 1+1+2; end else
		    if ({modrm[7:6],modrm[2:0]}==5'b00110) begin displc <= 2; i_ptr <= 1+1+2; end
		    else begin displc<=0; i_ptr <=1+1; end
		   end
		 end 
	        else 
		 begin   // no modrm one byte
		  i_ptr <=1; // just opcode
		 end
	       end 
	      else                   //two byte opcode
	       begin
	        // check if immediate needed and its size
	        if ( (indic[8] ) )  imm_sz <=  4 ; // jp rel
		else if (indic[70]|indic[53]) imm_sz <=  1 ; // shld/shrd/BT/BTR/BTS/BTC imm                    
		else if (indic[72]) imm_sz <=  0 ; // LSS                    
		
		// check modrm + sib		       
                if((&indic[15:13] ) |                   //((opcode & 0xF0) == 0x00 && (opcode & 0x0F) >= 0x04 && (opcode & 0x0D) != 0x0D ||
	           ( indic[16]    ) |                   // (opcode & 0xF0) == 0x30 ||
	           ( indic[17]    ) |                   //  opcode == 0x77 ||
	           ( indic[8]     ) |                   // (opcode & 0xF0) == 0x80 ||
	           ( indic[18]&(indic[19]|indic[60]))|  // (opcode & 0xF0) == 0xA0 && (opcode & 0x07) <= 0x02 ||
	           ( indic[20]    ) )                   // (opcode & 0xF8) == 0xC8)
	         begin   // two byte no modrm
		  i_ptr <=1; // just opcode
		 end 
                else
	         begin   // two byte    modrm
		  mod_dec<=1;
		  if (db67)
		   begin
		         if (&indrm[1:0]) begin 
			                   sib_dec <= 1 ;
					   if((indrm[7]==1'b1)&&(in128[18:16]==3'b101)) begin displc <= 4 ; i_ptr <= 1+1+1+4; end else
		                           if (|indrm[3:2]) begin displc <= 4; i_ptr <= 1+1+1+4; end else 
					   if ( indrm[4]  ) begin displc <= 1; i_ptr <= 1+1+1+1; end else
		                                            begin displc <= 0; i_ptr <=   1+1+1; end
			                  end
					 else begin
					   if (|indrm[3:2]) begin displc <= 4; i_ptr <= 1+1+4; end else 
					   if ( indrm[4]  ) begin displc <= 1; i_ptr <= 1+1+1; end else
		                                            begin displc <= 0; i_ptr <=   1+1; end
					 end
		   end
		   else
		   begin
		    if (indrm[4]) begin displc <= 1; i_ptr <= 1+1+1; end else
		    if (indrm[3]) begin displc <= 2; i_ptr <= 1+1+2; end else
		    if ({modrm[7:6],modrm[2:0]}==5'b00110) begin displc <= 2; i_ptr <= 1+1+2; end
		    else begin displc<=0; i_ptr <=1+1; end
		   end		   
		 end 
		end
       if (term_rise ==0) fsm <= `PUSHDEC; else fsm <= `POPDEC;       
      end
     end   
   `PUSHDEC : if (valid_len <= (i_ptr+imm_sz)) 
              begin
	       i_ptr <=0;
	       if (term_rise ==1) fsm <= `POPDEC ; else
	       if (idx_deco == 3) fsm <= `WAITEXE; else
	                          fsm <= `STARTDEC;
	      end
              else
              begin
               if (idx_deco == 0) begin over_seg0 <= {overgs,overfs,overds,overss,overcs,overes}; opz0 <= opz; to_acu0 <= {in128,mod_dec,sib_dec,indic,indrm}; reps0 <= {rep&udeco[103],repz,&op[2:1]}; imm0 <= imm; inst_deco  <= udeco; idx_deco <= 1; lenpc  <= pfx_sz+twobyte+fpu+1+mod_dec+sib_dec+displc+imm_sz; end else
               if (idx_deco == 1) begin over_seg1 <= {overgs,overfs,overds,overss,overcs,overes}; opz1 <= opz; to_acu1 <= {in128,mod_dec,sib_dec,indic,indrm}; reps1 <= {rep&udeco[103],repz,&op[2:1]}; imm1 <= imm; inst_deco1 <= udeco; idx_deco <= 2; lenpc1 <= pfx_sz+twobyte+fpu+1+mod_dec+sib_dec+displc+imm_sz; end 
               if (idx_deco == 2) begin over_seg2 <= {overgs,overfs,overds,overss,overcs,overes}; opz2 <= opz; to_acu2 <= {in128,mod_dec,sib_dec,indic,indrm}; reps2 <= {rep&udeco[103],repz,&op[2:1]}; imm2 <= imm; inst_deco2 <= udeco; idx_deco <= 3; lenpc2 <= pfx_sz+twobyte+fpu+1+mod_dec+sib_dec+displc+imm_sz; end 
	       	                      
	       {i_ptr,pfx_sz,twobyte,fpu,mod_dec,sib_dec,displc,imm_sz,rep,repz,fpu_indrm,fpu_modrm} <=0;
	       {overgs,overfs,overds,overss,overcs,overes} <=0;
	       db67 <=adz; opz <=4;
	       
	       if (term_rise ==1) fsm <= `POPDEC ; else
	       if (idx_deco == 3) fsm <= `WAITEXE; else
	                          fsm <= `STARTDEC;
	      end

   `POPDEC  : popdec;
	     
   `WAITEXE : begin
	       {i_ptr,pfx_sz,twobyte,fpu,mod_dec,sib_dec,displc,imm_sz,rep,repz,fpu_indrm,fpu_modrm} <=0;
	       {overgs,overfs,overds,overss,overcs,overes,trig_it} <=0;
	       db67 <= adz; opz <= 4;

	       if (term_rise ==1)
               begin		  
                 if ((ififo_rvect1 != 0) && (ie == 1) && (int_excl == 0) &&(ipg_fault==0) &&(pg_fault==0))	
                  begin
	           i_ptr <=0;
	           if (idx_deco ==3 ) idx_deco <=2; else 
	           if (idx_deco ==2 ) idx_deco <=1; else 
	           if (idx_deco ==1 ) idx_deco <=0; 
                   fsm <= `WAITEXE; idx_deco <=3;	  
                   if (cpl==3)  inst_deco <={4'ha,4'h4,4'hf,4'h5,4'h4,4'h9,4'he,4'h0,8'h0,ififo_rvect1,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};	 // int vector idt protected
                 	   else inst_deco <={4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,ififo_rvect1,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};		 // int vector idt protected
                   trig_it  <= 1;
                   {i_ptr,pfx_sz,twobyte,fpu,mod_dec,sib_dec,displc,imm_sz,rep,repz,fpu_indrm,fpu_modrm} <=0;
                   {overgs,overfs,overds,overss,overcs,overes} <=0; db67 <=adz; opz <=4; lenpc <=0;
                  end
                 else 
		 popdec;
               end
	      	       
              end
	    
	      	  
  endcase
 end

endmodule
