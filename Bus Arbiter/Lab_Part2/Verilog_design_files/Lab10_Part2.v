/*****************************************************************************
 *                                                                           *
 * Module:       Lab10_Part2                                                  *
 * Description:                                                              *
 *      This module is the top level module of part II of the bus            *
 *   communication exercise in Altera's computer organization lab set.       *
 *                                                                           *
 *****************************************************************************/

module Lab10_Part2 (
	// Inputs
	CLOCK_50,
	KEY,
	
	// Bidirectionals
	SRAM_DQ,
	
	// Outputs
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
input			CLOCK_50;
input		[3:0]	KEY;

// Bidirectionals
inout		[15:0]	SRAM_DQ;

// Outputs
output	[17:0]	SRAM_ADDR;

output			SRAM_CE_N;
output			SRAM_WE_N;
output			SRAM_OE_N;
output			SRAM_UB_N;
output			SRAM_LB_N;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[18:0]	address;
wire				bus_enable;
wire		[1:0]	byte_enable;
wire				rw;
wire		[15:0]	write_data;
wire				acknowledge;
wire		[15:0]	read_data;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

nios_system NiosII (
	// Inputs
	.clk_clk		(CLOCK_50),
	.reset_reset_n	(KEY[0]),

	.bridge_acknowledge	(acknowledge),
	.bridge_read_data	(read_data),

	// Outputs
	.bridge_address		(address),
	.bridge_bus_enable	(bus_enable),
	.bridge_byte_enable	(byte_enable),
	.bridge_rw			(rw),
	.bridge_write_data	(write_data)
);

SRAM_Controller Sram_Controller (
	// Inputs
	.clk_clk		(CLOCK_50),
	.reset_reset_n	(KEY[0]),
	
	.address		(address),
	.bus_enable		(bus_enable),
	.byte_enable	(byte_enable),
	.rw				(rw),
	.write_data		(write_data),
	
	// Bidirectionals
	.SRAM_DQ		(SRAM_DQ),
	
	// Outputs
	.acknowledge	(acknowledge),
	.read_data		(read_data),

	.SRAM_ADDR		(SRAM_ADDR),

	.SRAM_CE_N		(SRAM_CE_N),
	.SRAM_WE_N		(SRAM_WE_N),
	.SRAM_OE_N		(SRAM_OE_N),
	.SRAM_UB_N		(SRAM_UB_N),
	.SRAM_LB_N		(SRAM_LB_N)
);

endmodule

