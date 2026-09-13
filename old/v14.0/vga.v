///////////////////////////////////
// AXI to VGA frame buffer
// fixed 640x200x16bpp RGB565 , 256kByte internal vram ressource
// (c) Valptek 2017
///////////////////////////////////


module vga(
    input s00_AXI_RSTN,
    input s00_AXI_CLK,
    output [3:0] r4,g4,b4,
    output hz,vt,
    // axi bus
    input  [31:0] s00_AXI_AWADDR, s00_AXI_ARADDR,
    input	  s00_AXI_AWVALID,s00_AXI_ARVALID,s00_AXI_WVALID,s00_AXI_RREADY,s00_AXI_WLAST,
    output reg    s00_AXI_AWREADY,s00_AXI_ARREADY,s00_AXI_WREADY,s00_AXI_RVALID,s00_AXI_RLAST,
    output reg [31:0] s00_AXI_RDATA,
    input  [31:0] s00_AXI_WDATA,
    input   [3:0] s00_AXI_WSTRB,
    input   [1:0] s00_AXI_ARBURST,
    input   [7:0] s00_AXI_ARLEN,
    input   [2:0] s00_AXI_ARSIZE,
    input   [1:0] s00_AXI_AWBURST,
    input   [7:0] s00_AXI_AWLEN,
    input   [2:0] s00_AXI_AWSIZE,
    input	  s00_AXI_BREADY,
    output	  s00_AXI_BVALID
    );

// video ram
reg  [7:0] vmem1 [0:(640*200/2)-1];
reg  [7:0] vmem2 [0:(640*200/2)-1];
reg  [7:0] vmem3 [0:(640*200/2)-1];
reg  [7:0] vmem4 [0:(640*200/2)-1];

reg  [7:0] Qreg1,Qreg2,Qreg3,Qreg4;
reg [15:0] wadd,radd,vadd,gadd;
reg  [1:0] vbits;
reg        wreq1,wreq2,wreq3,wreq4;

reg [15:0] fifo;
reg [31:0] wdat;
reg [1:0] gclk;
reg [9:0] counX, counY;
wire [9:0] nextcounX;
reg hSync, vSync;
reg rd_rq,wr_rq,wr_gnt,rd_gnt;
reg [3:0] wr_strb;


always @(posedge s00_AXI_CLK) Qreg1 <= vmem1[vadd];
always @(posedge s00_AXI_CLK) Qreg2 <= vmem2[vadd];
always @(posedge s00_AXI_CLK) Qreg3 <= vmem3[vadd];
always @(posedge s00_AXI_CLK) Qreg4 <= vmem4[vadd];


always @(posedge s00_AXI_CLK) if (wreq1) vmem1[vadd] <= wdat[31:24];
always @(posedge s00_AXI_CLK) if (wreq2) vmem2[vadd] <= wdat[23:16];
always @(posedge s00_AXI_CLK) if (wreq3) vmem3[vadd] <= wdat[15:8];
always @(posedge s00_AXI_CLK) if (wreq4) vmem4[vadd] <= wdat[7:0];

//
// Internal BUS :  write generate & decode + round robin for video display
//
always @(posedge s00_AXI_CLK or negedge s00_AXI_RSTN)
if (s00_AXI_RSTN == 0)
 begin 
  s00_AXI_AWREADY <= 0;
  s00_AXI_ARREADY <= 0;
  s00_AXI_WREADY  <= 0;
  s00_AXI_RVALID  <= 0;
  s00_AXI_RLAST   <= 0;
  rd_rq           <= 0;
  wr_rq           <= 0;
 end
