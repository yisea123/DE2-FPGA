/******************************************************************************
 *                                                                            *
 * Module:       Seven_Segment_Display                                        *
 * Description:                                                               *
 *      This module writes data to Seven Segment Displays.                    *
 *                                                                            *
 * This is a skeleton module that must be completed as part of this exercise. *
 *                                                                            *
 * Hint: Creating an extra module which converts a 4-bit hexadecimal number   *
 *   to 7-segment display and instantiating it multiple times within this     *
 *   module will save you time.                                               *
 *                                                                            *
 ******************************************************************************/

module Seven_Segment_Display (
	// Inputs
	clk_clk,
	reset_reset_n,
	
	register_0,
	register_1,
	register_2,
	register_3,

	register_selection,

	// Outputs
	seven_segment_display_0,
	seven_segment_display_1,
	seven_segment_display_2,
	seven_segment_display_3,
	seven_segment_display_4,
	seven_segment_display_5,
	seven_segment_display_6,
	seven_segment_display_7
);


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input			clk_clk;
input			reset_reset_n;

input		[15:0] register_0;
input		[15:0] register_1;
input		[15:0] register_2;
input		[15:0] register_3;

input		[1:0]	register_selection;

// Outputs
output	[6:0]	seven_segment_display_0;
output	[6:0]	seven_segment_display_1;
output	[6:0]	seven_segment_display_2;
output	[6:0]	seven_segment_display_3;
output	[6:0]	seven_segment_display_4;
output	[6:0]	seven_segment_display_5;
output	[6:0]	seven_segment_display_6;
output	[6:0]	seven_segment_display_7;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires

	/* Add code here */
	reg [15:0] data;


/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

	/* Add code here */
/*	always @(register_selection, register_0, register_1, register_2, register_3)
		case (register_selection)
			2'b00:data = register_0;
			2'b01:data = register_1;
			2'b10:data = register_2;
			2'b11:data = register_3;
		endcase
		
	hex_to_7_segment h0 (.hex(data[3:0]), .disp(seven_segment_display_0));
	hex_to_7_segment h1 (.hex(data[7:4]), .disp(seven_segment_display_1));
	hex_to_7_segment h2 (.hex(data[11:8]), .disp(seven_segment_display_2));
	hex_to_7_segment h3 (.hex(data[15:12]), .disp(seven_segment_display_3));*/
	
	assign seven_segment_display_4 = 7'b1111111; //blank
	assign seven_segment_display_5 = 7'b1111111; //blank
	assign seven_segment_display_6 = 7'b1111111; //blank
	assign seven_segment_display_7 = 7'b1111111; //blank


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

	/* Add code here */
	always @*
		if (reset_reset_n==0) data <= 0;
		else //data <= 16'h90ab;
			  data <= (register_selection[1])? ((register_selection[0])?(register_3):(register_2)):((~register_selection[0])?(register_0):(register_1));
			  //data <= (register_selection[1])? ((register_selection[0])?(16'h1a2b):(16'h2b3c)):((~register_selection[0])?(16'h3c4d):(16'h4d5e));
	
	hex_to_7_segment h0 (.hex(data[3:0]), .disp(seven_segment_display_0));
	hex_to_7_segment h1 (.hex(data[7:4]), .disp(seven_segment_display_1));
	hex_to_7_segment h2 (.hex(data[11:8]), .disp(seven_segment_display_2));
	hex_to_7_segment h3 (.hex(data[15:12]), .disp(seven_segment_display_3));
endmodule


module hex_to_7_segment(hex, disp);
	input [3:0] hex;
	output reg [6:0] disp;

	always @(hex)
		case (hex)
			4'b0000: disp <= 7'b1000000; // Hexadecimal 0
			4'b0001: disp <= 7'b1111001; // Hexadecimal 1
			4'b0010: disp <= 7'b0100100; // Hexadecimal 2
			4'b0011: disp <= 7'b0110000; // Hexadecimal 3
			4'b0100: disp <= 7'b0011001; // Hexadecimal 4
			4'b0101: disp <= 7'b0010010; // Hexadecimal 5
			4'b0110: disp <= 7'b0000010; // Hexadecimal 6
			4'b0111: disp <= 7'b1111000; // Hexadecimal 7
			4'b1000: disp <= 7'b0000000; // Hexadecimal 8
			4'b1001: disp <= 7'b0011000; // Hexadecimal 9
			4'b1010: disp <= 7'b0001000; // Hexadecimal A
			4'b1011: disp <= 7'b0000011; // Hexadecimal B
			4'b1100: disp <= 7'b1000110; // Hexadecimal C
			4'b1101: disp <= 7'b0100001; // Hexadecimal D
			4'b1110: disp <= 7'b0000110; // Hexadecimal E
			4'b1111: disp <= 7'b0001110; // Hexadecimal F
			default: disp <= 7'b1111111; // Blank
		endcase
endmodule
