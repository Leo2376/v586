/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
/* verilator lint_off COMBDLY */

module deco_rm (in8,indic);

input [7:0] in8;
output reg [7:0] indic;

always @(in8) casex (in8) 8'bxxxxx100 : indic[ 0] <= 1; default : indic[ 0] <= 0; endcase
always @(in8) casex (in8) 8'b11xxxxxx : indic[ 1] <= 0; default : indic[ 1] <= 1; endcase  
always @(in8) casex (in8) 8'b00xxx101 : indic[ 2] <= 1; default : indic[ 2] <= 0; endcase
always @(in8) casex (in8) 8'b10xxxxxx : indic[ 3] <= 1; default : indic[ 3] <= 0; endcase  
always @(in8) casex (in8) 8'b01xxxxxx : indic[ 4] <= 1; default : indic[ 4] <= 0; endcase  
always @(in8) casex (in8) 8'bxx00xxxx : indic[ 5] <= 1; default : indic[ 5] <= 0; endcase  
always @(in8) casex (in8) 8'b00xxx110 : indic[ 6] <= 1; default : indic[ 6] <= 0; endcase  

always @(in8) casex (in8) 8'b00xxxxxx : indic[ 7] <= 1; default : indic[ 7] <= 0; endcase  

endmodule
