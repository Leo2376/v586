/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off PINNOCONNECT */
/* verilator lint_off PINMISSING */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off COMBDLY */

module udeco ( op , modrm , twobyte, cpl , adz, opz, jsz, udeco, fpu, emul , ipg_fault);

input [7:0] op;
input [7:0] modrm;
input [1:0] cpl;
input [2:0] opz;
input       adz;
input [3:0] jsz;
input       twobyte;
input       fpu;
input       emul;
input       ipg_fault;
output reg [127:0] udeco;

wire  [7:0] src,src8;

assign src = (op[1]==1) ? {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]}} : {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]}};
assign src8= (op[1]==1) ? {{2'b00,modrm[4:3]},{2'b00,modrm[1:0]}} : {{2'b00,modrm[1:0]},{2'b00,modrm[4:3]}};

always @(op or modrm or cpl or adz or opz or jsz or twobyte or src8 or src or fpu or emul or ipg_fault)
    if (ipg_fault)
    begin
     if (cpl==3)  udeco <={4'ha,4'h4,4'hf,4'h6,4'h4,4'h9,4'he,4'hd,8'h0,8'he,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};	// int vector idt protected
 	     else udeco <={4'hf,4'h9,4'he,4'h4,4'h4,4'hd,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};		// int vector idt protected
    end
    else
    if (fpu)
    begin
        if (emul == 0) udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; else
	begin
         if (cpl==3) udeco <={4'ha,4'h4,4'hf,4'h5,4'h4,4'h9,4'he,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};    // fpu emulation device busy
                else udeco <={4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h00,8'h00,8'h00,16'h0,8'hce};    // fpu emulation device busy
	end
    end    
    else
    if (twobyte)
     casex(op) // decode twobyte
      8'b0000_0000 : case(modrm[5:3])
                     3'b000 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b001 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
		     
                     3'b010 : if (modrm[7:6] == 2'b11) udeco<={1'b0,modrm[2:0],1'b0,modrm[2:0],8'h07,8'h42,80'h0,8'hff,8'h61,8'h1};  // LLDT    
		                                  else udeco<={8'h0,8'h07,8'h40,64'h0,8'hff,8'h61,8'h3,8'h1d,8'h1}; // LLDT
		     
                     3'b011 : if (modrm[7:6] == 2'b11) udeco<={1'b0,modrm[5:3],4'h0,8'h07,8'h42,80'h0,8'hff,8'h63,8'h1};  // LTRW   
		                                  else udeco<={8'h0,8'h07,8'h40,72'h0,8'hff,8'h63,8'h3,8'h1}; // LTRW 
						  
                     3'b100 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b101 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b110 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b111 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     endcase
		     
      8'b0000_0001 : case(modrm[5:3])
                     3'b000 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b001 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
		     
                     3'b010 : if (modrm[7:6] == 2'b11) udeco<= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;   // LGDT
		                                  else udeco<={8'h0,8'h07,8'h42,64'h0,8'hff,8'h60,8'h3,8'h1d,8'h1};  // LGDT
						  
                     3'b011 : if (modrm[7:6] == 2'b11) udeco<= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;   // LIDT
		                                  else udeco<={8'h0,8'h07,8'h42,64'h0,8'hff,8'h62,8'h3,8'h1d,8'h1};  // LIDT
						  
                     3'b100 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b101 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b110 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
                     3'b111 : udeco<={8'h0,8'h0,8'h0,80'h0,8'hff,8'hc9,8'h1};  // INVLPG 486 , flush all tlb
                     endcase
		     
      //8'h08,8'h09,8'hb0,8'hc0 : $write("486 %h %h %h\n",op,pc_in,modrm);
      8'h30,8'h32,8'h33 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
      
      8'hc7 :  if (modrm[7:6]==2'b11) udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; // CMPXCHG8B
                                else udeco<={8'h0,8'h07,{1'b0,opz},4'h0,40'h0,8'hff,8'hb3,8'hb2,8'hb1,8'h3,8'hb0,8'h3,8'h1};
      		     
      8'b0100_xxxx : begin
                     if (modrm[7:6]==2'b11) udeco <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,4'b1101,op[3:0],8'h1}; //CMOV
	             else udeco <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'b0,56'h0,8'h00,8'h00,8'hbc,8'd3,4'b1101,op[3:0],8'h1};
		     end
      
      8'b0011_0001 : udeco<={8'h0,8'h0,8'h0,80'h0,8'hff,8'hcd,8'h1}; // RDTSC		     			  
      8'b1100_1xxx : udeco<={8'h0,1'b0,op[2:0],4'h7,8'h40,72'h0,8'hff,8'he4,8'h4f,8'h1}; // bswap
      8'b1010_0010 : udeco<={8'h0,8'h07,8'h42,80'h0,8'hff,8'hcc,8'h1}; // CPU ID 
         
      8'b1011_0001 : if (modrm[7:6] ==2'b11) udeco<={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,56'h0,8'hff,8'he3,8'hca,8'ha,8'h17,8'h1}; // cmpxchg reg 
      	         else udeco<={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'hcb,8'ha,8'h17,8'h3,8'h1}; // cmpxchg word  mem
      
      8'b1100_0001 : if (modrm[7:6] ==2'b11) udeco<={{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'hff,8'he6,8'h2c,8'h2d,8'ha,8'h10,8'h1}; // xadd word 
      	          else udeco<={{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,32'h0,8'hff,8'he4,8'h02,8'h2c,8'h2d,8'ha,8'h10,8'h3,8'h1}; // xadd word  mem
      
      8'b0000_0010 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
      8'b0000_0011 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
      8'b0000_0110 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
      8'b0000_1011 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;
      
      8'b0010_0000 : udeco<={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,72'h0,8'h00,8'hb6,8'h49,8'h1}; // read from cr
      8'b0010_0001 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; // read from dr
      
      8'b0010_0010 : udeco<={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,80'h0,8'hff,8'h4a,8'h1}; // write to cr
      8'b0010_0011 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; // write to dr
      
      8'b1000_xxxx : udeco <={8'hee,8'ha6,{1'b0,opz},4'h0,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals      
      
      8'b1001_xxxx : if (modrm[7:6] ==2'b11) begin // setcc R
                                              if (modrm[2] == 0) udeco <={{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h10,32'h1,16'h0,8'h0,8'hb7,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
		                                            else udeco <={{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h30,32'h1, 8'h0,8'h0,8'hb7,8'h2e,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
			                     end
                                                            else udeco <={             4'h0,             4'h0,8'ha7,8'h10,32'h1,8'h0,8'hff,8'h2,8'h2a,4'b1101,op[3:0],8'h2,8'h2c,8'h16,8'h1}; // setcc Conditionals
				    
      8'b1010_0000 : udeco<={4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push fs 
      8'b1010_0001 : udeco<={4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop fs 
      
      8'b1010_0011 : if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
                else udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,48'h0,8'hff,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};

      8'b1010_0100: if (modrm[7:6]==2'b11) udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x imm )
                                     else udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   

      8'b1010_0101: if (modrm[7:6]==2'b11)  udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x CL )
                                       else udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   

      8'b1010_0110 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      8'b1010_0111 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      8'b1010_1000 : udeco<={4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push gs
      8'b1010_1001 : udeco<={4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop gs
      8'b1010_1010 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 

      8'b1010_1011 : if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
                                       else udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
      
      8'b1010_1100 : if (modrm[7:6]==2'b11)  udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x imm )
                                       else udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	   

      8'b1010_1101 : if (modrm[7:6]==2'b11)  udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x CL )
                                       else udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	   
            
      8'b1010_1110 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      
      8'b1010_1111 : if (opz == 3'h2)
                     begin
                      if (modrm[7:6]==2'b11) // IMUL R RM (word) 
                       udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h1};
	              else //MUL imm -> m word
                       udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
		     end
		     else
		     begin
                      if (modrm[7:6]==2'b11) // IMUL R RM (word) 
                       udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h1};
	              else //MUL imm -> m word
                       udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
		     end
		     
      8'b1011_0000 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      8'b1011_0010 : udeco<={1'b0,modrm[5:3],1'b0,modrm[5:3],8'h27,8'h40,72'h0,8'h0,8'hb7,8'h03,8'h1}; // LSS

      8'b1011_0011 : if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
                else udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
		       
      8'b1011_0100 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      8'b1011_0101 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      
      8'b1011_0110 : if (modrm[7:6]==2'b11)    // movzx 8b
                       begin if (modrm[2] == 0) udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1};
			                   else udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h26,8'h1}; end
                      else udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1e,8'h1};

      8'b1011_0111 : if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4e,8'h1}; // movzx word
                                       else udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4e,8'h3,8'h1};
		      
      8'b1011_1000 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      8'b1011_1001 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      
      8'b1011_1010 : case(modrm[5:3])
                       4: if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
                else udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,32'h0,8'hff,8'hff,8'h2c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
		  
		       5: if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
                else udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
		
		       6: if (modrm[7:6]==2'b11) udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
                else udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
		
		       default: udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
                     endcase
      
      8'b1011_1011 : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
      
      8'b1011_1100 : if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h35,8'hc6,8'h2d,8'h0e,8'h1};             // Bit Scan forward
                                       else udeco<={1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h35,8'hc6,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan forward

      8'b1011_1101 : if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h36,8'hc7,8'h2d,8'h0e,8'h1};             // Bit Scan reverse
                                       else udeco<={1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h36,8'hc7,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan reverse
            
      8'b1011_1110 : if (modrm[7:6]==2'b11) 
                       begin
		         if (modrm[2] == 0) udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h2f,8'h1};
			               else udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h26,8'h1};			 
		       end else udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h3,8'h1};
		      
      8'b1011_1111 : if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4c,8'h1};
                      else udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4c,8'h3,8'h1};
      default      : begin udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; end
     endcase
    else
     casex (op)     
      8'b00xx_x0x0: // add/or/adc/sbb/and/sub/xor/cmp r->r, r->m, m->r -byte
	 if (modrm[7:6]==2'b11)
	  case( {modrm[5],modrm[2],op[1]} )
           3'b000: udeco<={src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};
	   3'b001: udeco<={src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};	   
           3'b010: udeco<={src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
	   3'b011: udeco<={src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};
           3'b100: udeco<={src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};	   
	   3'b101: udeco<={src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
           3'b110: udeco<={src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};
	   3'b111: udeco<={src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};
	  endcase
	 else
	  case( {modrm[5],modrm[2],op[1]} )
           3'b000: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};
	   3'b001: udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   	   
           3'b010: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};	   
	   3'b011: udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   
           3'b100: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};	   
	   3'b101: udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1}; 	   	     
           3'b110: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};
	   3'b111: udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1};
	  endcase

      8'b00xx_x0x1: // add/or/adc/sbb/and/sub/xor/cmp r->r, r->m -word
	  if (modrm[7:6]==2'b11) udeco <= {src,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1}; else
	  if                             (op[1]) udeco <= {src,8'ha7,{1'b0,opz,4'b0},56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'd3,8'h1}; else
	                                         udeco <= {src,8'ha7,{1'b0,opz,4'b0},32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'd3,8'h2d,8'h1};

      8'b00xx_x100: udeco<={8'h06,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};              // add/or/adc/sbb/and/sub/xor/cmp i->al -byte
      8'b00xx_x101: udeco<={8'h06,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};    // add/or/adc/sbb/and/sub/xor/cmp i->eax/ax -word 
                                  
      
      8'b000x_x110: udeco<={4'h4,{2'b10,op[4:3]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push seg
      8'b000x_x111: udeco<={4'h4,{2'b10,op[4:3]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop seg
      8'b0010_0111: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // daa
      8'b0010_1111: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // das
      8'b0011_0111: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // aaa
      8'b0011_1111: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // aas
      8'b0100_0xxx: udeco <={{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // inc word reg
      8'b0100_1xxx: udeco <={{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // dec word reg
      8'b0101_0xxx: udeco <={4'h4,{1'b0,op[2:0]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push reg
      8'b0101_1xxx: udeco <={4'h0,{1'b0,op[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop reg
      8'b0110_0000: udeco <={4'h0,4'h1,4'h2,4'h8,{1'b0,opz},4'h3,4'h4,4'h5,4'h6,4'h7,72'h0,8'hff,8'hc4}; // pusha
      8'b0110_0001: udeco <={4'h7,4'h6,4'h5,4'h8,{1'b0,opz},4'h4,4'h3,4'h2,4'h1,4'h0,72'h0,8'hff,8'hc5}; // popa
      8'b0110_0010: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // BOUND
      8'b0110_0011: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // ARPL
      8'b0110_1000: udeco <={8'h06,8'h06,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm      
      8'b0110_1010: udeco <={8'h08,8'h08,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm
  
      8'b0110_1011: if (opz==2) 
                            begin
			     if (modrm[7:6]==2'b11)
			      udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm8 *rm
			     else
			      udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm8 *rm
			    end
                           else 
			    begin
			     if (modrm[7:6]==2'b11)
			      udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm8 *rm
			     else
			      udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm8 *rm
			    end
      
      8'b0110_1001: if (opz==2) 
                            begin
			     if (modrm[7:6]==2'b11)
			      udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm *rm
			     else
			      udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm *rm
			    end
                           else 
			    begin
			     if (modrm[7:6]==2'b11)
			      udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm *rm
			     else
			      udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm *rm
			    end
			    
      8'b0111_xxxx: udeco <={4'he,4'h8,8'ha8,{1'b0,opz},4'h8,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals

      8'b1000_00x0: // add/or/adc/sbb/and/sub/xor/cmp imm - 8bit r/m <=r+i;
         case ({modrm[7:6],modrm[2]})
	  3'b110 : udeco <={2'b0,modrm[1:0],4'h6,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
	  3'b111 : udeco <={2'b0,modrm[1:0],4'b0,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,modrm[5:3],8'h2b,8'h2e,8'h1};	  	  
	  default: udeco <={8'h06,8'ha7,8'h18,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};
	 endcase
	
      8'b1000_0001: // add/or/adc/sbb/and/sub/xor/cmp imm16/32 - Word
        if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[2:0],4'h6,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1}; else
	                       udeco<={8'h06,8'ha7,{1'b0,opz},4'h8,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};

      8'b1000_0011: // add/or/adc/sbb/and/sub/xor/cmp imm8 - sign extend
        if (modrm[7:6]==2'b11) udeco<={1'b0,modrm[2:0],4'h8,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
	           else udeco<={8'h06,8'ha7,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h2f,8'h47,8'h3,8'h2d,8'h1};
      8'b1000_0100: // test r->r, r->m -byte
	 if (modrm[7:6]==2'b11)
	  case( {modrm[5],modrm[2]} )
           2'b00: udeco<={src8,8'ha6,8'h10,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
           2'b01: udeco<={src8,8'ha6,8'h30,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	   
           2'b10: udeco<={src8,8'ha6,8'h10,64'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h26,8'h1};	   
           2'b11: udeco<={src8,8'ha6,8'h30,48'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h26,8'h1};
	  endcase
	 else
	  case( modrm[5] )
           1'b0: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,48'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h1};	   
           1'b1: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h26,8'h47,8'h1e,8'h1};
	  endcase

      8'b1000_0101: // test r->r, r->m -word
	 if (modrm[7:6]==2'b11) udeco<={src,8'ha6,{1'b0,opz},4'h0,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
	 else udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h0,8'h47,8'h3,8'h1};	   
       
      8'b1000_0110:  // xchg 8bit
	 if (modrm[7:6]==2'b11)
	  case( {modrm[5],modrm[2]} )
           2'b00: udeco<={4'h0,src8,4'h7,8'h10,72'h0,8'hff,8'he6,8'h2d,8'h1};
           2'b01: if (modrm[1:0]!=modrm[4:3]) udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; 
	                                 else udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1}; 
           2'b10: if (modrm[1:0]!=modrm[4:3]) udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; 
	                                 else udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};
           2'b11: udeco<={4'h0,src8,4'h7,8'h30,72'h0,8'hff,8'he6,8'h2d,8'h1};
	  endcase
	 else
	  case( modrm[5] )
           1'b0: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,64'h0,8'hff,8'he4,8'h2d,8'h1e,8'h1};	   
           1'b1: udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h30,56'h0,8'hff,8'he4,8'h2,8'h41,8'h1e,8'h1};
	  endcase
      
      8'b1000_0111: if (modrm[7:6]==2'b11)
           udeco <={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg word
      else udeco <={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},56'h0,8'hff,8'he4,8'h2,8'h2d,8'h3,8'h1}; // xchg word
            
      8'b1000_10x1: // mov: r->r, r->m, m->r - word
	  if (modrm[7:6]==2'b11) udeco <= {src,8'ha6,{1'b0,opz},4'h0,80'h0,8'h00,8'hbc,8'h1}; 
	   else
	    if (op[1]) udeco<={src[3:0],src[7:4],8'ha7,{1'b0,opz,4'b0},64'h0,16'h00,8'hb7,8'd3,8'h1};
	          else udeco<={src,8'ha7,{1'b0,opz,4'b0},80'h0,8'hff,8'd2,8'h1};

      8'b1000_10x0: // mov: r->r, r->m, m->r - byte
	 if (modrm[7:6]==2'b11)
	  case( {modrm[5],modrm[2],op[1]} )
           3'b000: udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};
	   3'b001: udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};	   
           3'b010: udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
	   3'b011: udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};
           3'b100: udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};	   
	   3'b101: udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
           3'b110: udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
	   3'b111: udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
	  endcase
	 else
	  case( {modrm[5],modrm[2],op[1]} )
           3'b000: udeco<={src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};
	   3'b001: udeco<={src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};	   
           3'b010: udeco<={src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};	   // doute
	   3'b011: udeco<={src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};
           3'b100: udeco<={src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};	   
	   3'b101: udeco<={src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};   
           3'b110: udeco<={src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};
	   3'b111: udeco<={src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};
	  endcase	  	     	  

      8'b1000_1100: // mov: s->m, s->r
	  if (modrm[7:6]==2'b11) udeco <={{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,72'h0,8'h00,8'h00,8'hbc,8'h1};
	                    else udeco <={{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,80'h0,8'hff,8'h2,8'h1};

      8'b1000_1101: if (modrm[7:6]==2'b11) udeco <={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2c,8'h1}; // lea
	                              else udeco <={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2b,8'h1};

      8'b1000_1110: // mov: m->s, r->s
        begin 
          //$write ("mov: m->s, r->s ");
	  udeco[127:16] <= {{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011};
	  if (modrm[7:6]==2'b11) udeco[15:0] <= {8'h0,8'h1}; else udeco[15:0] <= {8'h03,8'h1};
        end

      8'b1000_1111: if (modrm[7:6]==2'b11) udeco <= {4'h0,{1'b0,modrm[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};//  pop reg non-standard)   
                                      else udeco <= {4'h0,{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,56'h0,8'hff,8'h2,8'hf,8'hf9,8'h5,8'h1};//  pop mem        
      8'b1001_0xxx: udeco <= {4'ha,{1'b0,op[2:0]},4'h0,{5'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // nop, xchg acum      
      8'b1001_1000: udeco <= {8'h00,8'h27,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2f,8'h1}; // cbw
      8'b1001_1001: udeco <= {8'h09,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'he5,8'h48,8'h1}; // cwd			     
      8'b1001_1010: udeco <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'he3,8'h20,8'h27,8'h4,8'h2c,8'h4,8'h1,8'hfb,16'h0,8'hce}; // call different seg
      8'b1001_1011: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101;// wait
      8'b1001_1100: udeco <= {8'h4f,8'ha1,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'h2,8'hf1,8'h29,8'h18,8'h1};// pushf
      8'b1001_1101: udeco <= {8'h4f,8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'd5,8'h1};// popf
      8'b1001_1110: udeco <= {8'hf0,8'ha1,8'h10,72'h0,8'h00,8'hb6,8'h25,8'h1}; // sahf
      8'b1001_1111: udeco <= {8'h0f,8'ha1,8'h30,72'h0,8'h00,8'hb6,8'h24,8'h1}; // lahf
      8'b1010_0000: udeco <= {8'h00,8'ha6,8'h10,72'h0,8'h00,8'hb7,8'h1e,8'h1}; // mov: m->a - 8bit
      8'b1010_0001: udeco <= {8'h01,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h03,8'h1}; // mov: m->a -word
      8'b1010_0010: udeco <= {8'h10,8'ha6,8'h10,80'h0,8'hff,8'h02,8'h1}; // mov: a->m - 8bit
      8'b1010_0011: udeco <= {8'h10,8'ha6,{1'b0,opz},4'h0,80'h0,8'hff,8'h02,8'h1};// mov: a->m -word      
      8'b1010_0100: if (adz == 0 ) udeco <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'hf2,8'h1,8'hc3}; // movs byte
                              else udeco <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'h1,8'hc3}; // movs byte, faster without when cr0[0]==1
			      
      8'b1010_0101: if (adz == 0 ) udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'hf2,8'h1,8'hc3}; // movs word/dword   
                              else udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'h1,8'hc3}; // movs word/dword, faster without when cr0[0]==1
        
      8'b1010_0110: if (adz == 0 ) udeco <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'h1f,8'hf2,8'h1,8'hc3}; // cmps byte
                              else udeco <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'h1f,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1
            
      8'b1010_0111: if (adz == 0 ) udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'd9,8'hf2,8'h1,8'hc3}; // cmps word
                              else udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'd9,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1     
      
      8'b1010_1000: udeco <= {8'h06,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> al
      8'b1010_1001: udeco <= {8'h06,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> ax/eax       	       
      
      8'b1010_1010: udeco <= {8'h00,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos byte
      8'b1010_1011: udeco <= {8'h00,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos word/dword
      
      8'b1010_1100: if (adz == 0 ) udeco <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'hf2,8'h1,8'hc3}; // lods byte
                              else udeco <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'h1,8'hc3}; // lods byte, faster without when cr0[0]==1  
			      
      8'b1010_1101: if (adz == 0 ) udeco <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'hf2,8'h1,8'hc3}; // lods word/dword
                              else udeco <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'h1,8'hc3}; // lods word/dword
      
      8'b1010_1110: if (adz == 0 ) udeco <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'hf0,8'h1,8'hc3}; // scas byte      
                              else udeco <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'h1,8'hc3}; // scas byte 
			      
      8'b1010_1111: if (adz == 0 ) udeco <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'hf0,8'h1,8'hc3}; // scas word/dword
                              else udeco <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'h1,8'hc3}; // scas word/dword
			      
      8'b1011_00xx: udeco <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0001,8'h1}; // mov: i->r - byte low
      8'b1011_01xx: udeco <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0010,8'h1}; // mov: i->r - byte high
      8'b1011_1xxx: udeco <= {{1'b0,op[2:0]},4'h9,8'hc6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,8'b0010_0000,8'h1}; // mov: i->r - word

      8'b1100_0000: if (modrm[7:6]==2'b11) begin // ror/rol/shl/sar/sal/shr  ( x imm )
                       if (modrm[2]==1'b0) udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // 8 bit reg low
		                      else udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h38,32'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h2d,8'h1}; // 8 bit reg high
                                  end else udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h2d,8'h1}; // 8 bit mem		
				  
      8'b1100_0001: if (modrm[7:6]==2'b11) udeco <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // word reg
		                      else udeco <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h2d,8'h1}; // word mem		  
				      
      8'b1100_0010: udeco <= {8'h4e,8'ha6,{1'b0,opz},{1'b0,opz},32'h0,8'hfc,8'he1,8'h18,8'h1,8'he2,8'h5,8'h1,8'h0,8'hce}; // ret near with value
      8'b1100_0011: udeco <= {8'h0e,8'ha6,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h5,8'hce,8'h1}; // ret near      
      8'b1100_0100: udeco <= {4'h8,{1'b0,modrm[5:3]},8'h87,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // les      
      8'b1100_0101: udeco <= {4'hb,{1'b0,modrm[5:3]},8'hb7,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // lds      
      8'b1100_0110: // mov: i->m (or i->r non-standard)
        begin 
         //$write("mov: i->m (or i->r non-standard) ");
	 if (modrm[7:6]==2'b11) 
	                   begin
			    if (modrm[5]==1'b1) // high byte
			     udeco <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,64'h0,8'h00,8'h00,8'hbc,8'b0010_0110,8'h1};
			    else // low byte
			     udeco <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
			   end
	                   else udeco <= {1'b0,modrm[5:3],4'h6,8'ha7,4'h1,4'h8,80'h0,8'hff,8'h2,8'h1};
        end

      8'b1100_0111: // mov: i->m (or i->r non-standard)
        begin 
         //$write("mov: i->m (or i->r non-standard) ");
	 if (modrm[7:6]==2'b11) udeco <= {1'b0,modrm[2:0],4'h6,8'ha7,{1'b0,opz},4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
	                   else udeco <= {1'b0,modrm[5:3],4'h6,8'ha7,{1'b0,opz},4'h8,80'h0,8'hff,8'h2,8'h1};
        end
	
      8'b1100_1000: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // enter
      
      8'b1100_1001: udeco <= {8'h45,8'h67,{1'b0,opz},4'h0,56'h0,8'h0,8'hb7,8'h5,8'he1,8'h23,8'h1}; // leave
      
      8'b1100_1010: udeco <= {8'h49,8'he6,{1'b0,opz},{1'b0,opz},16'h0,8'hfc,8'he1,8'h18,8'h1,8'he6,8'd5,8'h2d,8'd5,8'h1,8'h0,8'hce}; // ret far with value
      8'b1100_1011: udeco <= {8'he9,8'he6,{1'b0,opz},{1'b0,opz},40'h0,8'hfc,8'he3,8'd5,8'h23,8'd5,8'h1,8'h0,8'hce}; // ret far
      8'b1100_1100: udeco <= {8'h9e,8'hfb,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int 3
      
      8'b1100_1101: if (adz ==0) udeco <= {8'h9e,8'hf6,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int      
		    else
		     begin
		      if (cpl==3) udeco <={4'ha,4'h4,4'hf,4'h5,{1'b0,opz},4'h9,4'he,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'h68,8'h67,8'h66,8'hfb,8'h0,8'hce}; // int idt protected
		             else udeco <={4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected		       
		     end
      
      8'b1100_1110: udeco <= {8'h9e,8'hfb,{1'b0,opz},4'h4,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb,8'hd0}; // into           
      8'b1100_1111: udeco <= {4'he,4'h9,4'hf,4'h3,{1'b0,opz},4'h4,4'ha,4'h0,32'h0,8'hfc,8'hc9,8'hc5,16'h0,8'hb5,8'hc9,8'hce}; // iret
      
      8'b1101_0000: if (modrm[7:6]==2'b11) begin // ror/rol/shl/sar/sal/shr  ( x1 )
                       if (modrm[2]==1'b0) udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1}; // 8 bit reg low
		                      else udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'h2e,8'h1}; // 8 bit reg high
                                  end else udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h1e,8'h1}; // 8 bit mem
				  
      8'b1101_0001: if (modrm[7:6]==2'b11) udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1};  // word reg
		                      else udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h3,8'h1}; // word mem

      8'b1101_0010: if (modrm[7:6]==2'b11) begin // ror/rol/shl/sar/sal/shr  ( xCL )
                       if (modrm[2]==1'b0) udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // 8 bit reg low
		                      else udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h1}; // 8 bit reg high
                                  end else udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h1}; // 8 bit mem
		
      8'b1101_0011: if (modrm[7:6]==2'b11) udeco <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // word reg
		                      else udeco <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h1}; // word mem
      
      8'b1101_0100: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // aam
      8'b1101_0101: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // aad      
      8'b1101_0110: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // SALC      
      8'b1101_0111: udeco <= {8'h03,8'ha6,8'h10,56'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1c,8'h1}; // mov: m->a - 8bit // xlat     
      
      8'b1101_1xxx: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101; // esc FPU
      
      8'b1110_0000: udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf7,8'he2,8'h19,8'h1,8'hce};// loopne
      8'b1110_0001: udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf6,8'he2,8'h19,8'h1,8'hce};// loope
      8'b1110_0010: udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf5,8'he2,8'h19,8'h1,8'hce};// loop
      8'b1110_0011: udeco <= {8'he1,8'ha8,jsz,4'h0,56'h0,8'hfd,8'he1,8'h18,8'hf8,8'h1,8'hce};// jcxz  
      8'b1110_0100: udeco <= {8'h0a,8'h66,4'h1,4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 8b
      8'b1110_0101: udeco <= {8'h0a,8'h66,{1'b0,opz},4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 16b/32b
      8'b1110_0110: udeco <= {8'h0a,8'h66,4'h1,4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 8b            
      8'b1110_0111: udeco <= {8'h0a,8'h66,{1'b0,opz},4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 32b      
      8'b1110_1000: if (adz ==0) udeco <= {8'hee,8'ha6,8'h20,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
                            else udeco <= {8'hee,8'ha6,8'h40,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
      
      8'b1110_1001: udeco <= {4'he,4'h6,8'ha6,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
      8'b1110_1011: udeco <= {4'he,4'h8,8'ha8,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
      8'b1110_1010: if (adz ==0) udeco <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'hcf,8'he3,8'h27,8'h20,8'h1,40'h0,8'hce}; // jmp indirect different segment
                            else udeco <= {8'he9,8'ha6,8'h40,8'h0,8'hfc,8'hcf,8'he3,8'h4b,8'h20,8'h1,40'h0,8'hce};
      8'b1110_1100: udeco <= {8'h02,8'h66,4'h1,4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 8b	
      8'b1110_1101: udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 32b
      8'b1110_1110: udeco <= {8'h02,8'h66,4'h1,4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 8b      
      8'b1110_1111: udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 32b      
      8'b1111_0100: udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,32'h0,8'hff,8'h00,8'h0,48'h0}; // hlt
      8'b1111_0101: udeco <= {8'hf9,8'ha6,8'h40,32'h1,32'h0,8'h00,8'hb6,8'b0001_0110,8'b0010_1010,8'h1};  // cmc

      8'b1111_0110: // test, not, neg, mul, imul - 8bit
        case (modrm[5:3])
	 3'b000: if (modrm[7:6]==2'b11) //test imm -> r byte
	         case( modrm[2] )
                  1'b0: udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
                  1'b1: udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
	         endcase
	        else //test imm -> m byte
                  udeco<={4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};
	 
	 3'b001: if (modrm[7:6]==2'b11) // test again 
	         case( modrm[2] )	 
                  1'b0: udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
                  1'b1: udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
	         endcase
	        else //test imm -> m byte
                  udeco<={4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};    	 
		  
	 3'b010: if (modrm[7:6]==2'b11) // not (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h1f,72'h0,8'h00,8'hb6,8'h16,8'h1};
                  1'b1: udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h3f,72'h0,8'h00,8'hb6,8'h16,8'h1};     
	         endcase
	        else //not imm -> m byte
                  udeco<={4'h0,4'h9,4'h0,4'h7,8'h1f,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h1e,8'h2d,8'h1};
		  
	 3'b011: if (modrm[7:6]==2'b11) // neg (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h18,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};
                  1'b1: udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h38,48'h0,8'h0,8'hba,8'he1,8'h2e,8'hb4,8'h2e,8'h1};   
	         endcase
	        else //neg imm -> m byte
                  udeco<={4'h0,4'h9,4'h0,4'h7,8'h1f,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h1e,8'h2d,8'h1};
		  
	 3'b100: if (modrm[7:6]==2'b11) // MUL (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1};
                  1'b1: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h26,8'h1};	    
	         endcase
	        else //MUL imm -> m byte
                  udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1e,8'h1};
		  
	 3'b101: if (modrm[7:6]==2'b11) // IMUL (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1};
                  1'b1: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h26,8'h1};	    
	         endcase
	        else //MUL imm -> m byte
                  udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1e,8'h1};
		  
	 3'b110: if (modrm[7:6]==2'b11) // DIV (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1};
                  1'b1: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h26,8'h1};   
	         endcase
	        else //DIV ax -> m byte
                  udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1e,8'h1};
		  
	 3'b111: if (modrm[7:6]==2'b11) // IDIV (byte) 
	         case( modrm[2] )	 
                  1'b0: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1};
                  1'b1: udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h26,8'h1};   
	         endcase
	        else //IDIV ax -> m byte
                  udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1e,8'h1};
	endcase

      8'b1111_0111: // test, not, neg, mul, imul - word
        case (modrm[5:3])
	 3'b000:if (modrm[7:6]==2'b11) udeco<={{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
	   else udeco<={4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};    	 
	 
	 3'b001:if (modrm[7:6]==2'b11) udeco<={{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
	   else udeco<={4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};
	   
	 3'b010: if (modrm[7:6]==2'b11) // not (word) 
                  udeco<={{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,72'h0,8'h00,8'hb6,8'h16,8'h1};	  
	        else //not imm -> m word
                  udeco<={4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h3,8'h2d,8'h1};
		  
	 3'b011: if (modrm[7:6]==2'b11) // neg (word) 
                  udeco<={{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};	  
	        else //neg imm -> m word
                  udeco<={4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h3,8'h2d,8'h1};

	 3'b100: if (opz ==2) 
	         begin
		 if (modrm[7:6]==2'b11) // MUL (word) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h1};
	         else //MUL imm -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h3,8'h1};
		 end
		else
	         begin
		 if (modrm[7:6]==2'b11) // MUL (dword) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h1};
	         else //MUL imm -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h3,8'h1};
		 end
			  
	 3'b101: if (opz==2)
	       begin
	        if (modrm[7:6]==2'b11) // IMUL (word) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h1};
	        else //MUL imm -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
               end
	       else
	       begin
	        if (modrm[7:6]==2'b11) // IMUL (dword) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h1};
	        else //MUL imm -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
	       end
	       
	 3'b110: if (modrm[7:6]==2'b11) // DIV (word) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h58,8'h45,8'h1};
	        else //DIV ax -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h58,8'h45,8'h3,8'h1};
		  
	 3'b111: if (modrm[7:6]==2'b11) // IDIV (word) 
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h59,8'h46,8'h1};
	        else //IDIV ax -> m word
                  udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h59,8'h46,8'h3,8'h1};
		  
	endcase

      8'b1111_1000: udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fffe,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // clc
      8'b1111_1001: udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0001,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // stc
      8'b1111_1010: udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fdff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cli
      8'b1111_1011: udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0200,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // sti
      8'b1111_1100: udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fbff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cld
      8'b1111_1101: udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0400,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // std
      8'b1111_1110: // inc r/m8
        casex (modrm[7:2])
	  6'b110000 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h19,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // inc reg low
	  6'b110001 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h39,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // inc reg high	  
	  6'b110010 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h1f,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // dec reg low
	  6'b110011 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h3f,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // dec reg high	  
	  6'b01000x : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8
	  6'b10000x : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8  	    
	  6'b00000x : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8  	    
	  6'b01001x : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8
	  6'b10001x : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      
	  6'b00001x : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      
	  default   : udeco<= 128'hffffffff_ffffffff_ffffffff_ff010101;
        endcase	
      8'b1111_1111: 
	 case (modrm[5:3])
	  3'b000: if (modrm[7:6]==2'b11) udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
	                            else udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};				    
	  3'b001: if (modrm[7:6]==2'b11) udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
	                            else udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};
	  
	  3'b010: if (modrm[7:6]==2'b11)
	     udeco <= {8'h4e,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h2d,8'h4,8'h1,8'hfb,8'hce}; // CALL
	else udeco <= {8'h4e,8'he7,                 {1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h03,8'h4,8'h1,8'hfb,8'hce};   
		  
	  3'b011: if (modrm[7:6]==2'b11)
	     udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101;
	else udeco <= {8'h9e,8'h97,{1'b0,opz},4'h0,8'h0,8'hfc,8'he3,8'h28,8'h3,8'h1,8'd4,8'h2d,8'd4,8'h2d,8'h1,8'hfb,8'hce}; // CALLF
	
	  3'b100: if (modrm[7:6]==2'b11) udeco <= {4'he,{1'b0,modrm[2:0]},8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he1,8'h23,8'h1,8'hce};
	                            else udeco <= {4'he,             4'he,8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h03,8'h1,8'hce};		  
	  3'b101: if (modrm[7:6]==2'b11) udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101;
	                            else udeco <= {8'h9e,8'ha7,8'h20,64'h0,8'hfc,8'he3,8'b0010_1000,8'h3,8'h1};	  
	  3'b110: if (modrm[7:6]==2'b11) udeco <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,80'h0,8'hff,8'h4,8'h1};
	                            else udeco <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,72'h0,8'hff,8'h4,8'h3,8'h1};	  
	  3'b111: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101;
	 endcase
      default: udeco <= 128'hffffffff_ffffffff_ffffffff_ff010101;// invalid opcode
  endcase

endmodule
