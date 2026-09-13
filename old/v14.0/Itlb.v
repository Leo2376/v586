module Itlb (clk,rstn,addr_phys,cr3,cr0,data_miss,iDaddr,pg_en,iwrite_data,owrite_data,
iread_req,iread_ack,iwrite_req,iwrite_ack,iread_sz,oread_sz,
oread_req,oread_ack,owrite_req,owrite_ack, 
pg_fault, wr_fault, cr2, flush_tlb, cs, pt_fault , busy_ram
);

input         clk,rstn;
output [31:0] addr_phys,owrite_data;
input  [31:0] iDaddr,data_miss,iwrite_data;
input  [31:0] cr3,cr0,cs;
input         iread_req,iread_ack,iwrite_req,iwrite_ack;
output        oread_req,oread_ack,owrite_req,owrite_ack;
input         pg_en,flush_tlb;
output reg    pg_fault;
output reg    wr_fault;
output reg    pt_fault;
output reg [31:0] cr2;
input             busy_ram;
input       [1:0] iread_sz;
output      [1:0] oread_sz;

wire ack_miss;
reg  req_miss;
wire  [9:0] directory;
wire  [9:0] tables;
wire        hit,hit_dir,hit_dir1,hit_dir2;
wire        hit_tab11,hit_tab12,hit_tab13,hit_tab14;
wire        hit_tab21,hit_tab22,hit_tab23,hit_tab24;
wire        hit_tab1,hit_tab2,hit_tab;
reg  [33:0] dir1,dir2;
reg  [33:0] tab11,tab12,tab13,tab14;
reg  [33:0] tab21,tab22,tab23,tab24;
reg   [1:0] nx_dir;
reg   [2:0] nx_tab1,nx_tab2,nnx_tab1,nnx_tab2;
wire [19:0] tab_mux1,tab_mux2;
wire [19:0] dir_mux;
reg   [3:0] fsm;
wire [31:0] base;
reg  [31:0] addr_miss,wrD,wrA,iDaddr_f;
wire [19:0] addr_virt;
reg   [8:0] fsm5_cnt;
wire        WPsp;
wire        hit_add11,hit_add12,hit_add13,hit_add14,
            hit_add21,hit_add22,hit_add23,hit_add24;
reg         hit_adr11,hit_adr12,hit_adr13,hit_adr14,
            hit_adr21,hit_adr22,hit_adr23,hit_adr24;
    
