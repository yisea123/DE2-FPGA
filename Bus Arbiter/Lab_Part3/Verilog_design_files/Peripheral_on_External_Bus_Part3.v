/******************************************************************************
 *                                                                            *
 * Module:       Peripheral_on_External_Bus                                   *
 * Description:                                                               *
 *      This module is used for the registers for part I of the bus           *
 *   communication exercise in Altera's computer organization lab set.        *
 *                                                                            *
 * This is a skeleton module that must be completed as part of this exercise. *
 *                                                                            *
 *****************************************************************************/

module Peripheral_on_External_Bus (
	// Inputs
	clk_clk,
	reset_reset_n,
	
	address,
	bus_enable,
	byte_enable,
	rw,
	write_data,
	
	// Outputs 1
	acknowledge,
	read_data,
	
	register_0,
	register_1,
	register_2,
	register_3,
	
	// Bidirectionals
	SRAM_DQ,
	
	// Outputs 2
	
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

input		[19:0]	address;
input				bus_enable;
input		[1:0]	byte_enable;
input				rw;
input		[15:0]	write_data;

// Outputs 1
output				acknowledge;
output		[15:0]	read_data;

output	reg	[15:0]	register_0;
output	reg	[15:0]	register_1;
output	reg	[15:0]	register_2;
output	reg	[15:0]	register_3;

// Bidirectionals
inout		[15:0]	SRAM_DQ;

// Outputs 2
output	[17:0]	SRAM_ADDR;

output			SRAM_CE_N;
output			SRAM_WE_N;
output			SRAM_OE_N;
output			SRAM_UB_N;
output			SRAM_LB_N;

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge clk_clk)
begin
	if (reset_reset_n == 0)
	begin
		register_0 <= 16'h0000;
		register_1 <= 16'h0000;
		register_2 <= 16'h0000;
		register_3 <= 16'h0000;
	end

	/* Add code here */
	else if (reset_reset_n == 1)
	begin
		if ((bus_enable==1'b1) & (rw==1'b0))
			begin
				case (address[18:17])
				2'b00: if (byte_enable==2'b01) register_0[7:0] <= write_data[7:0];
						 else if (byte_enable==2'b10) register_0[15:8] <= write_data[7:0];
						 else if (byte_enable==2'b11) register_0 <= write_data;
				2'b01: if (byte_enable==2'b01) register_1[7:0] <= write_data[7:0];
						 else if (byte_enable==2'b10) register_1[15:8] <= write_data[7:0];
						 else if (byte_enable==2'b11) register_1 <= write_data;
				2'b10: if (byte_enable==2'b01) register_2[7:0] <= write_data[7:0];
						 else if (byte_enable==2'b10) register_2[15:8] <= write_data[7:0];
						 else if (byte_enable==2'b11) register_2 <= write_data;
				2'b11: if (byte_enable==2'b01) register_3[7:0] <= write_data[7:0];
						 else if (byte_enable==2'b10) register_3[15:8] <= write_data[7:0];
						 else if (byte_enable==2'b11) register_3 <= write_data;
				endcase
			end
	end	
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/
 
assign read_data	 = (address[18])?((address[17]?register_3:register_2)):((~address[17])?register_0:register_1);
/* Add code here */ 

assign acknowledge = bus_enable/* Add code here */ ;
assign read_data	= (rw)?SRAM_DQ:16'bz;///* Add code here */ 16'h000a;

assign SRAM_DQ	= (~rw)?write_data:16'bz;///* Add code here */ 16'hZZZZ;

assign SRAM_ADDR	= address[17:0];///* Add/Edit code here */ 18'h00000;

assign SRAM_CE_N	= !(bus_enable)/* Add code here */ ;
assign SRAM_WE_N	= !(rw)/* Add code here */ ;
assign SRAM_OE_N	= rw/* Add code here */ ;
assign SRAM_UB_N	= !(byte_enable[1])/* Add code here */ ;
assign SRAM_LB_N	= !(byte_enable[0])/* Add code here */ ;

endmodule
