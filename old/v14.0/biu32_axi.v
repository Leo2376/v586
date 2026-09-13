module biu32_axi(
rstn,clk, 
write_req, write_ack, write_data, write_sz, write_msk,
read_req , read_ack , read_data , read_sz,
Daddr,
code_req , code_ack , code_data , code_addr,
code_wreq, code_wack, code_wdata,
readio_req, writeio_req, readio_ack, writeio_ack,
writeio_data, readio_data, io_add,

// AXI4 INSTRUCTION 128 BIT BUS
axi_AW, axi_AWVALID, axi_AWREADY,  axi_AWBURST, axi_AWLEN , axi_AWSIZE,
axi_W, axi_WVALID, axi_WREADY, axi_WSTRB, axi_WLAST,
axi_AR, axi_ARVALID, axi_ARREADY, axi_ARBURST, axi_ARLEN, axi_ARSIZE,
axi_R, axi_RVALID, axi_RREADY, axi_RLAST,

// AXI4 DATA 128 BIT BUS
D_axi_AW, D_axi_AWVALID, D_axi_AWREADY,  D_axi_AWBURST, D_axi_AWLEN, D_axi_AWSIZE,
D_axi_W,  D_axi_WVALID,  D_axi_WREADY,   D_axi_WSTRB,   D_axi_WLAST,
D_axi_AR, D_axi_ARVALID, D_axi_ARREADY,  D_axi_ARBURST, D_axi_ARLEN, D_axi_ARSIZE,
D_axi_R,  D_axi_RVALID,  D_axi_RREADY,   D_axi_RLAST,

// AXI4 PERIPH IOBUS 32 BIT BUS ( IN FACT ONLY 8 LSB USED)
axi_io_AW, axi_io_AWVALID, axi_io_AWREADY, axi_io_AWBURST, axi_io_AWLEN , axi_io_AWSIZE,
axi_io_W,  axi_io_WVALID,  axi_io_WREADY,  axi_io_WSTRB,   axi_io_WLAST,
axi_io_AR, axi_io_ARVALID, axi_io_ARREADY, axi_io_ARBURST, axi_io_ARLEN,  axi_io_ARSIZE,
axi_io_R,  axi_io_RVALID,  axi_io_RREADY,  axi_io_RLAST,

busy, outstanding
);
 
//ports
input       clk,rstn,write_req,read_req,code_req,code_wreq;
input [1:0] write_sz,read_sz;
output reg  code_wack;
output      write_ack;
output      read_ack,code_ack;
input       [31:0] Daddr,code_addr;
input      [127:0] code_wdata,write_data;
output     [127:0] read_data;
output reg [127:0] code_data;
output reg  [31:0] readio_data;
input       [31:0] writeio_data;
output reg  readio_ack,writeio_ack;
input       readio_req,writeio_req;
input       [31:0] io_add;
input       [15:0] write_msk;
input              outstanding;

// axi instruction bus
output reg  [31:0] axi_AW, axi_AR;
output reg 	   axi_AWVALID,axi_ARVALID,axi_WVALID,axi_RREADY,axi_WLAST;
input      	   axi_AWREADY,axi_ARREADY,axi_WREADY,axi_RVALID,axi_RLAST;
input      [127:0] axi_R;
output reg [127:0] axi_W;
output reg  [15:0] axi_WSTRB;
output reg   [1:0] axi_ARBURST,axi_AWBURST;
output reg   [7:0] axi_ARLEN, axi_AWLEN;
output reg   [2:0] axi_ARSIZE, axi_AWSIZE;

// axi data bus
output reg  [31:0] D_axi_AW, D_axi_AR;
output reg 	   D_axi_AWVALID,D_axi_ARVALID,D_axi_WVALID,D_axi_RREADY,D_axi_WLAST;
input      	   D_axi_AWREADY,D_axi_ARREADY,D_axi_WREADY,D_axi_RVALID,D_axi_RLAST;
input      [127:0] D_axi_R;
output reg [127:0] D_axi_W;
output reg  [15:0] D_axi_WSTRB;
output reg   [1:0] D_axi_ARBURST,D_axi_AWBURST;
output reg   [7:0] D_axi_ARLEN, D_axi_AWLEN;
output reg   [2:0] D_axi_ARSIZE, D_axi_AWSIZE;

// axi_io bus
output reg [31:0] axi_io_AW, axi_io_AR;
output reg 	  axi_io_AWVALID,axi_io_ARVALID,axi_io_WVALID,axi_io_RREADY,axi_io_WLAST;
input      	  axi_io_AWREADY,axi_io_ARREADY,axi_io_WREADY,axi_io_RVALID,axi_io_RLAST;
input      [31:0] axi_io_R;
output reg [31:0] axi_io_W;
output      [3:0] axi_io_WSTRB;
output      [1:0] axi_io_ARBURST,axi_io_AWBURST;
output      [7:0] axi_io_ARLEN, axi_io_AWLEN;
output      [2:0] axi_io_ARSIZE, axi_io_AWSIZE;
output            busy;