assign WPsp      = ({cr0[16],cs[1:0]}==3'b000) ? 1'b1: 1'b0;
assign addr_virt = (fsm ==0) ? iDaddr[31:12] : iDaddr_f[31:12];
assign ack_miss  = iread_ack;
assign base      = cr3;
assign directory = addr_virt[19:10];
assign tables    = addr_virt[9:0];
assign hit_dir   = hit_dir1 | hit_dir2;
assign hit_tab1  = hit_tab11|hit_tab12|hit_tab13|hit_tab14 ;
assign hit_tab2  = hit_tab21|hit_tab22|hit_tab23|hit_tab24 ;
assign hit_tab   = hit_tab1 |hit_tab2;
assign oread_req = (pg_en == 0) ? iread_req  : ( req_miss | (iread_req  & (fsm == 0) & (hit  == 1) ));
assign oread_ack = (pg_en == 0) ? iread_ack  :              (iread_ack  & (fsm == 0) & (hit  == 1) ) ;
assign owrite_req= (pg_en == 0) ? iwrite_req :             ((iwrite_req & (fsm == 0) & (hit  == 1) )|((fsm == 6)|(fsm==7))) ;
assign owrite_ack= (pg_en == 0) ? iwrite_ack :              (iwrite_ack & (fsm == 0) & (hit  == 1) ) ;
assign addr_phys = (pg_en == 0) ? iDaddr : 
                  ((fsm == 6)||(fsm==7)) ? wrA :
                  ((hit   == 1)&~((fsm == 6)|(fsm==7))) ? {dir_mux,iDaddr[11:0]} : 
		                  addr_miss;

assign oread_sz  = (pg_en == 0) ? iread_sz   : 
                  ((fsm == 0) & (hit == 1) ) ? iread_sz : 2'b10 ;
				  
assign owrite_data = ((fsm == 6)|(fsm == 7)) ? wrD : iwrite_data;

cmp14 d1  (.ina({dir1 [33:30],dir1 [9:0]}), .inb({1'b0,1'b0,iread_req|iwrite_req,      1'b0,directory}), .out(hit_dir1) );
cmp14 d2  (.ina({dir2 [33:30],dir2 [9:0]}), .inb({1'b0,1'b0,iread_req|iwrite_req,      1'b0,directory}), .out(hit_dir2) );
cmp14 t11 (.ina({tab11[33:30],tab11[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab11), .out2(hit_add11));
cmp14 t12 (.ina({tab12[33:30],tab12[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab12), .out2(hit_add12));
cmp14 t13 (.ina({tab13[33:30],tab13[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab13), .out2(hit_add13));
cmp14 t14 (.ina({tab14[33:30],tab14[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab14), .out2(hit_add14));
cmp14 t21 (.ina({tab21[33:30],tab21[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab21), .out2(hit_add21));
cmp14 t22 (.ina({tab22[33:30],tab22[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab22), .out2(hit_add22));
cmp14 t23 (.ina({tab23[33:30],tab23[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab23), .out2(hit_add23));
cmp14 t24 (.ina({tab24[33:30],tab24[9:0]}), .inb({1'b0,WPsp,iread_req|iwrite_req,iwrite_req,tables   }), .out(hit_tab24), .out2(hit_add24));

assign tab_mux1 = ( hit_tab11 == 1 ) ? tab11[29:10] :
                  ( hit_tab12 == 1 ) ? tab12[29:10] :
		  ( hit_tab13 == 1 ) ? tab13[29:10] :
		                       tab14[29:10] ;
				       
assign tab_mux2 = ( hit_tab21 == 1 ) ? tab21[29:10] :
                  ( hit_tab22 == 1 ) ? tab22[29:10] :
		  ( hit_tab23 == 1 ) ? tab23[29:10] :
		                       tab24[29:10] ;
				       	
assign dir_mux = (hit_dir1 ==1)  ? tab_mux1 : tab_mux2; 

assign hit = (hit_dir1&( (hit_tab11) | (hit_tab12) | (hit_tab13) | (hit_tab14))) | 
	     (hit_dir2&( (hit_tab21) | (hit_tab22) | (hit_tab23) | (hit_tab24))) ;


always @(posedge clk or negedge rstn) 
if (rstn == 0) iDaddr_f <=0; else if (fsm ==0) iDaddr_f <= iDaddr;


always @(posedge clk or negedge rstn)
if (rstn == 0)
 begin
  fsm <= 3'b000; nx_dir <= 0; nx_tab1 <=0; nnx_tab1 <=2'b01; 
  nx_tab2 <=0; nnx_tab2 <=2'b01; req_miss <=0; wrD <= 0; wrA <=0;
  addr_miss <=0; pg_fault <= 0; cr2 <=0; fsm5_cnt <=0; wr_fault <=0; pt_fault <=0;
  dir1  <= 34'h23fffffef; dir2  <= 34'h23fffffef; 
  tab11 <= 34'h23fffffef; tab12 <= 34'h23fffffef; tab13 <= 34'h23fffffef; tab14 <= 34'h23fffffef;
  tab21 <= 34'h23fffffef; tab22 <= 34'h23fffffef; tab23 <= 34'h23fffffef; tab24 <= 34'h23fffffef;
  hit_adr11 <=0;hit_adr12 <=0;hit_adr13 <=0;hit_adr14 <=0;
  hit_adr21 <=0;hit_adr22 <=0;hit_adr23 <=0;hit_adr24 <=0;
 end
else
 if (pg_en)
 begin
  if (fsm == 0)
  begin
  fsm5_cnt <=0;
       if (flush_tlb==1) begin
    			  dir1  <= 34'h23fffffef; dir2  <= 34'h23fffffef;
    			  tab11 <= 34'h23fffffef; tab12 <= 34'h23fffffef; tab13 <= 34'h23fffffef; tab14 <= 34'h23fffffef;
    			  tab21 <= 34'h23fffffef; tab22 <= 34'h23fffffef; tab23 <= 34'h23fffffef; tab24 <= 34'h23fffffef;
                         end       
  else if ((hit_dir1 == 0) && (hit_dir2 == 0) && ((iread_req ==1)||(iwrite_req ==1)) && (fsm == 0) && (busy_ram==0) ) fsm <= 1;  // read new dir&table entry 
  else if (((hit_dir1|hit_dir2) == 1) && (hit == 0) && ((iread_req ==1)||(iwrite_req ==1)) && (fsm == 0) && (pg_fault==0)  && (busy_ram==0))
           begin
	    fsm <= 3; // read new table only entry
            hit_adr11 <= hit_add11; hit_adr12 <= hit_add12; hit_adr13 <= hit_add13; hit_adr14 <= hit_add14;
            hit_adr21 <= hit_add21; hit_adr22 <= hit_add22; hit_adr23 <= hit_add23; hit_adr24 <= hit_add24;
	   end
  end
  else if (fsm ==1)  
    begin 
     fsm <= 2; req_miss <=1;
     addr_miss <= {base[31:12] , addr_virt[19:10] , 2'b0};  
    end // end fsm1
   else if (fsm ==2)
    begin 
     if (ack_miss) 
      begin 
       req_miss <=0;       
       if (data_miss[0]==0) begin 
                             pg_fault <= 1; cr2 <= iDaddr_f; fsm <= 5; pt_fault <= 1'b0;
			     dir1 <= 34'h23fffffef; dir2 <= 34'h23fffffef;
    			     tab11 <= 34'h23fffffef; tab12 <= 34'h23fffffef; tab13 <= 34'h23fffffef; tab14 <= 34'h23fffffef;
    			     tab21 <= 34'h23fffffef; tab22 <= 34'h23fffffef; tab23 <= 34'h23fffffef; tab24 <= 34'h23fffffef;
			    end 
                       else begin 
		             pg_fault <= 0; 
			     if ((data_miss[5]==1)) fsm <= 3; else begin fsm <= 6; wrD <= data_miss | {26'b0,1'b1,5'b0}; wrA <= addr_miss; end
		             if (nx_dir == 3'b000) 
			         begin 
			          dir1 <= {2'b0,iread_req|iwrite_req,iwrite_req,data_miss[31:12],addr_virt[19:10]}; nx_dir <= 2'b01;
				  tab11 <= 34'h23fffffef; tab12 <= 34'h23fffffef; tab13 <= 34'h23fffffef; tab14 <= 34'h23fffffef;
				 end else 
				 begin 
				  dir2 <= {2'b0,iread_req|iwrite_req,iwrite_req,data_miss[31:12],addr_virt[19:10]}; nx_dir <= 2'b00;
				  tab21 <= 34'h23fffffef; tab22 <= 34'h23fffffef; tab23 <= 34'h23fffffef; tab24 <= 34'h23fffffef;
				 end
			    end
      end
     end // end fsm2
   else if (fsm ==3)
    begin
     fsm <= 4;  req_miss <=1;
     
     if (hit_adr11 ==1) begin nx_tab1 <= 3'b000; nnx_tab1 <=nx_tab1 ; end else
     if (hit_adr12 ==1) begin nx_tab1 <= 3'b001; nnx_tab1 <=nx_tab1 ; end else
     if (hit_adr13 ==1) begin nx_tab1 <= 3'b010; nnx_tab1 <=nx_tab1 ; end else
     if (hit_adr14 ==1) begin nx_tab1 <= 3'b011; nnx_tab1 <=nx_tab1 ; end else nx_tab1 <= nx_tab1;
     
     if (hit_adr21 ==1) begin nx_tab2 <= 3'b000; nnx_tab2 <=nx_tab2 ; end else
     if (hit_adr22 ==1) begin nx_tab2 <= 3'b001; nnx_tab2 <=nx_tab2 ; end else
     if (hit_adr23 ==1) begin nx_tab2 <= 3'b010; nnx_tab2 <=nx_tab2 ; end else
     if (hit_adr24 ==1) begin nx_tab2 <= 3'b011; nnx_tab2 <=nx_tab2 ; end else nx_tab2 <= nx_tab2;
     
     if (hit_dir1) addr_miss <= {dir1[29:10],addr_virt[9:0],2'b0}; 
              else addr_miss <= {dir2[29:10],addr_virt[9:0],2'b0};
    end // end fsm3
   else if (fsm ==4)
    begin
     if (ack_miss) 
      begin
      req_miss <=0;
      if ((data_miss[0]==0) | ((data_miss[1]==0)&&(iwrite_req==1)&&({cr0[16],cs[1:0]}!=3'b000)) )
         begin 
	  pg_fault<=1; cr2 <= iDaddr_f; fsm <= 5; wr_fault <= ~data_miss[1] & iwrite_req; pt_fault <= data_miss[0];
	  dir1 <= 34'h23fffffef; dir2 <= 34'h23fffffef;
    	  tab11 <= 34'h23fffffef; tab12 <= 34'h23fffffef; tab13 <= 34'h23fffffef; tab14 <= 34'h23fffffef;
    	  tab21 <= 34'h23fffffef; tab22 <= 34'h23fffffef; tab23 <= 34'h23fffffef; tab24 <= 34'h23fffffef;
	 end 
      else 
         begin 
	  if (((data_miss[5]==1)&&(iread_req==1))|((data_miss[6:5]==2'b11)&&(iwrite_req==1))) fsm <= 0; 
	     else begin fsm <= 7; wrD <= data_miss | {25'b0,iwrite_req,1'b1,5'b0} ; wrA <= addr_miss; end
	     
	  pg_fault <= 0; wr_fault <= 0;
          casex ({hit_dir1,hit_dir2,nx_tab1,nx_tab2})
           8'b10x00xxx : begin tab11 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab1 <=nnx_tab1 ;nnx_tab1 <= nnx_tab1+1; end
           8'b10x01xxx : begin tab12 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab1 <=nnx_tab1 ;nnx_tab1 <= nnx_tab1+1; end
           8'b10x10xxx : begin tab13 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab1 <=nnx_tab1 ;nnx_tab1 <= nnx_tab1+1; end
           8'b10x11xxx : begin tab14 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab1 <=nnx_tab1 ;nnx_tab1 <= nnx_tab1+1; end
           8'b01xxxx00 : begin tab21 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab2 <=nnx_tab2 ;nnx_tab2 <= nnx_tab2+1; end
           8'b01xxxx01 : begin tab22 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab2 <=nnx_tab2 ;nnx_tab2 <= nnx_tab2+1; end
           8'b01xxxx10 : begin tab23 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab2 <=nnx_tab2 ;nnx_tab2 <= nnx_tab2+1; end
           8'b01xxxx11 : begin tab24 <= {1'b0,data_miss[1],1'b1,iwrite_req,data_miss[31:12],addr_virt[9:0]}; nx_tab2 <=nnx_tab2 ;nnx_tab2 <= nnx_tab2+1; end
          endcase
	 end
      end
    end // end fsm4
   else if (fsm ==5)
    begin
     if (fsm5_cnt<280) fsm5_cnt <= fsm5_cnt + 1; else begin fsm <= 0; pg_fault <= 0; wr_fault <= 0; end
    end         
   else if (fsm ==6)
    begin
     if (iwrite_ack == 0) fsm <= 6; else fsm <=8;
    end         
   else if (fsm ==7)
    begin
     if (iwrite_ack == 0) fsm <= 7; else fsm <=9;
    end         
   else if (fsm ==8)
    begin
     if (iwrite_ack == 1) fsm <= 8; else fsm <=3;
    end         
   else if (fsm ==9)
    begin
     if (iwrite_ack == 1) fsm <= 9; else fsm <=0;
    end         
  end			  


endmodule
