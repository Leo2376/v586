module realign (
clk,
rstn,
read_req_in,write_req_in,
read_req_out,write_req_out,

read_ack_in,write_ack_in,
read_ack_out,write_ack_out,

addr_in,
addr_out,

read_data_in,
read_data_out,

write_data_in,
write_data_out,
write_sz_in,
write_msk_out

);

input  [31:0] write_data_in , addr_in;
input [127:0] read_data_in ;

output [31:0] read_data_out,addr_out;
output [127:0] write_data_out;

input          rstn,clk;
input          read_req_in,write_req_in,read_ack_in,write_ack_in;
input    [1:0] write_sz_in;
output  [15:0] write_msk_out;
output         write_req_out,read_req_out,read_ack_out,write_ack_out;

reg write_req_ff, write_ack_ff, read_req_ff, read_ack_ff;
reg [31:0] addr_out_ff;
reg even;
reg [31:0] read_data_sav;
reg [31:0] read_data_out_ff,write_data_out_ff;
reg compl;

wire [15:0] msk8 = (addr_in[3:0] == 4'b0000) ? 16'b0000_0000_0000_0001 : 
		   (addr_in[3:0] == 4'b0001) ? 16'b0000_0000_0000_0010 : 
		   (addr_in[3:0] == 4'b0010) ? 16'b0000_0000_0000_0100 : 
		   (addr_in[3:0] == 4'b0011) ? 16'b0000_0000_0000_1000 :  

		   (addr_in[3:0] == 4'b0100) ? 16'b0000_0000_0001_0000 : 
		   (addr_in[3:0] == 4'b0101) ? 16'b0000_0000_0010_0000 : 
		   (addr_in[3:0] == 4'b0110) ? 16'b0000_0000_0100_0000 : 
		   (addr_in[3:0] == 4'b0111) ? 16'b0000_0000_1000_0000 :  

		   (addr_in[3:0] == 4'b1000) ? 16'b0000_0001_0000_0000 : 
		   (addr_in[3:0] == 4'b1001) ? 16'b0000_0010_0000_0000 : 
		   (addr_in[3:0] == 4'b1010) ? 16'b0000_0100_0000_0000 : 
		   (addr_in[3:0] == 4'b1011) ? 16'b0000_1000_0000_0000 :  

		   (addr_in[3:0] == 4'b1100) ? 16'b0001_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1101) ? 16'b0010_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1110) ? 16'b0100_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1111) ? 16'b1000_0000_0000_0000 : 16'b0;

wire [15:0] msk16= (addr_in[3:0] == 4'b0000) ? 16'b0000_0000_0000_0011 : 
		   (addr_in[3:0] == 4'b0001) ? 16'b0000_0000_0000_0110 : 
		   (addr_in[3:0] == 4'b0010) ? 16'b0000_0000_0000_1100 : 
		   (addr_in[3:0] == 4'b0011) ? 16'b0000_0000_0001_1000 :  

		   (addr_in[3:0] == 4'b0100) ? 16'b0000_0000_0011_0000 : 
		   (addr_in[3:0] == 4'b0101) ? 16'b0000_0000_0110_0000 : 
		   (addr_in[3:0] == 4'b0110) ? 16'b0000_0000_1100_0000 : 
		   (addr_in[3:0] == 4'b0111) ? 16'b0000_0001_1000_0000 :  

		   (addr_in[3:0] == 4'b1000) ? 16'b0000_0011_0000_0000 : 
		   (addr_in[3:0] == 4'b1001) ? 16'b0000_0110_0000_0000 : 
		   (addr_in[3:0] == 4'b1010) ? 16'b0000_1100_0000_0000 : 
		   (addr_in[3:0] == 4'b1011) ? 16'b0001_1000_0000_0000 :  

		   (addr_in[3:0] == 4'b1100) ? 16'b0011_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1101) ? 16'b0110_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1110) ? 16'b1100_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1111) ? 16'b1000_0000_0000_0000 : 16'b0;


wire [15:0] msk32= (addr_in[3:0] == 4'b0000) ? 16'b0000_0000_0000_1111 : 
		   (addr_in[3:0] == 4'b0001) ? 16'b0000_0000_0001_1110 : 
		   (addr_in[3:0] == 4'b0010) ? 16'b0000_0000_0011_1100 : 
		   (addr_in[3:0] == 4'b0011) ? 16'b0000_0000_0111_0000 :  

		   (addr_in[3:0] == 4'b0100) ? 16'b0000_0000_1111_0000 : 
		   (addr_in[3:0] == 4'b0101) ? 16'b0000_0001_1110_0000 : 
		   (addr_in[3:0] == 4'b0110) ? 16'b0000_0011_1100_0000 : 
		   (addr_in[3:0] == 4'b0111) ? 16'b0000_0111_1000_0000 :  

		   (addr_in[3:0] == 4'b1000) ? 16'b0000_1111_0000_0000 : 
		   (addr_in[3:0] == 4'b1001) ? 16'b0001_1110_0000_0000 : 
		   (addr_in[3:0] == 4'b1010) ? 16'b0011_1100_0000_0000 : 
		   (addr_in[3:0] == 4'b1011) ? 16'b0111_1000_0000_0000 :  

		   (addr_in[3:0] == 4'b1100) ? 16'b1111_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1101) ? 16'b1110_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1110) ? 16'b1100_0000_0000_0000 : 
		   (addr_in[3:0] == 4'b1111) ? 16'b1000_0000_0000_0000 : 16'b0;


wire [127:0] write_data_mux = (addr_in[3:0] == 4'b0000) ? {96'h0,write_data_in} : 
		              (addr_in[3:0] == 4'b0001) ? {88'h0,write_data_in,8'h0} : 
		              (addr_in[3:0] == 4'b0010) ? {80'h0,write_data_in,16'h0} :
	                      (addr_in[3:0] == 4'b0011) ? {72'h0,write_data_in,24'h0} :  

		              (addr_in[3:0] == 4'b0100) ? {64'h0,write_data_in,32'h0} : 
		              (addr_in[3:0] == 4'b0101) ? {56'h0,write_data_in,40'h0} : 
		              (addr_in[3:0] == 4'b0110) ? {48'h0,write_data_in,48'h0} : 
		              (addr_in[3:0] == 4'b0111) ? {40'h0,write_data_in,56'h0} :  

		   	      (addr_in[3:0] == 4'b1000) ? {32'h0,write_data_in,64'h0} : 
		   	      (addr_in[3:0] == 4'b1001) ? {24'h0,write_data_in,72'h0} : 
		   	      (addr_in[3:0] == 4'b1010) ? {16'h0,write_data_in,80'h0} : 
		   	      (addr_in[3:0] == 4'b1011) ? {8'h0,write_data_in,88'h0} :  
		   	       
		   	      (addr_in[3:0] == 4'b1100) ? {write_data_in[31:0],96'h0} : 
		   	      (addr_in[3:0] == 4'b1101) ? {write_data_in[23:0],104'h0} : 
		   	      (addr_in[3:0] == 4'b1110) ? {write_data_in[15:0],112'h0} : 
		              (addr_in[3:0] == 4'b1111) ? {write_data_in[7:0],120'h0} : 128'b0;


wire [127:0] write_data_mux_rest =(addr_in[3:0] == 4'b1101) ? {120'h0,write_data_in[31: 8]} : 
		   	          (addr_in[3:0] == 4'b1110) ? {112'h0,write_data_in[31:16]} : 
		                  (addr_in[3:0] == 4'b1111) ? {104'h0,write_data_in[31:24]} : 128'b0;

wire split   = ((addr_in[3:0] == 4'b1101) && (write_sz_in==2'b10))  ? 1'b1 :
               ((addr_in[3:0] == 4'b1110) && (write_sz_in==2'b10))  ? 1'b1 :
	       ((addr_in[3:0] == 4'b1111) && (write_sz_in==2'b10))  ? 1'b1 :
	       ((addr_in[3:0] == 4'b1111) && (write_sz_in==2'b01))  ? 1'b1 : 1'b0;


assign read_req_out  = read_req_ff;
assign read_ack_out  = read_ack_ff;

assign write_req_out = write_req_ff ;
assign write_ack_out = write_ack_ff ;

assign write_msk_out = ((compl ==1'b0) && (write_sz_in==2'b00))  ? msk8  :
                       ((compl ==1'b0) && (write_sz_in==2'b01))  ? msk16 :
	               ((compl ==1'b0) && (write_sz_in==2'b10))  ? msk32 : 1'b0;

                                                                             
assign write_data_out = write_data_out_ff;

assign read_data_out  = read_data_out_ff;

assign addr_out      = addr_out_ff;

always @(posedge clk or negedge rstn) 
if (~rstn) 
begin
 write_req_ff      <= 1'b0;
 write_ack_ff      <= 1'b0;
 read_req_ff       <= 1'b0;
 read_ack_ff       <= 1'b0;
 even              <= 1'b0;
 read_data_out_ff  <= 32'h0;
 write_data_out_ff <= 32'h0; 
 compl             <= 1'b0;
end
else
begin
 if (write_ack_ff == 1'b1) 
  begin
   write_req_ff <= 1'b0;
   write_ack_ff <= 1'b0;
   even         <= 1'b0;
   write_msk_ff <= 16'h0;
  end    
else if (read_ack_ff == 1'b1) 
   begin
    read_req_ff <= 1'b0;
    read_ack_ff <= 1'b0;
    even        <= 1'b0;
   end    
 else
 if ((read_req_ff == 1'b0) && (read_req_in == 1'b1) && (even == 1'b0)) 
    begin
     read_req_ff <= 1'b1;
     addr_out_ff <= {addr_in[31:4],4'b0000};
     if (split == 1'b1) even        <= 1'b1; else even <= 1'b0;
    end
 else
 if ((split == 1'b1) && (read_req_ff == 1'b1) && (read_ack_in == 1'b1) && (even == 1'b1))
    begin
     addr_out_ff <= {addr_in[31:4],4'b00} + 5'b10000;
     read_data_sav<= read_data_in;
     even        <= 1'b0;
    end 
 else
 if ((split == 1'b1) && (read_req_ff == 1'b1) && (read_ack_in == 1'b1) && (even == 1'b0))
    begin
     read_ack_ff <= 1'b1;
     read_req_ff <= 1'b0;
     case(addr_in[1:0])
      2'b00: read_data_out_ff <= read_data_sav; 
      2'b01: read_data_out_ff <= {read_data_in[ 7:0],read_data_sav[31: 8]};
      2'b10: read_data_out_ff <= {read_data_in[15:0],read_data_sav[31:16]};
      2'b11: read_data_out_ff <= {read_data_in[23:0],read_data_sav[31:24]};
     endcase
    end
 else
 if ((split == 1'b0) && (read_req_ff == 1'b1) && (read_ack_in == 1'b1))
    begin
     read_ack_ff <= 1'b1;
     read_req_ff <= 1'b0;
     read_data_out_ff <= read_data_in; 
    end
 else 
 if ((write_req_ff == 1'b0) && (write_req_in == 1'b1) && (even == 1'b0)) 
       begin
        addr_out_ff <= {addr_in[31:4],4'b0000};
        if (split == 1'b1) even        <= 1'b1; else even <= 1'b0;
        write_req_ff <= 1'b1;
        if (write_sz_in ==2'b00) begin write_msk_ff <= msk8 ; write_data_out_ff <= write_data_mux; end else 
        if (write_sz_in ==2'b01) begin write_msk_ff <= msk16; write_data_out_ff <= write_data_mux; end else 
        if (write_sz_in ==2'b10) begin write_msk_ff <= msk32; write_data_out_ff <= write_data_mux; end 
       end
    else
    if ((split == 1'b1) && (write_req_ff == 1'b1) && (write_ack_in == 1'b1) && (even == 1'b1))
       begin
        addr_out_ff  <= {addr_in[31:4],4'b0000} + 5'b10000;
        even         <= 1'b0;
	write_data_out_ff <= write_data_mux_rest;
	write_msk_ff <= {24'b0,~write_msk_ff[15:12]}
       end 
    else
    if ((split == 1'b1) && (write_req_ff == 1'b1) && (write_ack_in == 1'b1) && (even == 1'b0))
       begin
        even        <= 1'b0;
        write_ack_ff <= 1'b1;
        write_req_ff <= 1'b0;
       end 
    else
    if ((split == 1'b0) && (write_req_ff == 1'b1) && (write_ack_in == 1'b1))
       begin
        even        <= 1'b0;
        write_ack_ff <= 1'b1;
        write_req_ff <= 1'b0;
       end 
end

endmodule
