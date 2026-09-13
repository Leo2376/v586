/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off PINNOCONNECT */
/* verilator lint_off PINMISSING */
/* verilator lint_off IMPLICIT */
/* verilator lint_off WIDTH */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off COMBDLY */

module udecox ( op , modrm , twobyte, cpl , adz, opz, jsz, udeco, fpu, emul , ipg_fault);

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

wire        modrm_and = modrm[7] & modrm[6];
wire  [8:0] modrm_dec = {modrm[7:6],modrm_and,modrm[5:0]};

assign src = (op[1]==1) ? {{1'b0,modrm[5:3]},{1'b0,modrm[2:0]}} : {{1'b0,modrm[2:0]},{1'b0,modrm[5:3]}};
assign src8= (op[1]==1) ? {{2'b00,modrm[4:3]},{2'b00,modrm[1:0]}} : {{2'b00,modrm[1:0]},{2'b00,modrm[4:3]}};

always @(op or modrm_dec or cpl or adz or opz or jsz or twobyte or fpu or emul or ipg_fault or src8 or src)
begin

//$display("debug : %h",{ipg_fault,fpu,emul,cpl,adz,jsz,opz,twobyte,modrm_dec,op});

casex({ipg_fault,fpu,emul,cpl,adz,jsz,opz,twobyte,modrm_dec,op})
// 1+1+1+2+1+4+3+1+8+8 = 4+2+5+3+1+7+8 = 11+3+9+8 = 31

