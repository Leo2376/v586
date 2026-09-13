/* verilator lint_off UNUSED */
/* verilator lint_off CASEX */
module v8253(
    input               clk,
    input               rst_n,
    
    output              irq,
    
    //io slave 040h-043h
    input       [1:0]   io_address,
    input               io_read,
    output reg  [7:0]   io_readdata,
    input               io_write,
    input       [7:0]   io_writedata,
    
    //speaker port 61h
    input               port_61h_read,
    output      [7:0]   port_61h_readdata,
    input               port_61h_write,
    input       [7:0]   port_61h_writedata,
    
    //speaker output
    output reg          port_enable,
    output              port_out,
    
    input       [7:0]  cyc_ratio,
    input       [7:0]  cyc_ratio2);

reg io_read_last;
reg [7:0] cycles_in_1193181hz; //838.096ns
reg [7:0] system_counter;
reg port_gate;
reg counter_1_toggle;
reg [5:0] counter_1_cnt;
reg system_clock;

wire [7:0] counter_0_readdata;
wire [7:0] counter_1_readdata;
wire [7:0] counter_2_readdata;


//------------------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin if(rst_n == 1'b0) io_read_last <= 1'b0; else if(io_read_last) io_read_last <= 1'b0; else io_read_last <= io_read; end 
wire io_read_valid = io_read && io_read_last == 1'b0;

//------------------------------------------------------------------------------ system clock
reg [7:0] hopping ;

always @(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)  
     begin
      cycles_in_1193181hz <= 8'd42;
      hopping <=0;
     end     
    else
      if (system_counter >= cycles_in_1193181hz)
      begin      
      if (hopping < cyc_ratio2)
         begin
          hopping <= hopping +1; 
	  cycles_in_1193181hz <= cyc_ratio;
	 end
	 else
	 begin
	  hopping <= 0;
	  cycles_in_1193181hz <= cyc_ratio-2;
	 end
     end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                               system_counter <= 8'd0;
    else if(system_counter >= cycles_in_1193181hz)  system_counter <= 8'd0;
    else                                            system_counter <= system_counter + 8'd2;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                               system_clock <= 1'b0;
    else if(system_counter >= cycles_in_1193181hz)  system_clock <= ~(system_clock);
end

//------------------------------------------------------------------------------ read io

wire [7:0] io_readdata_next =
    (io_read_valid && io_address == 2'd0)?    counter_0_readdata :
    (io_read_valid && io_address == 2'd1)?    counter_1_readdata :
    (io_read_valid && io_address == 2'd2)?    counter_2_readdata :
                                              8'd0; //control address

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)   io_readdata <= 8'd0;
    else                io_readdata <= io_readdata_next;
end

//------------------------------------------------------------------------------ speaker

assign port_61h_readdata = { 2'b0, port_out, counter_1_toggle, 2'b0, port_enable, port_gate };

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                           counter_1_cnt <= 6'd0;
    else if(system_counter >= cycles_in_1193181hz && counter_1_cnt == 6'd35)    counter_1_cnt <= 6'd0;
    else if(system_counter >= cycles_in_1193181hz)                              counter_1_cnt <= counter_1_cnt + 6'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)                                                           counter_1_toggle <= 1'b0;
    else if(system_counter >= cycles_in_1193181hz && counter_1_cnt == 6'd35)    counter_1_toggle <= ~(counter_1_toggle);
end


always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           port_gate <= 1'b0;
    else if(port_61h_write)  port_gate <= port_61h_writedata[0];
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)           port_enable <= 1'b0;
    else if(port_61h_write)  port_enable <= port_61h_writedata[1];
end

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------

v8253_counter ucount1(
    .clk                (clk),
    .rst_n              (rst_n),
    
    .clock              (system_clock),     //input
    .gate               (1'b1),             //input
    .out                (irq),              //output
    
    .data_in            (io_writedata),                                                                                                                                         //input [7:0]
    .set_control_mode   (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b00 && io_writedata[5:4] != 2'b00),                                                           //input
    .latch_count        (io_write && io_address == 2'd3 && ((io_writedata[7:6] == 2'b00 && io_writedata[5:4] == 2'b00) || (io_writedata[7:5] == 3'b110 && io_writedata[1]))),   //input
    .latch_status       (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b11 && io_writedata[4] == 1'b0 && io_writedata[1]),                                           //input
    .write              (io_write && io_address == 2'd0),                                                                                                                       //input
    .read               (io_read_valid && io_address == 2'd0),                                                                                                                  //input
    
    .data_out           (counter_0_readdata)    //output [7:0]
);

v8253_counter count2(
    .clk                (clk),
    .rst_n              (rst_n),
    
    .clock              (system_clock),     //input
    .gate               (1'b1),             //input
    /* verilator lint_off PINNOCONNECT */
    .out                (),                 //output
    /* verilator lint_on PINNOCONNECT */
    
    .data_in            (io_writedata),                                                                                                                                         //input [7:0]
    .set_control_mode   (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b01 && io_writedata[5:4] != 2'b00),                                                           //input
    .latch_count        (io_write && io_address == 2'd3 && ((io_writedata[7:6] == 2'b01 && io_writedata[5:4] == 2'b00) || (io_writedata[7:5] == 3'b110 && io_writedata[2]))),   //input
    .latch_status       (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b11 && io_writedata[4] == 1'b0 && io_writedata[2]),                                           //input
    .write              (io_write && io_address == 2'd1),                                                                                                                       //input
    .read               (io_read_valid && io_address == 2'd1),                                                                                                                  //input
    
    .data_out           (counter_1_readdata)    //output [7:0]
);

v8253_counter count3(
    .clk                (clk),
    .rst_n              (rst_n),
    
    .clock              (system_clock),     //input
    .gate               (port_gate),     //input
    .out                (port_out),      //output
    
    .data_in            (io_writedata),                                                                                                                                         //input [7:0]
    .set_control_mode   (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b10 && io_writedata[5:4] != 2'b00),                                                           //input
    .latch_count        (io_write && io_address == 2'd3 && ((io_writedata[7:6] == 2'b10 && io_writedata[5:4] == 2'b00) || (io_writedata[7:5] == 3'b110 && io_writedata[3]))),   //input
    .latch_status       (io_write && io_address == 2'd3 && io_writedata[7:6] == 2'b11 && io_writedata[4] == 1'b0 && io_writedata[3]),                                           //input
    .write              (io_write && io_address == 2'd2),                                                                                                                       //input
    .read               (io_read_valid && io_address == 2'd2),                                                                                                                  //input
    
    .data_out           (counter_2_readdata)    //output [7:0]
);

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------

endmodule
