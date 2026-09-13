/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off COMBDLY */

module deco8 (in8,indic);

input [7:0] in8;
output reg [72:0] indic;

always @(in8) casex (in8) 8'b111100xx : indic[ 0] <= 1; default : indic[ 0] <= 0; endcase
always @(in8) casex (in8) 8'b011001xx : indic[ 1] <= 1; default : indic[ 1] <= 0; endcase
always @(in8) casex (in8) 8'b001x1110 : indic[ 2] <= 1; default : indic[ 2] <= 0; endcase
always @(in8) casex (in8) 8'b001x0110 : indic[ 3] <= 1; default : indic[ 3] <= 0; endcase 	    
always @(in8) casex (in8) 8'b00xxx0xx : indic[ 4] <= 1; default : indic[ 4] <= 0; endcase 	    
always @(in8) casex (in8) 8'b0110x0xx : indic[ 5] <= 1; default : indic[ 5] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxx0x1x : indic[ 6] <= 1; default : indic[ 6] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxx1xx1 : indic[ 7] <= 1; default : indic[ 7] <= 0; endcase 	    
always @(in8) casex (in8) 8'b1000xxxx : indic[ 8] <= 1; default : indic[ 8] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11000xxx : indic[ 9] <= 1; default : indic[ 9] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxx001x : indic[10] <= 0; default : indic[10] <= 1; endcase 	    
always @(in8) casex (in8) 8'b110100xx : indic[11] <= 1; default : indic[11] <= 0; endcase 	    
always @(in8) casex (in8) 8'b1111x11x : indic[12] <= 1; default : indic[12] <= 0; endcase 	    
always @(in8) casex (in8) 8'b0000xxxx : indic[13] <= 1; default : indic[13] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxx00xx : indic[14] <= 0; default : indic[14] <= 1; endcase 	    
always @(in8) casex (in8) 8'bxxxx11x1 : indic[15] <= 0; default : indic[15] <= 1; endcase 	    
always @(in8) casex (in8) 8'b0011xxxx : indic[16] <= 1; default : indic[16] <= 0; endcase 	    
always @(in8) casex (in8) 8'b01110111 : indic[17] <= 1; default : indic[17] <= 0; endcase 	    
always @(in8) casex (in8) 8'b1010xxxx : indic[18] <= 1; default : indic[18] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxxx00x : indic[19] <= 1; default : indic[19] <= 0; endcase 
always @(in8) casex (in8) 8'bxxxxx010 : indic[60] <= 1; default : indic[60] <= 0; endcase  	    
always @(in8) casex (in8) 8'b11001xxx : indic[20] <= 1; default : indic[20] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxxxxx100 : indic[21] <= 1; default : indic[21] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11xxxxxx : indic[22] <= 0; default : indic[22] <= 1; endcase 	    
always @(in8) casex (in8) 8'b00xxx1x1 : indic[23] <= 1; default : indic[23] <= 0; endcase 	    
always @(in8) casex (in8) 8'b01xxxxxx : indic[24] <= 1; default : indic[24] <= 0; endcase 	    
always @(in8) casex (in8) 8'b10xxxxxx : indic[25] <= 1; default : indic[25] <= 0; endcase 	    
always @(in8) casex (in8) 8'b00xxx100 : indic[26] <= 1; default : indic[26] <= 0; endcase 	    
always @(in8) casex (in8) 8'b0110101x : indic[27] <= 1; default : indic[27] <= 0; endcase 	    
always @(in8) casex (in8) 8'b0111xxxx : indic[28] <= 1; default : indic[28] <= 0; endcase 	    
always @(in8) casex (in8) 8'b10000000 : indic[29] <= 1; default : indic[29] <= 0; endcase 	    
always @(in8) casex (in8) 8'b10000011 : indic[30] <= 1; default : indic[30] <= 0; endcase 	    

//always @(in8) casex (in8) 8'b101000x0 : indic[31] <= 1; default : indic[31] <= 0; endcase 	    
always @(in8) casex (in8) 8'b101000x0 : indic[31] <= 0; default : indic[31] <= 0; endcase 	    

