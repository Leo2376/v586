module datacache (A,D,Q,WEN,clk);
input [9:0] A;
input [128+22-1:0] D;
output reg [128+22-1:0] Q;
input clk;
input WEN;
reg [128+22-1:0] Mem [1023:0];
always @(posedge clk) Q <= Mem[A];
always @(posedge clk) if (WEN ==0) Mem[A] <= D;
endmodule