// page fault
31'b1_x_x_11_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'ha,4'h4,4'hf,4'h6,4'h4,4'h9,4'he,4'hd,8'h0,8'he,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};
31'b1_x_x_10_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h4,4'h4,4'hd,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};
31'b1_x_x_01_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h4,4'h4,4'hd,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};
31'b1_x_x_00_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h4,4'h4,4'hd,4'h0,4'h0,8'h0,8'h0e,8'h0,8'hfc,8'h65,8'h64,8'hc4,32'h0,8'hce};
// fpu
31'b0_1_1_11_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'ha,4'h4,4'hf,4'h5,4'h4,4'h9,4'he,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h68,8'h67,8'h66,16'h0,8'hce};
31'b0_1_1_10_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h00,8'h00,8'h00,16'h0,8'hce};
31'b0_1_1_01_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h00,8'h00,8'h00,16'h0,8'hce};
31'b0_1_1_00_x_xxxx_xxx_x_xx_xxxxxxx_xxxxxxxx : udeco <={4'hf,4'h9,4'he,4'h3,4'h4,4'h0,4'h0,4'h0,8'h0,8'h7,8'hfc,8'h65,8'h64,8'hc4,8'h00,8'h00,8'h00,16'h0,8'hce};
// twobyte
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1010xxx_00000000 : udeco<={1'b0,modrm[2:0],1'b0,modrm[2:0],8'h07,8'h42,80'h0,8'hff,8'h61,8'h1};  // LLDT
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0010xxx_00000000 : udeco<={8'h0,8'h07,8'h40,64'h0,8'hff,8'h61,8'h3,8'h1d,8'h1}; // LLDT
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1011xxx_00000000 : udeco<={1'b0,modrm[5:3],4'h0,8'h07,8'h42,80'h0,8'hff,8'h63,8'h1};  // LTRW
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0011xxx_00000000 : udeco<={8'h0,8'h07,8'h40,72'h0,8'hff,8'h63,8'h3,8'h1}; // LTRW

31'b0_0_x_xx_x_xxxx_xxx_1_xx_0010xxx_00000001 : udeco<={8'h0,8'h07,8'h42,64'h0,8'hff,8'h60,8'h3,8'h1d,8'h1};  // LGDT
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0011xxx_00000001 : udeco<={8'h0,8'h07,8'h42,64'h0,8'hff,8'h62,8'h3,8'h1d,8'h1};  // LIDT
31'b0_0_x_xx_x_xxxx_xxx_1_xx_x111xxx_00000001 : udeco<={8'h0,8'h0,8'h0,24'h0,8'hff,8'h0,8'hc9,8'h0,8'hb5,8'h0,8'hc9,8'h0,8'hb5,8'h1};  // INVLPG 486 , flush all tlb

31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_11000111 : udeco<={8'h0,8'h07,{1'b0,opz},4'h0,40'h0,8'hff,8'hb3,8'hb2,8'hb1,8'h3,8'hb0,8'h3,8'h1}; // CMPXCHG8B

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_0100xxxx : udeco <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,4'b1101,op[3:0],8'h1}; //CMOV
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_0100xxxx : udeco <= {1'b0,modrm[5:3],1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'b0,56'h0,8'h00,8'h00,8'hbc,8'd3,4'b1101,op[3:0],8'h1}; //CMOV

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_00110001 : udeco<={8'h0,8'h0,8'h0,80'h0,8'hff,8'hcd,8'h1}; // RDTSC

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_11001xxx : udeco<={8'h0,1'b0,op[2:0],4'h7,8'h40,72'h0,8'hff,8'he4,8'h4f,8'h1}; // bswap

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10100010 : udeco<={8'h0,8'h07,8'h42,80'h0,8'hff,8'hcc,8'h1}; // CPU ID

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10110001 : udeco<={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,56'h0,8'hff,8'he3,8'hca,8'ha,8'h17,8'h1}; // cmpxchg reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10110001 : udeco<={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'hcb,8'ha,8'h17,8'h3,8'h1}; // cmpxchg word  mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_11000001 : udeco<={{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,48'h0,8'hff,8'he6,8'h2c,8'h2d,8'ha,8'h10,8'h1}; // xadd word
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_11000001 : udeco<={{1'b0,modrm[5:3]},{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz},4'h0,32'h0,8'hff,8'he4,8'h02,8'h2c,8'h2d,8'ha,8'h10,8'h3,8'h1}; // xadd word  mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_00100000 : udeco<={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,72'h0,8'h00,8'hb6,8'h49,8'h1}; // read from cr
31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_00100010 : udeco<={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha6,8'h0,24'h0,8'hff,8'hb5,8'h0,8'hc9,8'h0,8'hb5,8'h0,8'hc9,8'h4a,8'h1}; // write to cr

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_1000xxxx : udeco <={8'hee,8'ha6,{1'b0,opz},4'h0,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx0xx_1001xxxx : udeco <={{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h10,32'h1,16'h0,8'h0,8'hb7,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx1xx_1001xxxx : udeco <={{2'b0,modrm[1:0]},{2'b0,modrm[1:0]},8'ha3,8'h30,32'h1, 8'h0,8'h0,8'hb7,8'h2e,8'h2a,4'b1101,op[3:0],8'he1,8'h16,8'h1}; // setcc Conditionals
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_1001xxxx : udeco <={ 	    4'h0,	      4'h0,8'ha7,8'h10,32'h1,8'h0,8'hff,8'h2,8'h2a,4'b1101,op[3:0],8'h2,8'h2c,8'h16,8'h1}; // setcc Conditionals
      
31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10100000 : udeco<={4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push fs 
31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10100001 : udeco<={4'hd,4'hc,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop fs 


31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10100011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,80'h0,8'hff,8'h5a,8'h1}; //Bit Test reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10100011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,48'h0,8'hff,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; //Bit Test mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10100100 : udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld reg ( x imm )
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10100100 : udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1}; // shld mem ( x imm )

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10100101 : udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h39,8'hc1,8'h2d,8'h1}; // shld reg ( x CL )
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10100101 : udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h39,8'hc1,8'h3,8'h2d,8'h1}; // shld mem ( x CL )

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10101000 : udeco<={4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1}; // push gs
31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10101001 : udeco<={4'hd,4'hd,8'ha1,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1}; // pop gs

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10101011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10101011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; //Bit Test Set mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10101100 : udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd reg ( x imm )
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10101100 : udeco <= {{1'b0,modrm[5:3]},4'h6,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};   // shrd mem ( x imm )

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10101101 : udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'he4,8'h2d,8'ha,8'h38,8'hc1,8'h2d,8'h1};  // shrd reg ( x CL )
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10101101 : udeco <= {{1'b0,modrm[5:3]},4'h1,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2 ,8'ha,8'h38,8'hc1,8'h3,8'h2d,8'h1};   // shrd mem ( x CL )

31'b0_0_x_xx_x_xxxx_010_1_xx_1xxxxxx_10101111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h1};	  // IMUL R RM (word16) reg 
31'b0_0_x_xx_x_xxxx_010_1_xx_0xxxxxx_10101111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1}; // IMUL R RM (word16) mem
31'b0_0_x_xx_x_xxxx_100_1_xx_1xxxxxx_10101111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,56'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h1};	  // IMUL R RM (word32) reg 
31'b0_0_x_xx_x_xxxx_100_1_xx_0xxxxxx_10101111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1}; // IMUL R RM (word32) mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_xxxxxxx_10110010 : udeco<={1'b0,modrm[5:3],1'b0,modrm[5:3],8'h27,8'h40,72'h0,8'h0,8'hb7,8'h03,8'h1}; // LSS

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10110011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10110011 : udeco<= {1'b0,modrm[2:0],1'b0,modrm[5:3],8'h27,{1'b0,opz},4'h0,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; //Bit Test Reset mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx0xx_10110110 : udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1}; // movzx 8b reg low
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx1xx_10110110 : udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h26,8'h1}; // movzx 8b reg high
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10110110 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4d,8'h1e,8'h1};  // movzx 8b mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10110111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4e,8'h1}; // movzx word reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10110111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4e,8'h3,8'h1}; // movzx word mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1100xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,80'h0,8'hff,8'h5a,8'h1}; //Bit Test reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0100xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,32'h0,8'hff,8'hff,8'h2c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1};  //Bit Test mem
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1101xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5c,8'h5a,8'h1}; //Bit Test Set reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0101xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5c,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; //Bit Test Set reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1110xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'h5b,8'h5a,8'h1}; //Bit Test Reset reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0110xxx_10111010 : udeco<= {1'b0,modrm[2:0],4'h6,8'h27,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'h5b,8'h5a,8'h47,8'h3,8'h5d,8'h2d,8'h1}; //Bit Test Reset mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10111100 : udeco<={1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h35,8'hc6,8'h2d,8'h0e,8'h1};	     // Bit Scan forward reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10111100 : udeco<={1'b0,modrm[2:0],4'h9,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h35,8'hc6,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan forward mem
      
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10111101 : udeco<={1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,48'h0,8'hff,8'he4,8'h36,8'hc7,8'h2d,8'h0e,8'h1};	     // Bit Scan reverse reg
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10111101 : udeco<={1'b0,modrm[2:0],4'he,1'b0,modrm[5:3],4'h7,{1'b0,opz},4'h8,32'h0,8'hff,8'he4,8'h36,8'hc7,8'h0e,8'h23,8'h3,8'h2d,8'h1};  // Bit Scan reverse mem

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx0xx_10111110 : udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h2f,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxx1xx_10111110 : udeco<={1'b0,modrm[5:3],2'b0,modrm[1:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h26,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10111110 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h2f,8'h3,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_1_xx_1xxxxxx_10111111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h4c,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_1_xx_0xxxxxx_10111111 : udeco<={1'b0,modrm[5:3],1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'h00,8'h00,8'hbc,8'h4c,8'h3,8'h1};

// One Byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_00xxx000 : udeco<={src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_00xxx010 : udeco<={src8,8'ha6,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx1xx_00xxx000 : udeco<={src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx1xx_00xxx010 : udeco<={src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx0xx_00xxx000 : udeco<={src8,8'ha6,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h26,8'h1};        
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx0xx_00xxx010 : udeco<={src8,8'ha6,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_00xxx000 : udeco<={src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_00xxx010 : udeco<={src8,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h26,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx0xx_00xxx000 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1}; // add/or/adc/sbb/and/sub/xor/cmp r->r, r->m, m->r -byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx0xx_00xxx010 : udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx1xx_00xxx000 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'h1e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx1xx_00xxx010 : udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx0xx_00xxx000 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx0xx_00xxx010 : udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1};			
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx1xx_00xxx000 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h26,8'h47,8'h1e,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx1xx_00xxx010 : udeco<={{2'b00,modrm[4:3]},4'h0,8'ha7,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,op[5:3],8'h2e,8'h1e,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_00xxx0x1 : udeco<= {src,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};  // add/or/adc/sbb/and/sub/xor/cmp r->r, r->m -word
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_00xxx011 : udeco<= {src,8'ha7,{1'b0,opz,4'b0},56'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'd3,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_00xxx001 : udeco<= {src,8'ha7,{1'b0,opz,4'b0},32'h0,8'hff,8'd2,8'h2c,8'ha,5'b0001_0,op[5:3],8'h47,8'd3,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_00xxx100 : udeco<={8'h06,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1}; 	     // add/or/adc/sbb/and/sub/xor/cmp i->al -byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_00xxx101 : udeco<={8'h06,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,op[5:3],8'h1};    // add/or/adc/sbb/and/sub/xor/cmp i->eax/ax -word 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_000xx110 : udeco<={4'h4,{2'b10,op[4:3]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push seg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_000xx111 : udeco<={4'h4,{2'b10,op[4:3]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop seg
      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01000xxx : udeco<={{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // inc word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01001xxx : udeco<={{1'b0,op[2:0]},4'h9,8'hc1,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1}; // dec word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01010xxx : udeco<={4'h4,{1'b0,op[2:0]},8'ha1,{1'b0,opz},4'h0,80'h0,8'hff,8'h4,8'h1};// push reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01011xxx : udeco<={4'h0,{1'b0,op[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};// pop reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01100000 : udeco<={4'h0,4'h1,4'h2,4'h8,{1'b0,opz},4'h3,4'h4,4'h5,4'h6,4'h7,72'h0,8'hff,8'hc4}; // pusha
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01100001 : udeco<={4'h7,4'h6,4'h5,4'h8,{1'b0,opz},4'h4,4'h3,4'h2,4'h1,4'h0,72'h0,8'hff,8'hc5}; // popa
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01101000 : udeco<={8'h06,8'h06,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm	   
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_01101010 : udeco<={8'h08,8'h08,{1'b0,opz},4'h8,80'h0,8'hff,8'h4,8'h1}; // push imm

31'b0_0_x_xx_x_xxxx_010_0_xx_1xxxxxx_01101011 : udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm8 *rm
31'b0_0_x_xx_x_xxxx_010_0_xx_0xxxxxx_01101011 : udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm8 *rm
31'b0_0_x_xx_x_xxxx_100_0_xx_1xxxxxx_01101011 : udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm8 *rm
31'b0_0_x_xx_x_xxxx_100_0_xx_0xxxxxx_01101011 : udeco<={1'b0,modrm[5:3],4'h8,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm8 *rm

31'b0_0_x_xx_x_xxxx_010_0_xx_1xxxxxx_01101001 : udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,48'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h47,8'h1}; // imul word = imm *rm
31'b0_0_x_xx_x_xxxx_010_0_xx_0xxxxxx_01101001 : udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h28,40'h0,8'hb6,8'h3a,8'h55,8'h55,8'h55,8'h03,8'h23,8'h1}; // imul word = imm *rm
31'b0_0_x_xx_x_xxxx_100_0_xx_1xxxxxx_01101001 : udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,48'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h47,8'h1}; // imul dword = imm *rm
31'b0_0_x_xx_x_xxxx_100_0_xx_0xxxxxx_01101001 : udeco<={1'b0,modrm[5:3],4'h6,1'b0,modrm[2:0],4'h7,8'h48,40'h0,8'hb6,8'h3a,8'h56,8'h56,8'h56,8'h03,8'h23,8'h1}; // imul dword = imm *rm

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_0111xxxx : udeco <={4'he,4'h8,8'ha8,{1'b0,opz},4'h8,80'h0,8'hb8,8'h1,4'b1101,op[3:0]}; // Jump Conditionals

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx0xx_100000x0 : udeco <={2'b0,modrm[1:0],4'h6,8'ha6,8'h18,64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1}; // add/or/adc/sbb/and/sub/xor/cmp imm - 8bit r/m <=r+i; reg low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx1xx_100000x0 : udeco <={2'b0,modrm[1:0],4'b0,8'ha6,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b0001_0,modrm[5:3],8'h2b,8'h2e,8'h1}; // add/or/adc/sbb/and/sub/xor/cmp imm - 8bit r/m <=r+i; reg hi
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_100000x0 : udeco <={8'h06,8'ha7,8'h18,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1}; // add/or/adc/sbb/and/sub/xor/cmp imm - 8bit r/m <=r+i; reg mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10000001 : udeco<={1'b0,modrm[2:0],4'h6,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1}; // add/or/adc/sbb/and/sub/xor/cmp imm16/32 - Word
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10000001 : udeco<={8'h06,8'ha7,{1'b0,opz},4'h8,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h47,8'h3,8'h2d,8'h1}; // add/or/adc/sbb/and/sub/xor/cmp imm16/32 - Word

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10000011 : udeco<={1'b0,modrm[2:0],4'h8,8'ha6,{1'b0,opz,4'h8},64'h0,8'h00,8'h0,8'hb9,5'b0001_0,modrm[5:3],8'h1};  // add/or/adc/sbb/and/sub/xor/cmp imm8 - sign extend
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10000011 : udeco<={8'h06,8'ha7,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b0001_0,modrm[5:3],8'h2f,8'h47,8'h3,8'h2d,8'h1};  // add/or/adc/sbb/and/sub/xor/cmp imm8 - sign extend
	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_10000100 : udeco<={src8,8'ha6,8'h10,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; 		  // test r->r, r->m -byte reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx1xx_10000100 : udeco<={src8,8'ha6,8'h30,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	  // test r->r, r->m -byte reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx0xx_10000100 : udeco<={src8,8'ha6,8'h10,64'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h26,8'h1};		  // test r->r, r->m -byte reg     
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_10000100 : udeco<={src8,8'ha6,8'h30,48'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h26,8'h1}; // test r->r, r->m -byte reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xxxxx_10000100 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,48'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h1};	 // test r->r, r->m -byte mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xxxxx_10000100 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h26,8'h47,8'h1e,8'h1}; // test r->r, r->m -byte mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10000101 : udeco<={src,8'ha6,{1'b0,opz},4'h0,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test r->r, r->m -word reg 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10000101 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h0,8'h47,8'h3,8'h1}; // test r->r, r->m -word mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_10000110 : udeco<={4'h0,src8,4'h7,8'h10,72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000100_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};     // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001100_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010100_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1011100_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000101_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001101_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};     // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010101_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1011101_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000110_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001110_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010110_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};     // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1011110_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000111_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001111_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010111_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h40,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1011111_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};     // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1100000_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};	  // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1101000_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110000_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1111000_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1100001_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1101001_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};	  // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110001_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1111001_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1100010_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1101010_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110010_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};	  // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1111010_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1100011_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1101011_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110011_10000110 : udeco<={4'h0,src8,4'h7,8'h20,72'h0,8'hff,8'he6,8'h41,8'h1}; // xchg 8bit reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1111011_10000110 : udeco<={src8,8'h07,8'h20,72'h0,8'h00,8'hb6,8'h2e,8'h1};	  // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_10000110 : udeco<={4'h0,src8,4'h7,8'h30,72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg 8bit reg

31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xxxxx_10000110 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h30,56'h0,8'hff,8'he4,8'h2,8'h41,8'h1e,8'h1}; // xchg 8bit mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xxxxx_10000110 : udeco<={8'h0,{2'b0,modrm[4:3]},4'h7,8'h10,64'h0,8'hff,8'he4,8'h2d,8'h1e,8'h1}; // xchg 8bit mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10000111 : udeco <={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // xchg 8bit mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10000111 : udeco <={4'h0,{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},4'h7,{1'b0,opz,4'b0},56'h0,8'hff,8'he4,8'h2,8'h2d,8'h3,8'h1}; // xchg 8bit mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_100010x1 : udeco <= {src,8'ha6,{1'b0,opz},4'h0,80'h0,8'h00,8'hbc,8'h1};  // xchg 8bit mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001001 : udeco<={src[3:0],src[7:4],8'ha7,{1'b0,opz,4'b0},64'h0,16'h00,8'hb7,8'd3,8'h1};  // xchg 8bit mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001011 : udeco<={src,8'ha7,{1'b0,opz,4'b0},80'h0,8'hff,8'd2,8'h1};  // xchg 8bit mem


31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_100010x1 : udeco <= {src,8'ha6,{1'b0,opz},4'h0,80'h0,8'h00,8'hbc,8'h1};  // mov: r->r, r->m, m->r - word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001001 : udeco<={src,8'ha7,{1'b0,opz,4'b0},80'h0,8'hff,8'd2,8'h1};  // mov: r->r, r->m, m->r - word mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001011 : udeco<={src[3:0],src[7:4],8'ha7,{1'b0,opz,4'b0},64'h0,16'h00,8'hb7,8'd3,8'h1};  // mov: r->r, r->m, m->r - word mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_10001000 : udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};	     // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx0xx_10001010 : udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'h00,8'hbc,8'h1};	     // mov: r->r, r->m, m->r - byte	 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx1xx_10001000 : udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1}; // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xx1xx_10001010 : udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1}; // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx0xx_10001000 : udeco<={src8,8'ha6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0101,8'h1}; // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx0xx_10001010 : udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0100,8'h1}; // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_10001000 : udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};	     // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xx1xx_10001010 : udeco<={src8,8'ha6,8'h30,72'h0,8'h00,8'h00,8'hbc,8'h1};	     // mov: r->r, r->m, m->r - byte

31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx0xx_10001000 : udeco<={src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};  		   // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx0xx_10001010 : udeco<={src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};	   // mov: r->r, r->m, m->r - byte     
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx1xx_10001000 : udeco<={src8,8'ha7,8'h10,80'h0,8'hff,8'd2,8'h1};        // doute     // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_00xx1xx_10001010 : udeco<={src8,8'ha7,8'h10,64'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1};	   // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx0xx_10001000 : udeco<={src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};		   // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx0xx_10001010 : udeco<={src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1}; // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx1xx_10001000 : udeco<={src8,8'ha7,8'h10,72'h0,8'hff,8'd2,8'h26,8'h1};		   // mov: r->r, r->m, m->r - byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_01xx1xx_10001010 : udeco<={src8,8'ha7,8'h30,64'h0,8'h00,8'hb6,8'b0010_0100,8'h1e,8'h1}; // mov: r->r, r->m, m->r - byte

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001100 : udeco <={{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,72'h0,8'h00,8'h00,8'hbc,8'h1}; // mov: s->m, s->r reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001100 : udeco <={{1'b0,modrm[2:0]},{1'b1,modrm[5:3]},8'ha7,8'h20,80'h0,8'hff,8'h2,8'h1};        // mov: s->m, s->r mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001101 : udeco <={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2c,8'h1}; // lea reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001101 : udeco <={{1'b0,modrm[2:0]},{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2b,8'h1}; // lea mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001110 : udeco <={{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h0,8'h1}; // mov: m->s, r->s reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001110 : udeco <={{1'b1,modrm[5:3]},{1'b0,modrm[2:0]},8'ha7,8'h20,64'h0,8'h00,8'hb6,8'b0010_0011,8'h3,8'h1}; // mov: m->s, r->s mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_10001111 : udeco <= {4'h0,{1'b0,modrm[2:0]},8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h5,8'h1};//  pop reg n(on-standard)
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_10001111 : udeco <= {4'h0,{1'b0,modrm[5:3]},8'ha7,{1'b0,opz},4'h0,56'h0,8'hff,8'h2,8'hf,8'hf9,8'h5,8'h1};//  pop mem
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10010xxx : udeco <= {4'ha,{1'b0,op[2:0]},4'h0,{5'b0,opz,4'b0},72'h0,8'hff,8'he6,8'h2d,8'h1}; // nop, xchg acum
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011000 : udeco <= {8'h00,8'h27,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'h2f,8'h1}; // cbw
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011001 : udeco <= {8'h09,8'h27,{1'b0,opz},4'h8,72'h0,8'hff,8'he5,8'h48,8'h1}; // cwd
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011010 : udeco <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'he3,8'h20,8'h27,8'h4,8'h2c,8'h4,8'h1,8'hfb,16'h0,8'hce}; // call different seg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011100 : udeco <= {8'h4f,8'ha1,{1'b0,opz},4'h0,48'h0,8'h00,8'hb6,8'h2,8'hf1,8'h29,8'h18,8'h1};// pushf
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011101 : udeco <= {8'h4f,8'ha0,{1'b0,opz},4'h0,72'h0,8'h0,8'hb7,8'd5,8'h1};// popf

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011110 : udeco <= {8'hf0,8'ha1,8'h10,72'h0,8'h00,8'hb6,8'h25,8'h1}; // sahf
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10011111 : udeco <= {8'h0f,8'ha1,8'h30,72'h0,8'h00,8'hb6,8'h24,8'h1}; // lahf
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10100000 : udeco <= {8'h00,8'ha6,8'h10,72'h0,8'h00,8'hb7,8'h1e,8'h1}; // mov: m->a - 8bit
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10100001 : udeco <= {8'h01,8'ha6,{1'b0,opz},4'h0,64'h0,8'h00,8'h00,8'hbc,8'h03,8'h1}; // mov: m->a -word
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10100010 : udeco <= {8'h10,8'ha6,8'h10,80'h0,8'hff,8'h02,8'h1}; // mov: a->m - 8bit
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10100011 : udeco <= {8'h10,8'ha6,{1'b0,opz},4'h0,80'h0,8'hff,8'h02,8'h1};// mov: a->m -word      

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10100100 : udeco <= {8'h16,8'h7b,	  4'h1,      4'h1,1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'hf2,8'h1,8'hc3}; // movs byte
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10100100 : udeco <= {8'h16,8'h7b,	  4'h1,      4'h1,1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'h1f,8'h1,8'hc3}; // movs byte, faster without when cr0[0]==1

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10100101 : udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'hf2,8'h1,8'hc3}; // movs word/dword	
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10100101 : udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hb,8'h1,8'hbb,8'd9,8'h1,8'hc3}; // movs word/dword, faster without when cr0[0]==1

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10100110 : udeco <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'h1f,8'hf2,8'h1,8'hc3}; // cmps byte
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10100110 : udeco <= {8'h16,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'h1f,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1 

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10100111 : udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,15'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'hf0,8'h47,8'd9,8'hf2,8'h1,8'hc3}; // cmps word
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10100111 : udeco <= {8'h16,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,31'h0,8'hff,8'hb,8'ha,8'h17,8'h9,8'h47,8'd9,8'h1,8'hc3}; // cmps , faster without when cr0[0]==1   
			       
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10101000 : udeco <= {8'h06,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> al
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10101001 : udeco <= {8'h06,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1}; // test i-> ax/eax   
      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10101010 : udeco <= {8'h00,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10101011 : udeco <= {8'h00,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,63'h0,8'hff,8'hbb,8'hd,8'h1,8'hc3}; // stos word/dword

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10101100 : udeco <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'hf2,8'h1,8'hc3}; // lods byte
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10101100 : udeco <= {8'h06,8'h7b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'h1f,8'h1,8'hc3}; // lods byte, faster without when cr0[0]==1  
      
31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10101101 : udeco <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'hf2,8'h1,8'hc3}; // lods word/dword
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10101101 : udeco <= {8'h06,8'h7b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hc,8'he1,8'h23,8'd9,8'h1,8'hc3}; // lods word/dword
			       
31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10101110 : udeco <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'hf0,8'h1,8'hc3}; // scas byte	
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10101110 : udeco <= {8'h07,8'h0b,{ 4'b0001},{ 4'b0001},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'h1f,8'h1,8'hc3}; // scas byte 

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_10101111 : udeco <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,39'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'hf0,8'h1,8'hc3}; // scas word/dword
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_10101111 : udeco <= {8'h07,8'h0b,{1'b0,opz},{1'b0,opz},1'b1,47'h0,8'hff,8'hd,8'ha,8'h17,8'd9,8'h1,8'hc3}; // scas word/dword

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_101100xx : udeco <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h10,72'h0,8'h00,8'hb6,8'b0010_0001,8'h1}; // mov: i->r - byte low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_101101xx : udeco <= {{2'b0,op[1:0]},4'h9,8'hc6,8'h30,72'h0,8'h00,8'hb6,8'b0010_0010,8'h1}; // mov: i->r - byte high
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_10111xxx : udeco <= {{1'b0,op[2:0]},4'h9,8'hc6,{1'b0,opz},4'h0,72'h0,8'h00,8'hb6,8'b0010_0000,8'h1}; // mov: i->r - word
      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx0xx_11000000 : udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // ror/rol/shl/sar/sal/shr  ( x imm ) - 8 bit reg low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx1xx_11000000 : udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h38,32'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h2d,8'h1}; // ror/rol/shl/sar/sal/shr  ( x imm ) - 8 bit reg hi
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11000000 : udeco <= {{2'b00,modrm[1:0]},4'h6,8'h17,8'h18,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h2d,8'h1}; // ror/rol/shl/sar/sal/shr  ( x imm ) - 8 bit reg mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_11000001 : udeco <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,48'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h2d,8'h1}; // ror/rol/shl/sar/sal/shr  ( x imm ) - word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11000001 : udeco <= {{1'b0,modrm[2:0]},4'h6,8'h17,{1'b0,opz},4'h8,24'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h2d,8'h1}; // ror/rol/shl/sar/sal/shr  ( x imm ) - word mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11000010 : udeco <= {8'h4e,8'ha6,{1'b0,opz},{1'b0,opz},32'h0,8'hfc,8'he1,8'h18,8'h1,8'he2,8'h5,8'h1,8'h0,8'hce}; // ret near with value
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11000011 : udeco <= {8'h0e,8'ha6,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h5,8'hce,8'h1}; // ret near 

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11000100 : udeco <= {4'h8,{1'b0,modrm[5:3]},8'h87,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // les 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11000101 : udeco <= {4'hb,{1'b0,modrm[5:3]},8'hb7,{1'b0,opz},4'h0,64'h0,8'hff,8'he3,8'h28,8'h3,8'h1}; // lds 

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11xxxxx_11000110 : udeco <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,64'h0,8'h00,8'h00,8'hbc,8'b0010_0110,8'h1}; // mov: i->m (or i->r non-standard) high byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10xxxxx_11000110 : udeco <= {2'b0,modrm[4:3],4'h6,8'ha7,4'h1,4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1}; // mov: i->m (or i->r non-standard) low byte
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11000110 : udeco <= {1'b0,modrm[5:3],4'h6,8'ha7,4'h1,4'h8,80'h0,8'hff,8'h2,8'h1}; // mov: i->m (or i->r non-standard) mem byte

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_11000111 : udeco <= {1'b0,modrm[2:0],4'h6,8'ha7,{1'b0,opz},4'h8,72'h0,8'h00,8'h00,8'hbc,8'h1}; // mov: i->m (or i->r non-standard) reg word
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11000111 : udeco <= {1'b0,modrm[5:3],4'h6,8'ha7,{1'b0,opz},4'h8,80'h0,8'hff,8'h2,8'h1}; // mov: i->m (or i->r non-standard) reg word
 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001001 : udeco <= {8'h45,8'h67,{1'b0,opz},4'h0,56'h0,8'h0,8'hb7,8'h5,8'he1,8'h23,8'h1}; // leave

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001010 : udeco <= {8'h49,8'he6,{1'b0,opz},{1'b0,opz},16'h0,8'hfc,8'he1,8'h18,8'h1,8'he6,8'd5,8'h2d,8'd5,8'h1,8'h0,8'hce}; // ret far with value
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001011 : udeco <= {8'he9,8'he6,{1'b0,opz},{1'b0,opz},40'h0,8'hfc,8'he3,8'd5,8'h23,8'd5,8'h1,8'h0,8'hce}; // ret far
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001100 : udeco <= {8'h9e,8'hfb,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int 3

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_11001101 : udeco <= {8'h9e,8'hf6,{1'b0,opz},4'h3,8'h0,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb}; // int
31'b0_0_x_11_1_xxxx_xxx_0_xx_xxxxxxx_11001101 : udeco <= {4'ha,4'h4,4'hf,4'h5,{1'b0,opz},4'h9,4'he,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'h68,8'h67,8'h66,8'hfb,8'h0,8'hce}; // int idt protected user cpl3
31'b0_0_x_00_1_xxxx_xxx_0_xx_xxxxxxx_11001101 : udeco <= {4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected kernel cpl0
31'b0_0_x_01_1_xxxx_xxx_0_xx_xxxxxxx_11001101 : udeco <= {4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected kernel cpl0
31'b0_0_x_10_1_xxxx_xxx_0_xx_xxxxxxx_11001101 : udeco <= {4'hf,4'h9,4'he,4'h3,{1'b0,opz},4'h0,4'h0,4'h0,8'h0,modrm,8'hfc,8'h65,8'h69,8'hc4,8'hfb,32'h0,8'hce}; // int idt protected kernel cpl0

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001110 : udeco <= {8'h9e,8'hfb,{1'b0,opz},4'h4,8'hfe,8'he3,8'h28,8'd8,8'd4,8'h2d,8'd4,8'h2c,8'd4,8'h2d,8'h1,8'hfb,8'hd0}; // into  	 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11001111 : udeco <= {4'he,4'h9,4'hf,4'h3,{1'b0,opz},4'h4,4'ha,4'h0,24'h0,8'hfc,8'hc9,8'h0,8'hc5,8'h0,8'hb5,8'h0,8'hc9,8'hce}; // iret
      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx0xx_11001111 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1}; // 8 bit reg low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx1xx_11001111 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'h2e,8'h1}; // 8 bit reg high
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11001111 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h1e,8'h1}; // 8 bit mem
      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_11001111 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1};  // word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11001111 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h3,8'h1}; // word mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx0xx_11010000 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1}; // 8 bit reg low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx1xx_11010000 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,48'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'h2e,8'h1}; // 8 bit reg high
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11010000 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h1e,8'h1}; // 8 bit mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_11010001 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,64'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'h1};  // word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11010001 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'ha7,{1'b0,opz},4'h0,40'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'h23,8'h3,8'h1}; // word mem   

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx0xx_11010010 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // ror/rol/shl/sar/sal/shr  ( xCL ) 8 bit reg low
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxx1xx_11010010 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h30,40'h0,8'h00,8'h0,8'hb9,8'h2e,5'b00110,modrm[5:3],8'hc1,8'h2e,8'h1}; // ror/rol/shl/sar/sal/shr  ( xCL ) 8 bit reg high
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11010010 : udeco <= {{2'b00,modrm[1:0]},4'h1,8'h17,8'h10,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h1e,8'h1}; // ror/rol/shl/sar/sal/shr  ( xCL ) 8 bit mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1xxxxxx_11010011 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,56'h0,8'h00,8'h0,8'hb9,5'b00110,modrm[5:3],8'hc1,8'h1}; // word reg
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0xxxxxx_11010011 : udeco <= {{1'b0,modrm[2:0]},4'h1,8'h17,{1'b0,opz},4'h0,32'h0,8'hff,8'h2,8'h2c,8'ha,5'b00110,modrm[5:3],8'hc1,8'h23,8'h3,8'h1}; // word mem

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11010111 : udeco <= {8'h03,8'ha6,8'h10,56'h0,8'h00,8'h00,8'hbc,8'h1e,8'h1c,8'h1}; // mov: m->a - 8bit // xlat

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100000 : udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf7,8'he2,8'h19,8'h1,8'hce};// loopne
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100001 : udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf6,8'he2,8'h19,8'h1,8'hce};// loope
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100010 : udeco <= {8'he1,8'ha8,jsz,4'h7,40'h0,8'hfd,8'he1,8'h18,8'hf5,8'he2,8'h19,8'h1,8'hce};// loop
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100011 : udeco <= {8'he1,8'ha8,jsz,4'h0,56'h0,8'hfd,8'he1,8'h18,8'hf8,8'h1,8'hce};// jcxz  
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100100 : udeco <= {8'h0a,8'h66,4'h1,4'h8,56'h0,8'h00,8'h0,8'h0,8'hb6,8'h7,8'h1}; // in imm 8b
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100101 : udeco <= {8'h0a,8'h66,{1'b0,opz},4'h8,56'h0,8'h00,8'h0,8'h0,8'hb6,8'h7,8'h1}; // in imm 16b/32b
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100110 : udeco <= {8'h0a,8'h66,4'h1,4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 8b	       
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11100111 : udeco <= {8'h0a,8'h66,{1'b0,opz},4'h8,80'h0,8'hff,8'h6,8'h1}; // out imm 32b	

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_11101000 : udeco <= {8'hee,8'ha6,8'h20,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_11101000 : udeco <= {8'hee,8'ha6,8'h40,40'h0,8'hfc,8'he1,8'h10,8'h2b,8'h4,8'h1,8'hfb,8'hce}; // call same segment

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101001 : udeco <= {4'he,4'h6,8'ha6,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101011 : udeco <= {4'he,4'h8,8'ha8,jsz,4'h8,64'h0,8'hfd,8'he1,8'h10,8'hce,8'h1};// jmp direct

31'b0_0_x_xx_0_xxxx_xxx_0_xx_xxxxxxx_11101010 : udeco <= {8'he9,8'ha6,8'h20,8'h0,8'hfc,8'hcf,8'he3,8'h27,8'h20,8'h1,40'h0,8'hce}; // jmp indirect different segment
31'b0_0_x_xx_1_xxxx_xxx_0_xx_xxxxxxx_11101010 : udeco <= {8'he9,8'ha6,8'h40,8'h0,8'hfc,8'hcf,8'he3,8'h4b,8'h20,8'h1,40'h0,8'hce};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101100 : udeco <= {8'h02,8'h66,4'h1,4'h0,56'h0,8'h00,8'h0,8'h0,8'hb6,8'h7,8'h1}; // in dx 8b 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101101 : udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,56'h0,8'h00,8'h0,8'h0,8'hb6,8'h7,8'h1}; // in dx 32b
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101110 : udeco <= {8'h02,8'h66,4'h1,4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 8b	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11101111 : udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,80'h0,8'hff,8'h6,8'h1}; // out dx 32b      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11110100 : udeco <= {8'h02,8'h66,{1'b0,opz},4'h0,32'h0,8'hff,8'h00,8'h0,48'h0}; // hlt
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11110101 : udeco <= {8'hf9,8'ha6,8'h40,32'h1,32'h0,8'h00,8'hb6,8'b0001_0110,8'b0010_1010,8'h1};  // cmc

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10000xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10001xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};  
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0000xxx_11110110 : udeco<={4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10010xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h18,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10011xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h6,8'ha6,8'h38,56'h0,8'h0,8'hba,8'h2e,5'b0001_0,3'b100,8'h2e,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0001xxx_11110110 : udeco<={4'h0,4'h6,4'h0,4'h7,8'h18,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h1e,8'h2d,8'h1};    

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10100xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h1f,72'h0,8'h00,8'hb6,8'h16,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10101xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h3f,72'h0,8'h00,8'hb6,8'h16,8'h1};   
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0010xxx_11110110 : udeco<={4'h0,4'h9,4'h0,4'h7,8'h1f,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h1e,8'h2d,8'h1};	 

31'b0_0_x_xx_x_xxxx_xxx_0_xx_10110xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h18,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_10111xx_11110110 : udeco<={{2'b0,modrm[1:0]},4'h9,8'ha9,8'h38,48'h0,8'h0,8'hba,8'he1,8'h2e,8'hb4,8'h2e,8'h1}; 
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0011xxx_11110110 : udeco<={4'h0,4'h9,4'h0,4'h7,8'h1f,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h1e,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11000xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11001xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h26,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0100xxx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h50,8'h50,8'h50,8'h1e,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11010xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,56'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11011xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h26,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0101xxx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'hb6,8'h3a,8'h54,8'h54,8'h54,8'h1e,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11100xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11101xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h26,8'h1};  
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0110xxx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h58,8'h43,8'h1e,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_11110xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,48'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_11111xx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h26,8'h1};	
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0111xxx_11110110 : udeco<={4'h0,2'b0,modrm[1:0],8'h27,8'h20,40'h0,8'h00,8'hb6,8'h24,8'h2d,8'h59,8'h44,8'h1e,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000xxx_11110111 : udeco<={{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0000xxx_11110111 : udeco<={4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001xxx_11110111 : udeco<={{1'b0,modrm[2:0]},4'h6,8'ha6,{1'b0,opz},4'h8,72'h0,8'h0,8'hba,5'b0001_0,3'b100,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0001xxx_11110111 : udeco<={4'h0,4'h6,4'h0,4'h7,{1'b0,opz},4'h8,40'h0,8'hff,8'h2c,8'ha,5'b0001_0,3'b100,8'h47,8'h3,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010xxx_11110111 : udeco<={{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,72'h0,8'h00,8'hb6,8'h16,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0010xxx_11110111 : udeco<={4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,40'h0,8'hff,8'h2,8'h2c,8'h16,8'h47,8'h3,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1011xxx_11110111 : udeco<={{1'b0,modrm[2:0]},4'h9,8'ha9,{1'b0,opz},4'hf,64'h0,8'h0,8'hba,8'he1,8'hb4,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0011xxx_11110111 : udeco<={4'h0,4'h9,4'h0,4'h7,{1'b0,opz},4'hf,32'h0,8'h0,8'hba,8'h2,8'h2c,8'hb4,8'h47,8'h3,8'h2d,8'h1};

31'b0_0_x_xx_x_xxxx_010_0_xx_1100xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h1};
31'b0_0_x_xx_x_xxxx_010_0_xx_0100xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h51,8'h51,8'h51,8'h3,8'h1};
31'b0_0_x_xx_x_xxxx_100_0_xx_1100xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h1};
31'b0_0_x_xx_x_xxxx_100_0_xx_0100xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h52,8'h52,8'h52,8'h3,8'h1};

31'b0_0_x_xx_x_xxxx_010_0_xx_1101xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,48'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h1};
31'b0_0_x_xx_x_xxxx_010_0_xx_0101xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h20,40'h0,8'hff,8'he5,8'h3a,8'h55,8'h55,8'h55,8'h3,8'h1};
31'b0_0_x_xx_x_xxxx_100_0_xx_1101xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,48'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h1};
31'b0_0_x_xx_x_xxxx_100_0_xx_0101xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,8'h40,40'h0,8'hff,8'he5,8'h3a,8'h56,8'h56,8'h56,8'h3,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h58,8'h45,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0110xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h58,8'h45,8'h3,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1111xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,64'h0,8'hff,8'he5,8'h59,8'h46,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0111xxx_11110111 : udeco<={4'h0,1'b0,modrm[2:0],8'h27,{1'b0,opz},4'h0,56'h0,8'hff,8'he5,8'h59,8'h46,8'h3,8'h1};

31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111000 : udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fffe,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // clc
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111001 : udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0001,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // stc
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111010 : udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fdff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cli
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111011 : udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0200,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // sti
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111100 : udeco <= {8'hf9,8'ha6,8'h40,32'hffff_fbff,32'h0,8'h00,8'hb6,8'b0001_0100,8'b0010_1010,8'h1};  // cld
31'b0_0_x_xx_x_xxxx_xxx_0_xx_xxxxxxx_11111101 : udeco <= {8'hf9,8'ha6,8'h40,32'h0000_0400,32'h0,8'h00,8'hb6,8'b0001_0001,8'b0010_1010,8'h1};  // std

31'b0_0_x_xx_x_xxxx_xxx_0_11_x0000xx_11111110 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h19,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		   // inc reg low
31'b0_0_x_xx_x_xxxx_xxx_0_11_x0001xx_11111110 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h39,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // inc reg high
31'b0_0_x_xx_x_xxxx_xxx_0_11_x0010xx_11111110 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h1f,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};		   // dec reg low
31'b0_0_x_xx_x_xxxx_xxx_0_11_x0011xx_11111110 : udeco<= {2'b0,modrm[1:0],4'h9,8'hc7,8'h3f,48'h0,8'h00,8'h0,8'hb9,8'h2e,8'h10,8'h2e,8'h1};  // dec reg high
31'b0_0_x_xx_x_xxxx_xxx_0_01_x000xxx_11111110 : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8
31'b0_0_x_xx_x_xxxx_xxx_0_10_x000xxx_11111110 : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8	      
31'b0_0_x_xx_x_xxxx_xxx_0_00_x000xxx_11111110 : udeco<= {8'h9,8'ha7,8'h19,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // inc mem8	      
31'b0_0_x_xx_x_xxxx_xxx_0_01_x001xxx_11111110 : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8
31'b0_0_x_xx_x_xxxx_xxx_0_10_x001xxx_11111110 : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      
31'b0_0_x_xx_x_xxxx_xxx_0_00_x001xxx_11111110 : udeco<= {8'h9,8'ha7,8'h1f,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h1e,8'h2d,8'h1}; // dec mem8      

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1000xxx_11111111 : udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0000xxx_11111111 : udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'h9,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1001xxx_11111111 : udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,64'h0,8'h00,8'h0,8'hb9,8'h10,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0001xxx_11111111 : udeco <= {1'b0,modrm[2:0],4'h9,8'ha7,{1'b0,opz},4'hf,32'h0,8'hff,8'h2,8'h2c,8'ha,8'h10,8'h47,8'h3,8'h2d,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1010xxx_11111111 : udeco <= {8'h4e,{1'b0,modrm[2:0]},4'h7,{1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h2d,8'h4,8'h1,8'hfb,8'hce}; // CALL
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0010xxx_11111111 : udeco <= {8'h4e,8'he7,  	       {1'b0,opz},4'h0,48'h0,8'hfc,8'he2,8'h03,8'h4,8'h1,8'hfb,8'hce};    
      	  
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0011xxx_11111111 : udeco <= {8'h9e,8'h97,{1'b0,opz},4'h0,8'h0,8'hfc,8'he3,8'h28,8'h3,8'h1,8'd4,8'h2d,8'd4,8'h2d,8'h1,8'hfb,8'hce}; // CALLF
	      
31'b0_0_x_xx_x_xxxx_xxx_0_xx_1100xxx_11111111 : udeco <= {4'he,{1'b0,modrm[2:0]},8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he1,8'h23,8'h1,8'hce};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0100xxx_11111111 : udeco <= {4'he, 	    4'he,8'ha7,{1'b0,opz},4'h0,64'h0,8'hfc,8'he2,8'h03,8'h1,8'hce};      

31'b0_0_x_xx_x_xxxx_xxx_0_xx_0101xxx_11111111 : udeco <= {8'h9e,8'ha7,8'h20,64'h0,8'hfc,8'he3,8'b0010_1000,8'h3,8'h1};	  

31'b0_0_x_xx_x_xxxx_xxx_0_xx_1110xxx_11111111 : udeco <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,80'h0,8'hff,8'h4,8'h1};
31'b0_0_x_xx_x_xxxx_xxx_0_xx_0110xxx_11111111 : udeco <= {4'h0,1'b0,modrm[2:0],8'ha7,{1'b0,opz},4'h9,72'h0,8'hff,8'h4,8'h3,8'h1};

default : udeco<=128'hffff_ffff_ffff_ffff_ffff_ffff_ff01_0101;

endcase
end

endmodule
