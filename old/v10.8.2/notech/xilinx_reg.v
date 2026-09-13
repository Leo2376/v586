module notech_reg (CP,CD,D,Q);
input CP,CD,D;
output Q;

FDRE u1 (.C(CP) , .R(~CD), .D(D), .Q(Q) , .CE(1'b1) );

endmodule
