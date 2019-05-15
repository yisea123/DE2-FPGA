module encoder (
	clk,
	synch_reset,
	chA,
	chB,
	count
);

input clk;
input synch_reset;
input chA;
input chB;
output reg signed [31:0]	count;

reg As, Bs; // synchronised A, B
reg A_prev, B_prev;

always@(posedge clk) begin
	// previous update
	A_prev <= As; B_prev <= Bs;
	// synchroniser with one clock period // metastable settling time
	As <= chA; 
	Bs <= chB;

	if (synch_reset)
		count <= 0;
	else 
	begin
		case({A_prev, B_prev, As, Bs})
		4'b0010, 4'b1011, 4'b0100, 4'b1101:
			count <= count + 1'b1; 
		4'b0001, 4'b0111, 4'b1110, 4'b1000:
			count <= count - 1'b1;
		default: ;// do nothing since double 
		// transition - could flag error here
		endcase
	
		if(count>1000) begin	
			count<=-999;
		end
		if(count<=-1000) begin
			count<=999;	
		end
	end

end

endmodule