always @(in8) casex (in8) 8'b10101000 : indic[32] <= 1; default : indic[32] <= 0; endcase 	    
always @(in8) casex (in8) 8'b10110xxx : indic[33] <= 1; default : indic[33] <= 0; endcase 	    
always @(in8) casex (in8) 8'b1100000x : indic[34] <= 1; default : indic[34] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11000110 : indic[35] <= 1; default : indic[35] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11001101 : indic[36] <= 1; default : indic[36] <= 0; endcase 	    
always @(in8) casex (in8) 8'b1101010x : indic[37] <= 1; default : indic[37] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11100xxx : indic[38] <= 1; default : indic[38] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11101011 : indic[39] <= 1; default : indic[39] <= 0; endcase 	    
always @(in8) casex (in8) 8'b11110110 : indic[40] <= 1; default : indic[40] <= 0; endcase 	    
always @(in8) casex (in8) 8'bxx11xxxx : indic[41] <= 1; default : indic[41] <= 0; endcase  
always @(in8) casex (in8) 8'b1100x010 : indic[42] <= 1; default : indic[42] <= 0; endcase  
always @(in8) casex (in8) 8'b100000xx : indic[43] <= 1; default : indic[43] <= 0; endcase  
always @(in8) casex (in8) 8'b00xxx101 : indic[44] <= 1; default : indic[44] <= 0; endcase  
always @(in8) casex (in8) 8'b10111xxx : indic[45] <= 1; default : indic[45] <= 0; endcase  
always @(in8) casex (in8) 8'b1110100x : indic[46] <= 1; default : indic[46] <= 0; endcase  
always @(in8) casex (in8) 8'b0110100x : indic[47] <= 1; default : indic[47] <= 0; endcase  
always @(in8) casex (in8) 8'b101000xx : indic[48] <= 1; default : indic[48] <= 0; endcase  
always @(in8) casex (in8) 8'b101x100x : indic[49] <= 1; default : indic[49] <= 0; endcase  
always @(in8) casex (in8) 8'b11000111 : indic[50] <= 1; default : indic[50] <= 0; endcase  
always @(in8) casex (in8) 8'b11110111 : indic[51] <= 1; default : indic[51] <= 0; endcase  
always @(in8) casex (in8) 8'bxx11xxxx : indic[52] <= 1; default : indic[52] <= 0; endcase  
always @(in8) casex (in8) 8'b10111010 : indic[53] <= 1; default : indic[53] <= 0; endcase  
always @(in8) casex (in8) 8'b00001111 : indic[54] <= 1; default : indic[54] <= 0; endcase  
always @(in8) casex (in8) 8'b01110000 : indic[55] <= 1; default : indic[55] <= 0; endcase  
always @(in8) casex (in8) 8'b10100100 : indic[56] <= 1; default : indic[56] <= 0; endcase  
always @(in8) casex (in8) 8'b11000010 : indic[57] <= 1; default : indic[57] <= 0; endcase  
always @(in8) casex (in8) 8'b11000100 : indic[58] <= 1; default : indic[58] <= 0; endcase  
always @(in8) casex (in8) 8'b11000101 : indic[59] <= 1; default : indic[59] <= 0; endcase  
//always @(in8) casex (in8) 8'b11000110 : indic[60] <= 1; default : indic[60] <= 0; endcase  
always @(in8) casex (in8) 8'b11011xxx : indic[61] <= 1; default : indic[61] <= 0; endcase  
always @(in8) casex (in8) 8'b01100110 : indic[62] <= 1; default : indic[62] <= 0; endcase  
always @(in8) casex (in8) 8'b1111001x : indic[63] <= 1; default : indic[63] <= 0; endcase  //prefix F2/F3 repe/repne
always @(in8) casex (in8) 8'b11101010 : indic[64] <= 1; default : indic[64] <= 0; endcase  //jump far
always @(in8) casex (in8) 8'b11000111 : indic[65] <= 1; default : indic[65] <= 0; endcase  //mov imm,mem w
always @(in8) casex (in8) 8'b11000110 : indic[66] <= 1; default : indic[66] <= 0; endcase  //mov imm,mem b
always @(in8) casex (in8) 8'b01100111 : indic[67] <= 1; default : indic[67] <= 0; endcase  //db67
always @(in8) casex (in8) 8'b10011010 : indic[68] <= 1; default : indic[68] <= 0; endcase  //call far

always @(in8) casex (in8) 8'b00000001 : indic[69] <= 1; default : indic[69] <= 0; endcase  //lgdt
always @(in8) casex (in8) 8'b1010x100 : indic[70] <= 1; default : indic[70] <= 0; endcase  //shld/shrd
always @(in8) casex (in8) 8'b10000010 : indic[71] <= 1; default : indic[71] <= 0; endcase  // 82h has also imm8  
always @(in8) casex (in8) 8'b10110010 : indic[72] <= 1; default : indic[72] <= 0; endcase  // LSS  


endmodule
