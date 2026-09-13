/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */

module cmp14 ( ina, inb , out , out2);

input [13:0] ina,inb;
output out,out2;

assign out2 = (ina[9:0] == inb[9:0]) ? 1'b1 : 1'b0;

assign out = ( (ina[13]== 1'b0 ) &&
               (out2   == 1'b1 ) && 
	       ((ina[10]==1) | (ina[10]|inb[10]==0)) &&
	      (((ina[12]==1) && (inb[10]==1)) || (inb[10]==0) || ((inb[12]==1) && (inb[10]==1)) )
	     ) ? 1'b1 : 1'b0;


endmodule