else
begin 
   if ( ((s00_AXI_AWVALID == 1) && (s00_AXI_AWREADY ==0)) ) begin s00_AXI_AWREADY <=1; wadd <= s00_AXI_AWADDR[17:2]; end
   
   if ( ((s00_AXI_ARVALID == 1) && (s00_AXI_ARREADY ==0)) ) begin rd_rq <= 1; s00_AXI_ARREADY <=1; radd <= s00_AXI_ARADDR[17:2]; end else
                                                            begin 
                                                             s00_AXI_ARREADY <=0; 
                                                             s00_AXI_AWREADY <=0; 
                                                             if (rd_gnt ==1) 
                                                                 begin 
                                                                   rd_rq <=0; 
                                                                    
                                                                   s00_AXI_RVALID <= 1; 
                                                                   s00_AXI_RLAST  <= 1;
                                                                 end 
                                                                 else 
                                                                  begin
                                                                   s00_AXI_RVALID <= 0;
                                                                   s00_AXI_RLAST  <= 1;
                                                                  end
                                                            end
                                                            
   if  ( wr_gnt         == 1)                          begin s00_AXI_WREADY <=1; wr_rq <=0; wr_strb <= 0; end else
   if ((s00_AXI_WVALID  == 1) && (s00_AXI_WREADY ==0)) begin wr_rq <= 1; wr_strb <= s00_AXI_WSTRB; wdat <= s00_AXI_WDATA; end else 
                                       s00_AXI_WREADY <=0;
   

end


// clock divider gap
always @(posedge s00_AXI_CLK) if (~s00_AXI_RSTN) gclk <=0; else gclk <= gclk + 1;

// vram read write control
always @(posedge s00_AXI_CLK) 
 if (~s00_AXI_RSTN)
 begin 
  gadd   <= 0;
  fifo   <= 0;
  rd_gnt <= 0;
  wr_gnt <= 0;
  vadd   <= 0;
  s00_AXI_RDATA <=0;
 end 
 else
 begin
   if ((gclk == 0) && (wr_rq ==1)) begin wr_gnt <= 1; vadd <= wadd; {wreq1,wreq2,wreq3,wreq4} <= wr_strb; end else
   if ((gclk == 0) && (rd_rq ==1)) begin vadd <= radd; end else
   if ((gclk == 1) && (wr_rq ==1)) begin {wreq1,wreq2,wreq3,wreq4} <= 0; vadd <= gadd; end else
   if ((gclk == 1) && (rd_rq ==1)) begin rd_gnt <= 1; vadd <= gadd;  end else
   if  (gclk == 1)                 begin vadd <= gadd; end else
   if  (gclk == 2) begin wr_gnt <=0; rd_gnt <=0; s00_AXI_RDATA  <= {Qreg1,Qreg2,Qreg3,Qreg4}; end
   
  // update video address
   if  ((counY < 10'd400) && (nextcounX <10'd640)) gadd <=nextcounX[9:1]+{counY[9:1],8'b0}+{counY[9:1],6'b0};
   if  (gclk == 3) begin
                    if (nextcounX[0] == 1'b1) fifo <= {Qreg1,Qreg2}; else fifo <= {Qreg3,Qreg4};
		   end
 end

// raster  
always @(posedge s00_AXI_CLK) if (~s00_AXI_RSTN) counX <=0; else if (gclk ==3) begin if (counX==799) counX <=0; else counX <= nextcounX; end
always @(posedge s00_AXI_CLK) if (~s00_AXI_RSTN) counY <=0; else if((gclk ==3)&&(counX==799)) begin if (counY==524) counY <= 0; else counY <= counY + 1'b1; end

always @(posedge s00_AXI_CLK) if (~s00_AXI_RSTN) hSync <=0; else hSync <= (counX>=656) && (counX<752);
always @(posedge s00_AXI_CLK) if (~s00_AXI_RSTN) vSync <=0; else vSync <= (counY>=490) && (counY<492);

// dac
assign r4 = (counX>639) ? 0 : (counY>399) ? 0 :
	    fifo[15:12];

assign g4 = (counX>639) ? 0 : (counY>399) ? 0 :
	    fifo[10:7];

assign b4 = (counX>639) ? 0 : (counY>399) ? 0 :
            fifo[ 4: 1];

assign hz = ~hSync;
assign vt = vSync;
assign nextcounX = counX +1;

endmodule
