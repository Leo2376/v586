module tb_udeco();

wire [127:0] udeco,udecox;
reg [30:0] ad;
reg [7:0] modrm,op;
reg twobyte;

udeco i_udeco ( 
.op(ad[7:0]) , 
.modrm(ad[15:8]), 
.twobyte(ad[16]), 
.adz(ad[17]), 
.opz(ad[18]?3'b010:3'b100), 

.cpl(ad[20:19]), 
.jsz(ad[24]?4'b0010:4'b0100), 
.fpu(ad[21]), 
.emul(ad[22]), 
.ipg_fault(ad[23]),

.udeco(udeco)
);

udecox i_udecox ( 
.op(ad[7:0]) , 
.modrm(ad[15:8]), 
.twobyte(ad[16]), 
.adz(ad[17]), 
.opz(ad[18]?3'b010:3'b100), 

.cpl(ad[20:19]), 
.jsz(ad[24]?4'b0010:4'b0100), 
.fpu(ad[21]), 
.emul(ad[22]), 
.ipg_fault(ad[23]),

.udeco(udecox)
);

initial
begin
ad =0;
op =0;
twobyte = 0;
modrm=0;
#10
while (ad != 25'h1ffffff)
 begin
  if (udeco != udecox) $display("difference %h %h %h ",ad,udecox,udeco);
  //if (udeco == udecox) $display("identiques %h %h %h ",ad,udecox,udeco);
  #10 ad = ad + 1;
  #10 ad = ad;
 end

end


endmodule
