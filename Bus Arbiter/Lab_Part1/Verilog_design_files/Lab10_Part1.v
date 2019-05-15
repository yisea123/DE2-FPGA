/*****************************************************************************
 *                                                                           *
 * Module:       Lab10_Part1                                                  *
 * Description:                                                              *
 *      This module is the top level module of part I of the bus             *
 *   communication exercise in Altera's computer organization lab set.       *
 *                                                                           *
 *****************************************************************************/

module Lab10_Part1 (
	// Inputs
	CLOCK_50,
	KEY,
	SW,
	
	// Outputs
	HEX0,
	HEX1,
	HEX2,
	HEX3,
	HEX4,
	HEX5,
	HEX6,
	HEX7
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input			CLOCK_50;
input		[3:0]	KEY;
input		[17:0] SW;

// Outputs
output	[6:0]	HEX0;
output	[6:0]	HEX1;
output	[6:0]	HEX2;
output	[6:0]	HEX3;
output	[6:0]	HEX4;
output	[6:0]	HEX5;
output	[6:0]	HEX6;
output	[6:0]	HEX7;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[18:0]	address;
wire				bus_enable;
wire		[1:0]		byte_enable;
wire				rw;
wire		[15:0]	write_data;

wire				acknowledge;
wire		[15:0]	read_data;

wire		[15:0]	register_0;
wire		[15:0]	register_1;
wire		[15:0]	register_2;
wire		[15:0]	register_3;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

nios_system NiosII (
	// Inputs
	.clk_clk		(CLOCK_50),
	.reset_reset_n	(KEY[0]),

	.bridge_acknowledge	(acknowledge),
	.bridge_read_data		(read_data),

	// Outputs
	.bridge_address		(address),
	.bridge_bus_enable	(bus_enable),
	.bridge_byte_enable	(byte_enable),
	.bridge_rw			(rw),
	.bridge_write_data	(write_data)
);

Peripheral_on_External_Bus Four_Registers (
	// Inputs
	.clk_clk			(CLOCK_50),
	.reset_reset_n		(KEY[0]),
	
	.address		(address),
	.bus_enable		(bus_enable),
	.byte_enable	(byte_enable),
	.rw			(rw),
	.write_data		(write_data),
	
	// Outputs
	.acknowledge	(acknowledge),
	.read_data		(read_data),
	
	.register_0		(register_0),
	.register_1		(register_1),
	.register_2		(register_2),
	.register_3		(register_3)
);

Seven_Segment_Display Hex_Display (
	// Inputs
	.clk_clk			(CLOCK_50),
	.reset_reset_n		(KEY[0]),
	
	.register_0		(register_0),
	.register_1		(register_1),
	.register_2		(register_2),
	.register_3		(register_3),

	.register_selection	(SW[1:0]),

	// Outputs
	.seven_segment_display_0	(HEX0),
	.seven_segment_display_1	(HEX1),
	.seven_segment_display_2	(HEX2),
	.seven_segment_display_3	(HEX3),
	.seven_segment_display_4	(HEX4),
	.seven_segment_display_5	(HEX5),
	.seven_segment_display_6	(HEX6),
	.seven_segment_display_7	(HEX7)
);

endmodule

