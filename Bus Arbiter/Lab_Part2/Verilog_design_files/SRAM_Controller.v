/*****************************************************************************
 *                                                                           *
 * Module:       SRAM_Controller                                             *
 * Description:                                                              *
 *      This module is used for the SRAM controller for part II of the bus   *
 *   communication exercise in Altera's computer organization lab set.       *
 *                                                                           *
 * This module is a skeleton and must be completed as part of this exercise. *
 *                                                                           *
 *****************************************************************************/

module SRAM_Controller (
	// Inputs
	clk_clk,
	reset_reset_n,
	
	address,
	bus_enable,
	byte_enable,
	rw,
	write_data,
	
	// Bidirectionals
	SRAM_DQ,
	
	// Outputs
	acknowledge,
	read_data,
	
	SRAM_ADDR,

	SRAM_CE_N,
	SRAM_WE_N,
	SRAM_OE_N,
	SRAM_UB_N,
	SRAM_LB_N
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk_clk;
input				reset_reset_n;

input		[18:0]	address;
input				bus_enable;
input		[1:0]	byte_enable;
input				rw;
input		[15:0]	write_data;

// Bidirectionals
inout		[15:0]	SRAM_DQ;

// Outputs
output			acknowledge;
output	[15:0]	read_data;

output	[17:0]	SRAM_ADDR;

output			SRAM_CE_N;
output			SRAM_WE_N;
output			SRAM_OE_N;
output			SRAM_UB_N;
output			SRAM_LB_N;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign acknowledge = bus_enable/* Add code here */ ;
assign read_data	= SRAM_DQ;///* Add code here */ 16'h000a;

assign SRAM_DQ	= (bus_enable & ~rw)?write_data:16'hZZZZ;///* Add code here */ 16'hZZZZ;

assign SRAM_ADDR	= address[18:1];///* Add/Edit code here */ 18'h00000;

assign SRAM_CE_N	= ~bus_enable/* Add code here */ ;
assign SRAM_WE_N	= ~(bus_enable & ~rw)/* Add code here */ ;
assign SRAM_OE_N	= ~(bus_enable & rw)/* Add code here */ ;
assign SRAM_UB_N	= ~(byte_enable[1])/* Add code here */ ;
assign SRAM_LB_N	= ~(byte_enable[0])/* Add code here */ ;

endmodule

