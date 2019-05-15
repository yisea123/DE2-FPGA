/*****************************************************************************
 *                                                                          *
 * Module:       Lab10_Part3                                                  *
 * Description:                                                              *
 *      This module is the top level module of part III of the bus             *
 *   communication exercise in Altera's computer organization lab set.       *
 *                                                                           *
 *****************************************************************************/

module Lab10_Part3 (
	// Inputs
	CLOCK_50,
	KEY,
	SW,
	
	// Bidirectionals
	SRAM_DQ,
	
	// Outputs
	SRAM_ADDR,
	SRAM_CE_N,
	SRAM_WE_N,
	SRAM_OE_N,
	SRAM_UB_N,
	SRAM_LB_N,
	
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
input				CLOCK_50;
input		[3:0]	KEY;
input		[17:0] 	SW;

// Bidirectionals
inout		[15:0]	SRAM_DQ;

// Outputs 1
output	[6:0]	HEX0;
output	[6:0]	HEX1;
output	[6:0]	HEX2;
output	[6:0]	HEX3;
output	[6:0]	HEX4;
output	[6:0]	HEX5;
output	[6:0]	HEX6;
output	[6:0]	HEX7;

// Outputs 2
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
wire		[19:0]	address;
wire				bus_enable;
wire		[1:0]	byte_enable;
wire				rw;
wire		[15:0]	write_data;

wire				acknowledge;
wire 				acknowledge_REG;
wire 				acknowledge_SRAM;
wire		[15:0]	read_data;
wire		[15:0]	read_data_REG;
wire		[15:0]	read_data_SRAM;
wire		[15:0]	register_0;
wire		[15:0]	register_1;
wire		[15:0]	register_2;
wire		[15:0]	register_3;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/
 
assign acknowledge = address[19] ? acknowledge_SRAM: acknowledge_REG;
assign read_data = address[19] ? read_data_SRAM: read_data_REG;

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
	
	.address		(address[18:0]),
	.bus_enable		(bus_enable & address[19]),
	.byte_enable	(byte_enable),
	.rw				(rw),
	.write_data		(write_data),
	
	// Bidirectionals
	.SRAM_DQ		(SRAM_DQ),
	
	// Outputs
	.acknowledge	(acknowledge_SRAM),
	.read_data		(read_data_SRAM),

	.SRAM_ADDR		(SRAM_ADDR),

	.SRAM_CE_N		(SRAM_CE_N),
	.SRAM_WE_N		(SRAM_WE_N),
	.SRAM_OE_N		(SRAM_OE_N),
	.SRAM_UB_N		(SRAM_UB_N),
	.SRAM_LB_N		(SRAM_LB_N)
);

Peripheral_on_External_Bus Four_Registers (
	// Inputs
	.clk_clk		(CLOCK_50),
	.reset_reset_n	(KEY[0]),
	
	.address		(address[18:0]),
	.bus_enable		(bus_enable & (~address[19])),
	.byte_enable	(byte_enable),
	.rw				(rw),
	.write_data		(write_data),
	
	// Outputs
	.acknowledge	(acknowledge_REG),
	.read_data		(read_data_REG),
	
	.register_0		(register_0),
	.register_1		(register_1),
	.register_2		(register_2),
	.register_3		(register_3)
);

Seven_Segment_Display Hex_Display (
	// Inputs
	.clk_clk		(CLOCK_50),
	.reset_reset_n	(KEY[0]),
	
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