// cache signals
wire   [9:0] cacheA;
reg  [149:0] cacheD;
wire [149:0] cacheQ;
reg          cacheWEN;
reg    [1:0] A4;
reg [15:0] cacheM;

// internal wires
wire [31:0] A32 = {Daddr[31:4],4'b0};
wire [31:0] A = Daddr;
reg          read_ack_slow,code_ack_slow;
reg    [4:0] fsm;
reg          wrint_ack;
reg    [4:0] burst_idx;
reg          abort;
reg          wf,rf;
reg          outs;

assign code_ack = code_ack_slow;

assign read_ack = read_ack_slow;

assign write_ack = wrint_ack ;
assign busy = (fsm !=0 ) ? 1 : 0;
assign read_data = (fsm == 5'b11110) ? axi_R : cacheQ[127: 0] ;

assign cacheA = (fsm == 5'b00001) ? axi_AW[13:4] : Daddr[13:4];

datacache datacache1 (
.A(cacheA),
.D(cacheD),
.Q(cacheQ),
.M(cacheM),
.WEN(cacheWEN),
.clk(clk)
);

always @(posedge clk or negedge rstn) 
if (~rstn)
 begin 
   abort         <=0;                   // if code_req is =0 during prefetch transaction then it is an abort , most likely issued from a jump or decode pipe interruption. 
   axi_AW        <= 0; axi_AR      <=0; // AXI ADDRESS OUTPUTS
   axi_AWVALID   <= 0; axi_ARVALID <=0; // AXI ADRESS VALID OUTPUTS
   axi_WVALID    <= 0; axi_RREADY  <=0; // AXI R/W CHANNEL REQUESTS
   axi_W         <= 0;                  // AXI DATA TO WRITE 
   axi_WSTRB     <= 0;                  // AXI DATA TO WRITE STROBE
   axi_ARSIZE    <= 3'h2;               // DEFAULT SIZE is 2^2 = 4 bytes , SO 32 bits
   axi_ARLEN     <= 8'h0;               // DEFAULT BURST LENGTH is 1 , SO NO BURST
   axi_ARBURST   <= 2'h1;               // DEFAULT BURST TYPE   is INCREMENT NO WRAP   
   axi_AWSIZE    <= 3'h2;               // DEFAULT SIZE is 2^2 = 4 bytes , SO 32 bits
   axi_AWLEN     <= 8'h0;               // DEFAULT BURST LENGTH is 1 , SO NO BURST
   axi_AWBURST   <= 2'h1;               // DEFAULT BURST TYPE   is INCREMENT NO WRAP  
   axi_WLAST     <= 0;                  // ANYWAY WE DONT BURST IN WRITE MODE 
   fsm           <= 0; 
   read_ack_slow <= 0; wrint_ack <= 0; // RETURN TO CORE HANDSHAKE
   code_ack_slow <= 0; code_wack <= 0; // RETURN TO CORE HANDSHAKE
   cacheWEN      <= 1'b1;
   cacheM        <= 16'hffff;
   outs          <= 0;
 end
else
casex ({fsm,(write_req&~wrint_ack),(read_req&~read_ack_slow),(code_req&~code_ack_slow),(code_wreq&~code_wack)})
9'b11111_xxxx: 
        begin 
         abort         <= 0;
         fsm           <= 0; 
	 wrint_ack     <= 0; 
     read_ack_slow <= 0; 
     code_ack_slow <= 0; 
       code_wack     <= 0;
         axi_ARVALID   <= 0; 
	 axi_AWVALID   <= 0; 
	 axi_RREADY    <= 0; 
	 axi_WVALID    <= 0; 
	 axi_WSTRB     <= 0; 
	 axi_WLAST     <= 0; 
	 axi_AWLEN     <= 0;
	 axi_ARLEN     <= 0;
	 axi_AW        <= A32; 
	 axi_AR        <= A32; 
	 axi_W         <= write_data; 
	 axi_AWBURST   <= 2'h1;
         axi_ARBURST   <= 2'h1;         
	 axi_AWSIZE    <= 2'h2;
         axi_ARSIZE    <= 2'h2;   
	 cacheWEN      <= 1'b1;
	 cacheM        <= 16'hffff;    
	end

9'b11110_xxxx: 
        begin 
         abort         <= 0;
         fsm           <= 0; 
	 wrint_ack     <= 0; 
         read_ack_slow <= 0; 
         code_ack_slow <= 0; 
         code_wack     <= 0;
         axi_ARVALID   <= 0; 
	 axi_AWVALID   <= 0; 
	 axi_RREADY    <= 0; 
	 axi_WVALID    <= 0; 
	 axi_WSTRB     <= 0; 
	 axi_WLAST     <= 0; 
	 axi_AWLEN     <= 0;
	 axi_ARLEN     <= 0;
	 axi_AW        <= A32; 
	 axi_AR        <= A32; 
	 axi_W         <= write_data; 
	 axi_AWBURST   <= 2'h1;
         axi_ARBURST   <= 2'h1;         
	 axi_AWSIZE    <= 2'h2;
         axi_ARSIZE    <= 2'h2;   
	 cacheWEN      <= 1'b1;      
	end
		
/////////////////////////////////
// Writes
/////////////////////////////////

9'b00000_10xx :  begin 
                  abort         <= 0;
		          read_ack_slow <= 0; 
		          code_ack_slow <= 0; 
		          code_wack     <= 0;
		          wrint_ack     <= 1; 
		          axi_AWVALID   <= 1; 
		          axi_WVALID    <= 1; 
                          axi_AW        <= A32; 
		          axi_WSTRB     <= write_msk;			  
		          axi_AWLEN     <= 0; 
		          axi_WLAST     <= 1;
		          fsm           <= 5'b00001; 
		          axi_W         <= write_data;
			      burst_idx     <= 0;
		         end
 
9'b00001_xxxx : begin
		wrint_ack   <= 0;
		if (axi_AWREADY == 1) axi_AWVALID <= 0;
		cacheWEN <= 1;
		if (axi_WREADY  == 1) 
		     begin 
		      axi_WVALID  <= 0; 
		      fsm <= 5'b11111; 
		     end
           
           end

             
/////////////////////////////////////		
// Reads
/////////////////////////////////////

9'b00000_01xx : begin
            abort	      <= 0;
		    wrint_ack	  <= 0; 
		    read_ack_slow <= 0; 
		    code_ack_slow <= 0; 
		    code_wack	  <= 0;
            axi_AR	      <= {Daddr[31:4],4'b0};
		    A4            <= Daddr[3:2];
		    fsm 	      <= 5'b01011; 
		    axi_RREADY    <= 0;
		    axi_ARLEN     <= 8'h0;
		    burst_idx     <= 0;
                end

9'b01011_01xx : begin
                 if (axi_AR[31:20] == 12'h40e) // 0x40ex_xxxx is uncached
                 begin
                    fsm <= 5'b01100; 
                    axi_ARVALID <= 1;   
                    axi_AR    	  <= {Daddr[31:2],2'b0};       
                    axi_ARLEN     <= 8'h0;    
                 end
                 else
                 if ((axi_AR[31:14] == cacheQ[145:128]) && (cacheQ[148] == 1'b1) && (outstanding ==1'b0)) 
                   begin 
                    if (cacheQ[149] == 1'b0)
                     begin
                      read_ack_slow<=1; 
                      fsm <= 5'b11111;
                     end
                     else
                     begin
                      read_ack_slow<=1; 
                      fsm <= 5'b11111; // execute the write back
                     end
                   end 
                  else
                   begin 
                    fsm <= 5'b01000; 
                    axi_ARVALID <= 1;
		            cacheM      <= 16'hffff;
                   end
                end

                         		 
9'b01000_xxxx : begin
                 if (axi_ARREADY == 1) begin axi_ARVALID <= 0; axi_RREADY <= 1; end
                 if((axi_RVALID == 1) && (axi_RLAST ==1'b1))
		      begin 
		       fsm<=5'b01001; 
		       cacheD <= {2'b01,2'b0,Daddr[31:14],axi_R};
		       cacheWEN  <= 0;  
		       axi_RREADY    <= 0;
	              end
	        end

9'b01001_xxxx : begin fsm <= 5'b01010; cacheWEN <= 1; end

9'b01010_xxxx : begin read_ack_slow<=1; fsm <= 5'b11111; end

9'b01100_xxxx : begin
               if (read_req == 0) abort <= 1;
               if (axi_ARREADY == 1) begin axi_ARVALID <= 0; axi_RREADY <= 1; end
               if((axi_RVALID  == 1) && (axi_RREADY == 1))
                begin 
                  fsm<=5'b11110; 
                  if (read_req) read_ack_slow<=~abort; 
                  axi_RREADY<=0;       
	            end
	       end

9'b01101_xxxx : begin // write back
                 
                end


//////////////////////////////////////////////
// Read Code = pre-fetch
//////////////////////////////////////////////

9'b00000_001x : begin
		 wrint_ack     <= 0; 
		 read_ack_slow <= 0; 
		 code_ack_slow <= 0; 
		 code_wack     <= 0;
         axi_AR        <= {code_addr[31:4],4'b0}; 
         axi_ARVALID   <= 1; 
         axi_RREADY    <= 1; 
         burst_idx     <= 0;
		 abort         <= 0;
		 axi_ARLEN <= 8'h0;    // single 128-bit beat = 16-byte line
		 axi_ARSIZE <= 3'h4;   // 2^4 = 16 bytes per beat
		 fsm       <= 5'b10001;
		end
	
9'b10001_xxxx : begin
                 if (code_req == 0) abort <= 1;
                 if (axi_ARREADY == 1) axi_ARVALID <= 0;
                 if((axi_RVALID == 1) && (axi_RLAST == 1'b1))
	          begin 
		    code_data    <= axi_R; // capture fetched 128-bit line
		    fsm        <= 5'b11111; 
		    axi_RREADY <= 0;
		    code_ack_slow <= 1;
	          end
	        end

/////////////////////////////////////////////////////
// Write Code = update page dirty from MMU
/////////////////////////////////////////////////////

9'b00000_0001 : begin 
		 wrint_ack     <= 0; 
		 read_ack_slow <= 0; 
		 code_ack_slow <= 0; 
		 code_wack     <= 0; 
                 fsm           <= 5'b11000; 
		 axi_AW        <= {code_addr[31:4],4'b0000}; 
		 axi_AWVALID   <= 1; 
		 axi_W         <= {120'b0,code_wdata[ 7: 0]}; 
		 axi_WVALID    <= 1; 
		 axi_WSTRB     <= 4'b0001;
		 axi_WLAST     <= 1; 
		 axi_AWLEN     <= 0;
		 cacheD        <= 0;
                 cacheM        <= 16'hffff;
		end
				
9'b11000_xxxx : begin
                 if (axi_AWREADY == 1) axi_AWVALID <= 0;
		         
		         if ((axi_AW[31:14] == cacheQ[145:128]) && (axi_AWREADY ==1) && (axi_AWVALID==1) ) cacheWEN <= 0; // cache devalidate

		         if (axi_WREADY  == 1) 
		           begin 
		             axi_WVALID  <= 0; 
		             fsm <= 5'b11111; 
		             cacheWEN <= 1; 
		             code_wack <= 1;
		           end 
                end
endcase

always @(posedge clk or negedge rstn) 
if (~rstn)
begin
 writeio_ack <=0;
 readio_ack <=0;
 axi_io_AW <=0; 
 axi_io_AR <=0;
 axi_io_AWVALID <=0;
 axi_io_ARVALID <=0;
 axi_io_WVALID <=0;
 axi_io_RREADY <=0;
 axi_io_WLAST <=0;
 axi_io_W <=0;
 wf <=0; rf <=0;
end
else
begin
 wf <= writeio_req; rf <= readio_req;
 if (readio_ack ==1) readio_ack <= 0; else
 if (writeio_ack ==1) writeio_ack <= 0; else
 if ((axi_io_AWVALID ==1) && (axi_io_AWREADY==1)) begin axi_io_WVALID <=1; axi_io_AWVALID <=0; axi_io_WLAST <=1; end else
 if ((axi_io_WVALID  ==1) && (axi_io_WREADY ==1)) begin axi_io_WVALID <=0; writeio_ack <=1; axi_io_WLAST <=0; end else 
 if ((axi_io_ARVALID ==1) && (axi_io_ARREADY==1)) begin axi_io_RREADY <=1; axi_io_ARVALID <=0; end else
 if ((axi_io_RVALID  ==1) && (axi_io_RREADY ==1)) begin axi_io_RREADY <=0; readio_ack <=1; readio_data<= axi_io_R; end else 
 if ((writeio_req ==1) && (wf == 0))
  begin
   axi_io_AW <= {14'b0,io_add[15:0],2'b0};
   axi_io_AWVALID <=1;
   axi_io_W <= writeio_data;
  end
 else
 if ((readio_req ==1) &&(rf == 0))
  begin
   axi_io_AR <= {14'b0,io_add[15:0],2'b0};
   axi_io_ARVALID <=1;
  end
end

assign axi_io_ARSIZE = 3'h2;
assign axi_io_AWSIZE = 3'h2;
assign axi_io_ARLEN =8'h0;
assign axi_io_AWLEN =8'h0;
assign axi_io_ARBURST =2'h1;
assign axi_io_AWBURST =2'h1;
assign axi_io_WSTRB =4'h1;


endmodule
