module dec_mem (a , q , clk );

// modrm
//
//
//





output reg [127:0] q;
input       [8:0]  a;
input              clk;


reg [127:0] Mem [339:0];
reg [7:0] Ctrl [339:0];


always @(a) q <= Mem[a];
always @(a) q <= Ctrl[a];


initial
begin

// exceptions 

Mem[322] <= {4'ha,4'h4,4'hf,4'h6,4'h4,4'h9,4'he,4'hd,8'h0,8'he,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};	// int vector idt protected
Mem[323] <= {4'hf,4'h9,4'he,4'h4,4'h4,4'hd,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};		// int vector idt protected
Mem[324] <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101; 
Mem[325] <= {4'ha,4'h4,4'hf,4'h5,4'h4,4'h9,4'he,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};    // fpu emulation device busy
Mem[326] <= {4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h00,8'h00,8'h00,16'h0,8'hce};    // fpu emulation device busy
 
 // two byte
 
Mem[256] <= {1'b0,modrm[2:0],1'b0,modrm[2:0],8'h07,8'h42,80'h0,8'hff,8'h61,8'h1};  // LLDT    
Mem[257] <= {8'h0,8'h07,8'h40,64'h0,8'hff,8'h61,8'h3,8'h1d,8'h1}; // LLDT
Mem[258] <= {1'b0,modrm[5:3],4'h0,8'h07,8'h42,80'h0,8'hff,8'h63,8'h1};  // LTRW   
Mem[259] <= {8'h0,8'h07,8'h40,72'h0,8'hff,8'h63,8'h3,8'h1}; // LTRW 
Mem[260] <= {8'h0,8'h07,8'h42,64'h0,8'hff,8'h60,8'h3,8'h1d,8'h1};  // LGDT
Mem[261] <= {8'h0,8'h07,8'h42,64'h0,8'hff,8'h62,8'h3,8'h1d,8'h1};  // LIDT
Mem[262] <= {8'h0,8'h0,8'h0,80'h0,8'hff,8'hc9,8'h1};  // INVLPG 486 , flush all tlb
Mem[263] <= {8'h0,8'h07,{1'b0,opz},4'h0,40'h0,8'hff,8'hb3,8'hb2,8'hb1,8'h3,8'hb0,8'h3,8'h1};

Mem[264] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,4'b1101,op[3:0],8'h1}; //CMOV
Mem[265] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'b0,56'h0,8'h00,8'h00,8'hbc,8'd3,4'b1101,op[3:0],8'h1}; // CMOV

Mem[266] <= {8'h0,8'h0,8'h0,80'h0,8'hff,8'hcd,8'h1}; // RDTSC
Mem[267] <= {8'h0,1'b0,op[2:0],4'h7,8'h40,72'h0,8'hff,8'he4,8'h4f,8'h1}; // bswap
Mem[268] <= {8'h0,8'h07,8'h42,80'h0,8'hff,8'hcc,8'h1}; // CPU ID 
Mem[269] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,56'h0,8'hff,8'he3,8'hca,8'ha,8'h17,8'h1}; // cmpxchg reg 
Mem[270] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'hcb,8'ha,8'h17,8'h3,8'h1}; // cmpxchg word  mem
Mem[271] <= {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'hff,8'he6,8'h2c,8'h2d,8'ha,8'h10,8'h1}; // xadd word 
Mem[272] <= {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,32'h0,8'hff,8'he4,8'h02,8'h2c,8'h2d,8'ha,8'h10,8'h3,8'h1}; // xadd word  mem
Mem[273] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,72'h0,8'h00,8'hb6,8'h49,8'h1}; // read from cr
Mem[274] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,80'h0,8'hff,8'h4a,8'h1}; // write to cr
Mem[275] <= {8'hee,8'ha6,{1'b0,opz},4'h0,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals      
Mem[276] <= {{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h10,32'h1,16'h0,8'h0,8'hb7,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
Mem[277] <= {{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h30,32'h1, 8'h0,8'h0,8'hb7,8'h2e,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
Mem[278] <= {             4'h0,             4'h0,8'ha7,8'h10,32'h1,8'h0,8'hff,8'h2,8'h2a,4'b1101,op[3:0],8'h2,8'h2c,8'h16,8'h1}; // setcc Conditionals
Mem[279] <= {4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push fs 
Mem[280] <= {4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop fs 
Mem[281] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
Mem[282] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,48'h0,8'hff,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Mem[283] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x imm )
Mem[284] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   
Mem[285] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x CL )
Mem[286] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   
Mem[287] <= {4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push gs
Mem[288] <= {4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop gs
Mem[289] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
Mem[290] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; // Bit Test
Mem[291] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x imm )
Mem[292] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	  // shrd 
Mem[293] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x CL )
Mem[294] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	  // shrd 

Mem[295] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h1};
Mem[296] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
Mem[297] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h1};
Mem[298] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
Mem[299] <= {1'b0,modrm[5:3],1'b0,modrm[5:3],8'h27,8'h40,72'h0,8'h0,8'hb7,8'h03,8'h1}; // LSS
Mem[300] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
Mem[301] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Mem[302] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1};
Mem[303] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h26,8'h1};
Mem[304] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1e,8'h1};
Mem[305] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4e,8'h1}; // movzx word
Mem[306] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4e,8'h3,8'h1};
Mem[307] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
Mem[308] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,32'h0,8'hff,8'hff,8'h2c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Mem[309] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
Mem[310] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
Mem[311] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
Mem[312] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
Mem[313] <= {1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h35,8'hc6,8'h2d,8'h0e,8'h1};             // Bit Scan forward
Mem[314] <= {1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h35,8'hc6,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan forward
Mem[315] <= {1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h36,8'hc7,8'h2d,8'h0e,8'h1};             // Bit Scan reverse
Mem[316] <= {1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h36,8'hc7,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan reverse
Mem[317] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h2f,8'h1};
Mem[318] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h26,8'h1};			 
Mem[319] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h3,8'h1};
Mem[320] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4c,8'h1};
Mem[321] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4c,8'h3,8'h1};


// One Byte

Mem[0] <= {src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};
Mem[1] <= {src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};	   
Mem[2] <= {src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
Mem[3] <= {src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};
Mem[4] <= {src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};	   
Mem[5] <= {src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
Mem[6] <= {src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};
Mem[7] <= {src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};

Mem[8] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};
Mem[9] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   	   
Mem[10] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};	   
Mem[11] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   
Mem[12] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};	   
Mem[13] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1}; 	   	     
Mem[14] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};
Mem[15] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1};
Mem[16] <= {src,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1}; 
Mem[17] <= {src,8'ha7,{1'b0,opz,4'b0},56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'd3,8'h1};
Mem[18] <= {src,8'ha7,{1'b0,opz,4'b0},32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'd3,8'h2d,8'h1};
Mem[19] <= {8'h06,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};              // add/or/adc/sbb/and/sub/xor/cmp i->al -byte
Mem[20] <= {8'h06,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};    // add/or/adc/sbb/and/sub/xor/cmp i->eax/ax -word 

Mem[21] <= {4'h4,{2'b10,op[4:3]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push seg
Mem[22] <= {4'h4,{2'b10,op[4:3]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop seg
Mem[23] <= {{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // inc word reg
Mem[24] <= {{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // dec word reg
Mem[25] <= {4'h4,{1'b0,op[2:0]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push reg
Mem[26] <= {4'h0,{1'b0,op[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop reg
Mem[27] <= {4'h0,4'h1,4'h2,4'h8,{1'b0,opz},4'h3,4'h4,4'h5,4'h6,4'h7,72'h0,8'hff,8'hc4}; // pusha
Mem[28] <= {4'h7,4'h6,4'h5,4'h8,{1'b0,opz},4'h4,4'h3,4'h2,4'h1,4'h0,72'h0,8'hff,8'hc5}; // popa
Mem[29] <= {8'h06,8'h06,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm      
Mem[30] <= {8'h08,8'h08,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm
Mem[31] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm8 *rm
Mem[32] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm8 *rm
Mem[33] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm8 *rm
Mem[34] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm8 *rm
Mem[35] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm *rm
Mem[36] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm *rm
Mem[37] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm *rm
Mem[38] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm *rm
Mem[39] <= {4'he,4'h8,8'ha8,{1'b0,opz},4'h8,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals
Mem[40] <= {2'b0,modrm[1:0],4'h6,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Mem[41] <= {2'b0,modrm[1:0],4'b0,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,modrm[5:3],8'h2b,8'h2e,8'h1};	  	  
Mem[42] <= {8'h06,8'ha7,8'h18,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};
Mem[43] <= {1'b0,modrm[2:0],4'h6,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Mem[44] <= {8'h06,8'ha7,{1'b0,opz},4'h8,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};
Mem[45] <= {1'b0,modrm[2:0],4'h8,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Mem[46] <= {8'h06,8'ha7,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h2f,8'h47,8'h3,8'h2d,8'h1};
Mem[48] <= {src8,8'ha6,8'h10,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[49] <= {src8,8'ha6,8'h30,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	   
Mem[50] <= {src8,8'ha6,8'h10,64'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h26,8'h1};	   
Mem[51] <= {src8,8'ha6,8'h30,48'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h26,8'h1};
Mem[52] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,48'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h1};	   
Mem[53] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h26,8'h47,8'h1e,8'h1};
Mem[54] <= {src,8'ha6,{1'b0,opz},4'h0,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[55] <= {8'h0,{2'b0,modrm[4:3]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h0,8'h47,8'h3,8'h1};	   
Mem[56] <= {4'h0,src8,4'h7,8'h10,72'h0,8'hff,8'he6,8'h2d,8'h1};
Mem[57] <= {4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; 
Mem[58] <= {src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1}; 
Mem[59] <= {4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; 
Mem[60] <= {src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};
Mem[61] <= {4'h0,src8,4'h7,8'h30,72'h0,8'hff,8'he6,8'h2d,8'h1};
Mem[62] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,64'h0,8'hff,8'he4,8'h2d,8'h1e,8'h1};	   
Mem[63] <= {2'b0,modrm[4:3],4'h7,8'h30,56'h0,8'hff,8'he4,8'h2,8'h41,8'h1e,8'h1};
Mem[64] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg word
Mem[65] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},56'h0,8'hff,8'he4,8'h2,8'h2d,8'h3,8'h1}; // xchg word
Mem[66] <= {src,8'ha6,{1'b0,opz},4'h0,80'h0,8'h00,8'hbc,8'h1}; 
Mem[67] <= {src[3:0],src[7:4],8'ha7,{1'b0,opz,4'b0},64'h0,16'h00,8'hb7,8'd3,8'h1};
Mem[68] <= {src,8'ha7,{1'b0,opz,4'b0},80'h0,8'hff,8'd2,8'h1};
Mem[69] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[70] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};	   
Mem[71] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
Mem[72] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};
Mem[73] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};	   
Mem[74] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
Mem[75] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[76] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[77] <= {src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};
Mem[78] <= {src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};	   
Mem[79] <= {src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};	   // doute
Mem[80] <= {src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};
Mem[81] <= {src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};	   
Mem[82] <= {src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};   
Mem[83] <= {src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};
Mem[84] <= {src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};
Mem[85] <= {{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[86] <= {{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,80'h0,8'hff,8'h2,8'h1};
Mem[87] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2c,8'h1}; // lea
Mem[88] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2b,8'h1};
Mem[89]	<= {{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h0,8'h1};
Mem[90]	<= {{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h03,8'h1};
Mem[91] <= {4'h0,{1'b0,modrm[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};//  pop reg non-standard)   
Mem[92] <= {4'h0,{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,56'h0,8'hff,8'h2,8'hf,8'hf9,8'h5,8'h1};//  pop mem        
Mem[93] <= {4'ha,{1'b0,op[2:0]},4'h0,{5'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // nop, xchg acum      
Mem[94] <= {8'h00,8'h27,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2f,8'h1}; // cbw
Mem[95] <= {8'h09,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'he5,8'h48,8'h1}; // cwd			     
Mem[96] <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'he3,8'h20,8'h27,8'h4,8'h2c,8'h4,8'h1,8'hfb,16'h0,8'hce}; // call different seg
Mem[97] <= {8'h4f,8'ha1,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'h2,8'hf1,8'h29,8'h18,8'h1};// pushf
Mem[98] <= {8'h4f,8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'd5,8'h1};// popf
Mem[99] <= {8'hf0,8'ha1,8'h10,72'h0,8'h00,8'hb6,8'h25,8'h1}; // sahf
Mem[100] <= {8'h0f,8'ha1,8'h30,72'h0,8'h00,8'hb6,8'h24,8'h1}; // lahf
Mem[101] <= {8'h00,8'ha6,8'h10,72'h0,8'h00,8'hb7,8'h1e,8'h1}; // mov: m->a - 8bit
Mem[102] <= {8'h01,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h03,8'h1}; // mov: m->a -word
Mem[103] <= {8'h10,8'ha6,8'h10,80'h0,8'hff,8'h02,8'h1}; // mov: a->m - 8bit
Mem[104] <= {8'h10,8'ha6,{1'b0,opz},4'h0,80'h0,8'hff,8'h02,8'h1};// mov: a->m -word      
Mem[105] <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'hf2,8'h1,8'hc3}; // movs byte
Mem[106] <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'h1,8'hc3}; // movs byte, faster without when cr0[0]==1
Mem[107] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'hf2,8'h1,8'hc3}; // movs word/dword   
Mem[108] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'h1,8'hc3}; // movs word/dword, faster without when cr0[0]==1
Mem[109] <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'h1f,8'hf2,8'h1,8'hc3}; // cmps byte
Mem[110] <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'h1f,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1
Mem[111] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'd9,8'hf2,8'h1,8'hc3}; // cmps word
Mem[112] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'd9,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1     
Mem[113] <= {8'h06,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> al
Mem[114] <= {8'h06,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> ax/eax       	       
Mem[115] <= {8'h00,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos byte
Mem[116] <= {8'h00,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos word/dword
Mem[117] <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'hf2,8'h1,8'hc3}; // lods byte
Mem[118] <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'h1,8'hc3}; // lods byte, faster without when cr0[0]==1  
Mem[119] <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'hf2,8'h1,8'hc3}; // lods word/dword
Mem[120] <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'h1,8'hc3}; // lods word/dword
Mem[121] <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'hf0,8'h1,8'hc3}; // scas byte      
Mem[122] <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'h1,8'hc3}; // scas byte 
Mem[123] <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'hf0,8'h1,8'hc3}; // scas word/dword
Mem[124] <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'h1,8'hc3}; // scas word/dword
Mem[125] <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0001,8'h1}; // mov: i->r - byte low
Mem[126] <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0010,8'h1}; // mov: i->r - byte high
Mem[127] <= {{1'b0,op[2:0]},4'h9,8'hc6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,8'b0010_0000,8'h1}; // mov: i->r - word
Mem[128] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // 8 bit reg low
Mem[129] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h38,32'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h2d,8'h1}; // 8 bit reg high
Mem[130] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h2d,8'h1}; // 8 bit mem		
Mem[131] <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // word reg
Mem[132] <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h2d,8'h1}; // word mem		  
Mem[133] <= {8'h4e,8'ha6,{1'b0,opz},{1'b0,opz},32'h0,8'hfc,8'he1,8'h18,8'h1,8'he2,8'h5,8'h1,8'h0,8'hce}; // ret near with value
Mem[134] <= {8'h0e,8'ha6,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h5,8'hce,8'h1}; // ret near      
Mem[135] <= {4'h8,{1'b0,modrm[5:3]},8'h87,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // les      
Mem[136] <= {4'hb,{1'b0,modrm[5:3]},8'hb7,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // lds      
Mem[137] <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,64'h0,8'h00,8'h00,8'hbc,8'b0010_0110,8'h1};
Mem[138] <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[139] <= {1'b0,modrm[5:3],4'h6,8'ha7,4'h1,4'h8,80'h0,8'hff,8'h2,8'h1};
Mem[140] <= {1'b0,modrm[2:0],4'h6,8'ha7,{1'b0,opz},4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
Mem[141] <= {1'b0,modrm[5:3],4'h6,8'ha7,{1'b0,opz},4'h8,80'h0,8'hff,8'h2,8'h1};
Mem[142] <= {8'h45,8'h67,{1'b0,opz},4'h0,56'h0,8'h0,8'hb7,8'h5,8'he1,8'h23,8'h1}; // leave
Mem[143] <= {8'h49,8'he6,{1'b0,opz},{1'b0,opz},16'h0,8'hfc,8'he1,8'h18,8'h1,8'he6,8'd5,8'h2d,8'd5,8'h1,8'h0,8'hce}; // ret far with value
Mem[144] <= {8'he9,8'he6,{1'b0,opz},{1'b0,opz},40'h0,8'hfc,8'he3,8'd5,8'h23,8'd5,8'h1,8'h0,8'hce}; // ret far
Mem[145] <= {8'h9e,8'hfb,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int 3
Mem[146] <= {8'h9e,8'hf6,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int      
Mem[147] <= {4'ha,4'h4,4'hf,4'h5,{1'b0,opz},4'h9,4'he,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'h68,8'h67,8'h66,8'hfb,8'h0,8'hce}; // int idt protected
Mem[148] <= {4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected		       
Mem[149] <= {8'h9e,8'hfb,{1'b0,opz},4'h4,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb,8'hd0}; // into           
Mem[150] <= {4'he,4'h9,4'hf,4'h3,{1'b0,opz},4'h4,4'ha,4'h0,32'h0,8'hfc,8'hc9,8'hc5,16'h0,8'hb5,8'hc9,8'hce}; // iret
Mem[151] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1}; // 8 bit reg low
Mem[152] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'h2e,8'h1}; // 8 bit reg high
Mem[153] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h1e,8'h1}; // 8 bit mem
Mem[154] <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1};  // word reg
Mem[155] <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h3,8'h1}; // word mem
Mem[156] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // 8 bit reg low
Mem[157] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h1}; // 8 bit reg high
Mem[158] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h1}; // 8 bit mem
Mem[159] <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // word reg
Mem[160] <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h1}; // word mem
Mem[161] <= {8'h03,8'ha6,8'h10,56'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1c,8'h1}; // mov: m->a - 8bit // xlat     
Mem[162] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf7,8'he2,8'h19,8'h1,8'hce};// loopne
Mem[163] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf6,8'he2,8'h19,8'h1,8'hce};// loope
Mem[164] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf5,8'he2,8'h19,8'h1,8'hce};// loop
Mem[165] <= {8'he1,8'ha8,jsz,4'h0,56'h0,8'hfd,8'he1,8'h18,8'hf8,8'h1,8'hce};// jcxz  
Mem[166] <= {8'h0a,8'h66,4'h1,4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 8b
Mem[167] <= {8'h0a,8'h66,{1'b0,opz},4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 16b/32b
Mem[168] <= {8'h0a,8'h66,4'h1,4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 8b            
Mem[169] <= {8'h0a,8'h66,{1'b0,opz},4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 32b      
Mem[170] <= {8'hee,8'ha6,8'h20,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
Mem[171] <= {8'hee,8'ha6,8'h40,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
Mem[172] <= {4'he,4'h6,8'ha6,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
Mem[173] <= {4'he,4'h8,8'ha8,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
Mem[174] <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'hcf,8'he3,8'h27,8'h20,8'h1,40'h0,8'hce}; // jmp indirect different segment
Mem[175] <= {8'he9,8'ha6,8'h40,8'h0,8'hfc,8'hcf,8'he3,8'h4b,8'h20,8'h1,40'h0,8'hce};
Mem[176] <= {8'h02,8'h66,4'h1,4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 8b	
Mem[177] <= {8'h02,8'h66,{1'b0,opz},4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 32b
Mem[178] <= {8'h02,8'h66,4'h1,4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 8b      
Mem[179] <= {8'h02,8'h66,{1'b0,opz},4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 32b      
Mem[180] <= {8'h02,8'h66,{1'b0,opz},4'h0,32'h0,8'hff,8'h00,8'h0,48'h0}; // hlt
Mem[181] <= {8'hf9,8'ha6,8'h40,32'h1,32'h0,8'h00,8'hb6,8'b0001_0110,8'b0010_1010,8'h1};  // cmc
Mem[182] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[183] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
Mem[184] <= {4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};
Mem[185] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[186] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
Mem[187] <= {4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};    	 
Mem[188] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h1f,72'h0,8'h00,8'hb6,8'h16,8'h1};
Mem[189] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h3f,72'h0,8'h00,8'hb6,8'h16,8'h1};     
Mem[190] <= {4'h0,4'h9,4'h0,4'h7,8'h1f,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h1e,8'h2d,8'h1};
Mem[191] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h18,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};
Mem[192] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h38,48'h0,8'h0,8'hba,8'he1,8'h2e,8'hb4,8'h2e,8'h1};   
Mem[193] <= {4'h0,4'h9,4'h0,4'h7,8'h1f,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h1e,8'h2d,8'h1};
Mem[194] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1};
Mem[195] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h26,8'h1};	    
Mem[196] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1e,8'h1};
Mem[197] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1};
Mem[198] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h26,8'h1};	    
Mem[199] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1e,8'h1};
Mem[200] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1};
Mem[201] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h26,8'h1};   
Mem[202] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1e,8'h1};
Mem[203] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1};
Mem[204] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h26,8'h1};   
Mem[205] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1e,8'h1};
Mem[206] <= {{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[207] <= {4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};    	 
Mem[208] <= {{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Mem[209] <= {4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};
Mem[210] <= {{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,72'h0,8'h00,8'hb6,8'h16,8'h1};	  
Mem[211] <= {4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h3,8'h2d,8'h1};
Mem[212] <= {{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};	  
Mem[213] <= {4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h3,8'h2d,8'h1};
Mem[214] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h1};
Mem[215] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h3,8'h1};
Mem[216] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h1};
Mem[217] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h3,8'h1};
Mem[218] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h1};
Mem[219] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
Mem[220] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h1};
Mem[221] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
Mem[222] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h58,8'h45,8'h1};
Mem[223] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h58,8'h45,8'h3,8'h1};
Mem[224] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h59,8'h46,8'h1};
Mem[225] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h59,8'h46,8'h3,8'h1};
Mem[226] <= {8'hf9,8'ha6,8'h40,32'hffff_fffe,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // clc
Mem[227] <= {8'hf9,8'ha6,8'h40,32'h0000_0001,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // stc
Mem[228] <= {8'hf9,8'ha6,8'h40,32'hffff_fdff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cli
Mem[229] <= {8'hf9,8'ha6,8'h40,32'h0000_0200,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // sti
Mem[230] <= {8'hf9,8'ha6,8'h40,32'hffff_fbff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cld
Mem[231] <= {8'hf9,8'ha6,8'h40,32'h0000_0400,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // std
Mem[232] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h19,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // inc reg low
Mem[233] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h39,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // inc reg high	  
Mem[234] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h1f,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // dec reg low
Mem[235] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h3f,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // dec reg high	  
Mem[236] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8
Mem[237] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8  	    
Mem[238] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8  	    
Mem[239] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8
Mem[240] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      
Mem[241] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      
Mem[242] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
Mem[243] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};				    
Mem[244] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
Mem[245] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};
Mem[246] <= {8'h4e,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h2d,8'h4,8'h1,8'hfb,8'hce}; // CALL
Mem[247] <= {8'h4e,8'he7,                 {1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h03,8'h4,8'h1,8'hfb,8'hce};   
Mem[248] <= {8'h9e,8'h97,{1'b0,opz},4'h0,8'h0,8'hfc,8'he3,8'h28,8'h3,8'h1,8'd4,8'h2d,8'd4,8'h2d,8'h1,8'hfb,8'hce}; // CALLF
Mem[249] <= {4'he,{1'b0,modrm[2:0]},8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he1,8'h23,8'h1,8'hce};
Mem[250] <= {4'he,             4'he,8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h03,8'h1,8'hce};		  
Mem[251] <= {8'h9e,8'ha7,8'h20,64'h0,8'hfc,8'he3,8'b0010_1000,8'h3,8'h1};	  
Mem[252] <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,80'h0,8'hff,8'h4,8'h1};
Mem[253] <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,72'h0,8'hff,8'h4,8'h3,8'h1};	  



////////////////////////////////////////////////////:
// Control
////////////////////////////////////////////////////:



// exceptions 

Ctrl[322] <= 0;	   // int vector idt protected
Ctrl[323] <= 0;    // int vector idt protected
Ctrl[324] <= 0; 
Ctrl[325] <= 0;    // fpu emulation device busy
Ctrl[326] <= 0;    // fpu emulation device busy
 
 // two byte
 
Ctrl[256] <= {1'b0,modrm[2:0],1'b0,modrm[2:0],8'h07,8'h42,80'h0,8'hff,8'h61,8'h1};  // LLDT    
Ctrl[257] <= {8'h0,8'h07,8'h40,64'h0,8'hff,8'h61,8'h3,8'h1d,8'h1}; // LLDT
Ctrl[258] <= {1'b0,modrm[5:3],4'h0,8'h07,8'h42,80'h0,8'hff,8'h63,8'h1};  // LTRW   
Ctrl[259] <= {8'h0,8'h07,8'h40,72'h0,8'hff,8'h63,8'h3,8'h1}; // LTRW 
Ctrl[260] <= {8'h0,8'h07,8'h42,64'h0,8'hff,8'h60,8'h3,8'h1d,8'h1};  // LGDT
Ctrl[261] <= {8'h0,8'h07,8'h42,64'h0,8'hff,8'h62,8'h3,8'h1d,8'h1};  // LIDT
Ctrl[262] <= {8'h0,8'h0,8'h0,80'h0,8'hff,8'hc9,8'h1};  // INVLPG 486 , flush all tlb
Ctrl[263] <= {8'h0,8'h07,{1'b0,opz},4'h0,40'h0,8'hff,8'hb3,8'hb2,8'hb1,8'h3,8'hb0,8'h3,8'h1};

Ctrl[264] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,4'b1101,op[3:0],8'h1}; //CMOV
Ctrl[265] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'b0,56'h0,8'h00,8'h00,8'hbc,8'd3,4'b1101,op[3:0],8'h1}; // CMOV

Ctrl[266] <= {8'h0,8'h0,8'h0,80'h0,8'hff,8'hcd,8'h1}; // RDTSC
Ctrl[267] <= {8'h0,1'b0,op[2:0],4'h7,8'h40,72'h0,8'hff,8'he4,8'h4f,8'h1}; // bswap
Ctrl[268] <= {8'h0,8'h07,8'h42,80'h0,8'hff,8'hcc,8'h1}; // CPU ID 
Ctrl[269] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,56'h0,8'hff,8'he3,8'hca,8'ha,8'h17,8'h1}; // cmpxchg reg 
Ctrl[270] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'hcb,8'ha,8'h17,8'h3,8'h1}; // cmpxchg word  Ctrl
Ctrl[271] <= {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'hff,8'he6,8'h2c,8'h2d,8'ha,8'h10,8'h1}; // xadd word 
Ctrl[272] <= {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,32'h0,8'hff,8'he4,8'h02,8'h2c,8'h2d,8'ha,8'h10,8'h3,8'h1}; // xadd word  Ctrl
Ctrl[273] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,72'h0,8'h00,8'hb6,8'h49,8'h1}; // read from cr
Ctrl[274] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,80'h0,8'hff,8'h4a,8'h1}; // write to cr
Ctrl[275] <= {8'hee,8'ha6,{1'b0,opz},4'h0,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals      
Ctrl[276] <= {{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h10,32'h1,16'h0,8'h0,8'hb7,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
Ctrl[277] <= {{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h30,32'h1, 8'h0,8'h0,8'hb7,8'h2e,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
Ctrl[278] <= {             4'h0,             4'h0,8'ha7,8'h10,32'h1,8'h0,8'hff,8'h2,8'h2a,4'b1101,op[3:0],8'h2,8'h2c,8'h16,8'h1}; // setcc Conditionals
Ctrl[279] <= {4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push fs 
Ctrl[280] <= {4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop fs 
Ctrl[281] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
Ctrl[282] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,48'h0,8'hff,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Ctrl[283] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x imm )
Ctrl[284] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   
Ctrl[285] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld  ( x CL )
Ctrl[286] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1};	   
Ctrl[287] <= {4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push gs
Ctrl[288] <= {4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop gs
Ctrl[289] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
Ctrl[290] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; // Bit Test
Ctrl[291] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x imm )
Ctrl[292] <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	  // shrd 
Ctrl[293] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd  ( x CL )
Ctrl[294] <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};	  // shrd 

Ctrl[295] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h1};
Ctrl[296] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
Ctrl[297] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h1};
Ctrl[298] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
Ctrl[299] <= {1'b0,modrm[5:3],1'b0,modrm[5:3],8'h27,8'h40,72'h0,8'h0,8'hb7,8'h03,8'h1}; // LSS
Ctrl[300] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
Ctrl[301] <= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Ctrl[302] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1};
Ctrl[303] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h26,8'h1};
Ctrl[304] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1e,8'h1};
Ctrl[305] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4e,8'h1}; // movzx word
Ctrl[306] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4e,8'h3,8'h1};
Ctrl[307] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,80'h0,8'hff,8'h5a,8'h1}; //Bit Test 
Ctrl[308] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,32'h0,8'hff,8'hff,8'h2c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};
Ctrl[309] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set 
Ctrl[310] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
Ctrl[311] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset 
Ctrl[312] <= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; 
Ctrl[313] <= {1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h35,8'hc6,8'h2d,8'h0e,8'h1};             // Bit Scan forward
Ctrl[314] <= {1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h35,8'hc6,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan forward
Ctrl[315] <= {1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h36,8'hc7,8'h2d,8'h0e,8'h1};             // Bit Scan reverse
Ctrl[316] <= {1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h36,8'hc7,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan reverse
Ctrl[317] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h2f,8'h1};
Ctrl[318] <= {1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h26,8'h1};			 
Ctrl[319] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h3,8'h1};
Ctrl[320] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4c,8'h1};
Ctrl[321] <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4c,8'h3,8'h1};


// One Byte

Ctrl[0] <= {src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};
Ctrl[1] <= {src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};	   
Ctrl[2] <= {src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
Ctrl[3] <= {src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};
Ctrl[4] <= {src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};	   
Ctrl[5] <= {src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	   
Ctrl[6] <= {src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};
Ctrl[7] <= {src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};

Ctrl[8] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};
Ctrl[9] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   	   
Ctrl[10] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};	   
Ctrl[11] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	   
Ctrl[12] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};	   
Ctrl[13] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1}; 	   	     
Ctrl[14] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};
Ctrl[15] <= {{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1};
Ctrl[16] <= {src,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1}; 
Ctrl[17] <= {src,8'ha7,{1'b0,opz,4'b0},56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'd3,8'h1};
Ctrl[18] <= {src,8'ha7,{1'b0,opz,4'b0},32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'd3,8'h2d,8'h1};
Ctrl[19] <= {8'h06,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};              // add/or/adc/sbb/and/sub/xor/cmp i->al -byte
Ctrl[20] <= {8'h06,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};    // add/or/adc/sbb/and/sub/xor/cmp i->eax/ax -word 

Ctrl[21] <= {4'h4,{2'b10,op[4:3]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push seg
Ctrl[22] <= {4'h4,{2'b10,op[4:3]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop seg
Ctrl[23] <= {{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // inc word reg
Ctrl[24] <= {{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // dec word reg
Ctrl[25] <= {4'h4,{1'b0,op[2:0]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push reg
Ctrl[26] <= {4'h0,{1'b0,op[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop reg
Ctrl[27] <= {4'h0,4'h1,4'h2,4'h8,{1'b0,opz},4'h3,4'h4,4'h5,4'h6,4'h7,72'h0,8'hff,8'hc4}; // pusha
Ctrl[28] <= {4'h7,4'h6,4'h5,4'h8,{1'b0,opz},4'h4,4'h3,4'h2,4'h1,4'h0,72'h0,8'hff,8'hc5}; // popa
Ctrl[29] <= {8'h06,8'h06,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm      
Ctrl[30] <= {8'h08,8'h08,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm
Ctrl[31] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm8 *rm
Ctrl[32] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm8 *rm
Ctrl[33] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm8 *rm
Ctrl[34] <= {1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm8 *rm
Ctrl[35] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm *rm
Ctrl[36] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm *rm
Ctrl[37] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm *rm
Ctrl[38] <= {1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm *rm
Ctrl[39] <= {4'he,4'h8,8'ha8,{1'b0,opz},4'h8,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals
Ctrl[40] <= {2'b0,modrm[1:0],4'h6,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Ctrl[41] <= {2'b0,modrm[1:0],4'b0,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,modrm[5:3],8'h2b,8'h2e,8'h1};	  	  
Ctrl[42] <= {8'h06,8'ha7,8'h18,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};
Ctrl[43] <= {1'b0,modrm[2:0],4'h6,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Ctrl[44] <= {8'h06,8'ha7,{1'b0,opz},4'h8,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1};
Ctrl[45] <= {1'b0,modrm[2:0],4'h8,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};
Ctrl[46] <= {8'h06,8'ha7,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h2f,8'h47,8'h3,8'h2d,8'h1};
Ctrl[48] <= {src8,8'ha6,8'h10,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[49] <= {src8,8'ha6,8'h30,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	   
Ctrl[50] <= {src8,8'ha6,8'h10,64'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h26,8'h1};	   
Ctrl[51] <= {src8,8'ha6,8'h30,48'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h26,8'h1};
Ctrl[52] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,48'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h1};	   
Ctrl[53] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h26,8'h47,8'h1e,8'h1};
Ctrl[54] <= {src,8'ha6,{1'b0,opz},4'h0,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[55] <= {8'h0,{2'b0,modrm[4:3]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h0,8'h47,8'h3,8'h1};	   
Ctrl[56] <= {4'h0,src8,4'h7,8'h10,72'h0,8'hff,8'he6,8'h2d,8'h1};
Ctrl[57] <= {4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; 
Ctrl[58] <= {src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1}; 
Ctrl[59] <= {4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; 
Ctrl[60] <= {src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};
Ctrl[61] <= {4'h0,src8,4'h7,8'h30,72'h0,8'hff,8'he6,8'h2d,8'h1};
Ctrl[62] <= {8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,64'h0,8'hff,8'he4,8'h2d,8'h1e,8'h1};	   
Ctrl[63] <= {2'b0,modrm[4:3],4'h7,8'h30,56'h0,8'hff,8'he4,8'h2,8'h41,8'h1e,8'h1};
Ctrl[64] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg word
Ctrl[65] <= {4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},56'h0,8'hff,8'he4,8'h2,8'h2d,8'h3,8'h1}; // xchg word
Ctrl[66] <= {src,8'ha6,{1'b0,opz},4'h0,80'h0,8'h00,8'hbc,8'h1}; 
Ctrl[67] <= {src[3:0],src[7:4],8'ha7,{1'b0,opz,4'b0},64'h0,16'h00,8'hb7,8'd3,8'h1};
Ctrl[68] <= {src,8'ha7,{1'b0,opz,4'b0},80'h0,8'hff,8'd2,8'h1};
Ctrl[69] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[70] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};	   
Ctrl[71] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
Ctrl[72] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};
Ctrl[73] <= {src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1};	   
Ctrl[74] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1};	   
Ctrl[75] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[76] <= {src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[77] <= {src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};
Ctrl[78] <= {src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};	   
Ctrl[79] <= {src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};	   // doute
Ctrl[80] <= {src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};
Ctrl[81] <= {src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};	   
Ctrl[82] <= {src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};   
Ctrl[83] <= {src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};
Ctrl[84] <= {src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1};
Ctrl[85] <= {{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[86] <= {{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,80'h0,8'hff,8'h2,8'h1};
Ctrl[87] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2c,8'h1}; // lea
Ctrl[88] <= {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2b,8'h1};
Ctrl[89]	<= {{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h0,8'h1};
Ctrl[90]	<= {{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h03,8'h1};
Ctrl[91] <= {4'h0,{1'b0,modrm[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};//  pop reg non-standard)   
Ctrl[92] <= {4'h0,{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,56'h0,8'hff,8'h2,8'hf,8'hf9,8'h5,8'h1};//  pop Ctrl        
Ctrl[93] <= {4'ha,{1'b0,op[2:0]},4'h0,{5'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // nop, xchg acum      
Ctrl[94] <= {8'h00,8'h27,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2f,8'h1}; // cbw
Ctrl[95] <= {8'h09,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'he5,8'h48,8'h1}; // cwd			     
Ctrl[96] <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'he3,8'h20,8'h27,8'h4,8'h2c,8'h4,8'h1,8'hfb,16'h0,8'hce}; // call different seg
Ctrl[97] <= {8'h4f,8'ha1,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'h2,8'hf1,8'h29,8'h18,8'h1};// pushf
Ctrl[98] <= {8'h4f,8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'd5,8'h1};// popf
Ctrl[99] <= {8'hf0,8'ha1,8'h10,72'h0,8'h00,8'hb6,8'h25,8'h1}; // sahf
Ctrl[100] <= {8'h0f,8'ha1,8'h30,72'h0,8'h00,8'hb6,8'h24,8'h1}; // lahf
Ctrl[101] <= {8'h00,8'ha6,8'h10,72'h0,8'h00,8'hb7,8'h1e,8'h1}; // mov: m->a - 8bit
Ctrl[102] <= {8'h01,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h03,8'h1}; // mov: m->a -word
Ctrl[103] <= {8'h10,8'ha6,8'h10,80'h0,8'hff,8'h02,8'h1}; // mov: a->m - 8bit
Ctrl[104] <= {8'h10,8'ha6,{1'b0,opz},4'h0,80'h0,8'hff,8'h02,8'h1};// mov: a->m -word      
Ctrl[105] <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'hf2,8'h1,8'hc3}; // movs byte
Ctrl[106] <= {8'h16,8'h7b,      4'h1,      4'h1,1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'h1,8'hc3}; // movs byte, faster without when cr0[0]==1
Ctrl[107] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'hf2,8'h1,8'hc3}; // movs word/dword   
Ctrl[108] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'h1,8'hc3}; // movs word/dword, faster without when cr0[0]==1
Ctrl[109] <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'h1f,8'hf2,8'h1,8'hc3}; // cmps byte
Ctrl[110] <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'h1f,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1
Ctrl[111] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'd9,8'hf2,8'h1,8'hc3}; // cmps word
Ctrl[112] <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'd9,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1     
Ctrl[113] <= {8'h06,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> al
Ctrl[114] <= {8'h06,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> ax/eax       	       
Ctrl[115] <= {8'h00,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos byte
Ctrl[116] <= {8'h00,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos word/dword
Ctrl[117] <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'hf2,8'h1,8'hc3}; // lods byte
Ctrl[118] <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'h1,8'hc3}; // lods byte, faster without when cr0[0]==1  
Ctrl[119] <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'hf2,8'h1,8'hc3}; // lods word/dword
Ctrl[120] <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'h1,8'hc3}; // lods word/dword
Ctrl[121] <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'hf0,8'h1,8'hc3}; // scas byte      
Ctrl[122] <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'h1,8'hc3}; // scas byte 
Ctrl[123] <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'hf0,8'h1,8'hc3}; // scas word/dword
Ctrl[124] <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'h1,8'hc3}; // scas word/dword
Ctrl[125] <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0001,8'h1}; // mov: i->r - byte low
Ctrl[126] <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0010,8'h1}; // mov: i->r - byte high
Ctrl[127] <= {{1'b0,op[2:0]},4'h9,8'hc6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,8'b0010_0000,8'h1}; // mov: i->r - word
Ctrl[128] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // 8 bit reg low
Ctrl[129] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h38,32'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h2d,8'h1}; // 8 bit reg high
Ctrl[130] <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h2d,8'h1}; // 8 bit Ctrl		
Ctrl[131] <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // word reg
Ctrl[132] <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h2d,8'h1}; // word Ctrl		  
Ctrl[133] <= {8'h4e,8'ha6,{1'b0,opz},{1'b0,opz},32'h0,8'hfc,8'he1,8'h18,8'h1,8'he2,8'h5,8'h1,8'h0,8'hce}; // ret near with value
Ctrl[134] <= {8'h0e,8'ha6,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h5,8'hce,8'h1}; // ret near      
Ctrl[135] <= {4'h8,{1'b0,modrm[5:3]},8'h87,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // les      
Ctrl[136] <= {4'hb,{1'b0,modrm[5:3]},8'hb7,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // lds      
Ctrl[137] <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,64'h0,8'h00,8'h00,8'hbc,8'b0010_0110,8'h1};
Ctrl[138] <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[139] <= {1'b0,modrm[5:3],4'h6,8'ha7,4'h1,4'h8,80'h0,8'hff,8'h2,8'h1};
Ctrl[140] <= {1'b0,modrm[2:0],4'h6,8'ha7,{1'b0,opz},4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1};
Ctrl[141] <= {1'b0,modrm[5:3],4'h6,8'ha7,{1'b0,opz},4'h8,80'h0,8'hff,8'h2,8'h1};
Ctrl[142] <= {8'h45,8'h67,{1'b0,opz},4'h0,56'h0,8'h0,8'hb7,8'h5,8'he1,8'h23,8'h1}; // leave
Ctrl[143] <= {8'h49,8'he6,{1'b0,opz},{1'b0,opz},16'h0,8'hfc,8'he1,8'h18,8'h1,8'he6,8'd5,8'h2d,8'd5,8'h1,8'h0,8'hce}; // ret far with value
Ctrl[144] <= {8'he9,8'he6,{1'b0,opz},{1'b0,opz},40'h0,8'hfc,8'he3,8'd5,8'h23,8'd5,8'h1,8'h0,8'hce}; // ret far
Ctrl[145] <= {8'h9e,8'hfb,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int 3
Ctrl[146] <= {8'h9e,8'hf6,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int      
Ctrl[147] <= {4'ha,4'h4,4'hf,4'h5,{1'b0,opz},4'h9,4'he,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'h68,8'h67,8'h66,8'hfb,8'h0,8'hce}; // int idt protected
Ctrl[148] <= {4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected		       
Ctrl[149] <= {8'h9e,8'hfb,{1'b0,opz},4'h4,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb,8'hd0}; // into           
Ctrl[150] <= {4'he,4'h9,4'hf,4'h3,{1'b0,opz},4'h4,4'ha,4'h0,32'h0,8'hfc,8'hc9,8'hc5,16'h0,8'hb5,8'hc9,8'hce}; // iret
Ctrl[151] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1}; // 8 bit reg low
Ctrl[152] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'h2e,8'h1}; // 8 bit reg high
Ctrl[153] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h1e,8'h1}; // 8 bit Ctrl
Ctrl[154] <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1};  // word reg
Ctrl[155] <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h3,8'h1}; // word Ctrl
Ctrl[156] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // 8 bit reg low
Ctrl[157] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h1}; // 8 bit reg high
Ctrl[158] <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h1}; // 8 bit Ctrl
Ctrl[159] <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // word reg
Ctrl[160] <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h1}; // word Ctrl
Ctrl[161] <= {8'h03,8'ha6,8'h10,56'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1c,8'h1}; // mov: m->a - 8bit // xlat     
Ctrl[162] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf7,8'he2,8'h19,8'h1,8'hce};// loopne
Ctrl[163] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf6,8'he2,8'h19,8'h1,8'hce};// loope
Ctrl[164] <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf5,8'he2,8'h19,8'h1,8'hce};// loop
Ctrl[165] <= {8'he1,8'ha8,jsz,4'h0,56'h0,8'hfd,8'he1,8'h18,8'hf8,8'h1,8'hce};// jcxz  
Ctrl[166] <= {8'h0a,8'h66,4'h1,4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 8b
Ctrl[167] <= {8'h0a,8'h66,{1'b0,opz},4'h8,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in imm 16b/32b
Ctrl[168] <= {8'h0a,8'h66,4'h1,4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 8b            
Ctrl[169] <= {8'h0a,8'h66,{1'b0,opz},4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 32b      
Ctrl[170] <= {8'hee,8'ha6,8'h20,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
Ctrl[171] <= {8'hee,8'ha6,8'h40,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
Ctrl[172] <= {4'he,4'h6,8'ha6,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
Ctrl[173] <= {4'he,4'h8,8'ha8,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
Ctrl[174] <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'hcf,8'he3,8'h27,8'h20,8'h1,40'h0,8'hce}; // jmp indirect different segment
Ctrl[175] <= {8'he9,8'ha6,8'h40,8'h0,8'hfc,8'hcf,8'he3,8'h4b,8'h20,8'h1,40'h0,8'hce};
Ctrl[176] <= {8'h02,8'h66,4'h1,4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 8b	
Ctrl[177] <= {8'h02,8'h66,{1'b0,opz},4'h0,56'h0,8'h00,8'hb6,8'h7,8'h7,8'h7,8'h1}; // in dx 32b
Ctrl[178] <= {8'h02,8'h66,4'h1,4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 8b      
Ctrl[179] <= {8'h02,8'h66,{1'b0,opz},4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 32b      
Ctrl[180] <= {8'h02,8'h66,{1'b0,opz},4'h0,32'h0,8'hff,8'h00,8'h0,48'h0}; // hlt
Ctrl[181] <= {8'hf9,8'ha6,8'h40,32'h1,32'h0,8'h00,8'hb6,8'b0001_0110,8'b0010_1010,8'h1};  // cmc
Ctrl[182] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[183] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
Ctrl[184] <= {4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};
Ctrl[185] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[186] <= {{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  
Ctrl[187] <= {4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};    	 
Ctrl[188] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h1f,72'h0,8'h00,8'hb6,8'h16,8'h1};
Ctrl[189] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h3f,72'h0,8'h00,8'hb6,8'h16,8'h1};     
Ctrl[190] <= {4'h0,4'h9,4'h0,4'h7,8'h1f,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h1e,8'h2d,8'h1};
Ctrl[191] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h18,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};
Ctrl[192] <= {{2'b0,modrm[1:0]},4'h9,8'ha9,8'h38,48'h0,8'h0,8'hba,8'he1,8'h2e,8'hb4,8'h2e,8'h1};   
Ctrl[193] <= {4'h0,4'h9,4'h0,4'h7,8'h1f,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h1e,8'h2d,8'h1};
Ctrl[194] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1};
Ctrl[195] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h26,8'h1};	    
Ctrl[196] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1e,8'h1};
Ctrl[197] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1};
Ctrl[198] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h26,8'h1};	    
Ctrl[199] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1e,8'h1};
Ctrl[200] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1};
Ctrl[201] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h26,8'h1};   
Ctrl[202] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1e,8'h1};
Ctrl[203] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1};
Ctrl[204] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h26,8'h1};   
Ctrl[205] <= {4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1e,8'h1};
Ctrl[206] <= {{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[207] <= {4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};    	 
Ctrl[208] <= {{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
Ctrl[209] <= {4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};
Ctrl[210] <= {{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,72'h0,8'h00,8'hb6,8'h16,8'h1};	  
Ctrl[211] <= {4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h3,8'h2d,8'h1};
Ctrl[212] <= {{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};	  
Ctrl[213] <= {4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h3,8'h2d,8'h1};
Ctrl[214] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h1};
Ctrl[215] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h3,8'h1};
Ctrl[216] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h1};
Ctrl[217] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h3,8'h1};
Ctrl[218] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h1};
Ctrl[219] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
Ctrl[220] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h1};
Ctrl[221] <= {4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};
Ctrl[222] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h58,8'h45,8'h1};
Ctrl[223] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h58,8'h45,8'h3,8'h1};
Ctrl[224] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h59,8'h46,8'h1};
Ctrl[225] <= {4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h59,8'h46,8'h3,8'h1};
Ctrl[226] <= {8'hf9,8'ha6,8'h40,32'hffff_fffe,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // clc
Ctrl[227] <= {8'hf9,8'ha6,8'h40,32'h0000_0001,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // stc
Ctrl[228] <= {8'hf9,8'ha6,8'h40,32'hffff_fdff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cli
Ctrl[229] <= {8'hf9,8'ha6,8'h40,32'h0000_0200,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // sti
Ctrl[230] <= {8'hf9,8'ha6,8'h40,32'hffff_fbff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cld
Ctrl[231] <= {8'hf9,8'ha6,8'h40,32'h0000_0400,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // std
Ctrl[232] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h19,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // inc reg low
Ctrl[233] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h39,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // inc reg high	  
Ctrl[234] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h1f,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		 // dec reg low
Ctrl[235] <= {2'b0,modrm[1:0],4'h9,8'hc7,8'h3f,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // dec reg high	  
Ctrl[236] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc Ctrl8
Ctrl[237] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc Ctrl8  	    
Ctrl[238] <= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc Ctrl8  	    
Ctrl[239] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec Ctrl8
Ctrl[240] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec Ctrl8      
Ctrl[241] <= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec Ctrl8      
Ctrl[242] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
Ctrl[243] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};				    
Ctrl[244] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
Ctrl[245] <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};
Ctrl[246] <= {8'h4e,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h2d,8'h4,8'h1,8'hfb,8'hce}; // CALL
Ctrl[247] <= {8'h4e,8'he7,                 {1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h03,8'h4,8'h1,8'hfb,8'hce};   
Ctrl[248] <= {8'h9e,8'h97,{1'b0,opz},4'h0,8'h0,8'hfc,8'he3,8'h28,8'h3,8'h1,8'd4,8'h2d,8'd4,8'h2d,8'h1,8'hfb,8'hce}; // CALLF
Ctrl[249] <= {4'he,{1'b0,modrm[2:0]},8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he1,8'h23,8'h1,8'hce};
Ctrl[250] <= {4'he,             4'he,8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h03,8'h1,8'hce};		  
Ctrl[251] <= {8'h9e,8'ha7,8'h20,64'h0,8'hfc,8'he3,8'b0010_1000,8'h3,8'h1};	  
Ctrl[252] <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,80'h0,8'hff,8'h4,8'h1};
Ctrl[253] <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,72'h0,8'hff,8'h4,8'h3,8'h1};	  



end

endmodule
