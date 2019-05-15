module PWM(
			clk_in, 
			CE_in, 
			synch_reset_in, 
			PWM_data_input, 
			signmode, 
			PWM_out, 
			dirout
		);

parameter		PWM_IN_SIZE = 10; // this is a constant that can be overridden when
											// Instantiating this module
											
input 			clk_in, CE_in, synch_reset_in;
					// synch_reset_in must be synchronised to clk_in
input				signmode;	// controls whether PWM input is considered signed or unsigned
input [PWM_IN_SIZE-1:0] 	PWM_data_input;

output reg 						PWM_out;
output [1:0]					dirout;

// local signals									
reg 	[PWM_IN_SIZE-1:0] 	count;
wire 	[PWM_IN_SIZE-1:0] 	magn;

// wire assignments
assign magn =
	(signmode?(PWM_data_input[PWM_IN_SIZE-1]? 1'b0-PWM_data_input : PWM_data_input)<<1 : PWM_data_input);

assign dirout	= (signmode?(PWM_data_input[PWM_IN_SIZE-1]? 2'b01 : 2'b10):2'b10); // signed

// sequential logic
always @(posedge clk_in) begin
	if (synch_reset_in) begin
		PWM_out 		<= 0;
		count 		<= 0;
	end
	else if (CE_in) begin
		if (count < magn) PWM_out <= 1; // signed
		else					PWM_out <= 0;

		count 		<= count+1;
	end
end

endmodule