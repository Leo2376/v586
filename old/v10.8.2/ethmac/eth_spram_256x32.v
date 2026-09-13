
`include "timescale.v"

module eth_spram_256x32(
	input           clk,  // Clock, rising edge
	input           rst,  // Reset, active high
	input           ce,   // Chip enable input, active high
	input  [3:0]    we,   // Write enable input, active high
	input           oe,   // Output enable input, active high
	input  [7:0]    addr, // address bus inputs
	input  [31:0]   di,   // input data bus
	output [31:0]   do    // output data bus

);

wire write_enable;
assign write_enable = ce & (|we);

generic_sram_byte_en

    #(
    .DATA_WIDTH     ( 32            ) ,
    .ADDRESS_WIDTH  ( 8             )
) u_ram (
    .i_clk          ( clk           ),
    .i_write_data   ( di            ),
    .i_write_enable ( write_enable  ),
    .i_address      ( addr          ),
    .i_byte_enable  ( we            ),
    .o_read_data    ( do            )
);


endmodule
