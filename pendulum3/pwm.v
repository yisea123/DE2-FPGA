module pwm(clk, synch_reset, CE, OE, data_in, out, dir, cmp_magn);


parameter PWM_IN_SIZE = 10;

input clk, synch_reset; // reset is assumed to be synchronised to clk
input CE;  // clock enable -  internal counter increments when CE=1 and rising clk
			// used to divide down when clock active.
input OE; // output enable - OE must be 1 to produce 1 outputs from out.
input signed [PWM_IN_SIZE-1:0] data_in;  // signed 2's complement input
output reg out; 	// out=1 in proportion to (magnitude of data_in)/2**[PWM_IN_SIZE-1]		   
					// out=1 always only when data_in=100..0 (ie most negative input)
output reg [1:0] dir ; 	//  dir =1 when input negative
reg [PWM_IN_SIZE-2:0] count;  // note 1 bit smaller than data_in


wire [PWM_IN_SIZE-1:0] cmp_magn_temp = (data_in[PWM_IN_SIZE-1]? 1'b0-data_in : data_in);
output reg  [PWM_IN_SIZE-1:0] cmp_magn;
localparam [PWM_IN_SIZE-2:0] ff = {(PWM_IN_SIZE-1){1'b1}}; //~0;
reg [1:0] dir1;

always @(posedge clk) begin
	if (synch_reset)
		begin
			count <= 0;
			cmp_magn <= cmp_magn_temp;
			dir1[0] <= data_in[PWM_IN_SIZE-1];
			
		end
	else if (CE) begin
		if (count == ff) // all 1's, so when count wraps to 0 cmp_magn ready
			begin
				dir1[0] <= data_in[PWM_IN_SIZE-1];
				cmp_magn <= cmp_magn_temp;
			end
		count <= count + 1'b1;
		dir[0] <= dir1[0]; // align dir & out timing
		if (count < cmp_magn)
			out <= OE;
		else out <= 0;
	end
	
	dir[1] <= ~dir[0];
end
endmodule
	
