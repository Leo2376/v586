module notech_reg_set (CP,SD,D,Q);
input CP,SD,D;
output Q;
FDSE u1 (.C(CP) , .S(~SD), .D(D), .Q(Q) , .CE(1'b1) );
endmodule

