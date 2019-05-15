module pendulum3
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_27,						//	27 MHz
		CLOCK_50,						//	50 MHz
		EXT_CLOCK,						//	External Clock
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[17:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		HEX4,							//	Seven Segment Digit 4
		HEX5,							//	Seven Segment Digit 5
		HEX6,							//	Seven Segment Digit 6
		HEX7,							//	Seven Segment Digit 7
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[8:0]
		LEDR,							//	LED Red[17:0]
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		////////////////////	GPIO	////////////////////////////
		GPIO_0,							//	GPIO Connection 0
		GPIO_1							//	GPIO Connection 1
//		Hbridge_InA,
//		Hbridge_InB,
//		Hbridge_PWM,
//		encoderAin,
//		encoderBin,
//		beam
	);

////////////////////////	Clock Input	 	////////////////////////
input			CLOCK_27;				//	27 MHz
input			CLOCK_50;				//	50 MHz
input			EXT_CLOCK;				//	External Clock
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	[17:0]	SW;						//	Toggle Switch[17:0]
////////////////////////	7-SEG Dispaly	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
output	[6:0]	HEX4;					//	Seven Segment Digit 4
output	[6:0]	HEX5;					//	Seven Segment Digit 5
output	[6:0]	HEX6;					//	Seven Segment Digit 6
output	[6:0]	HEX7;					//	Seven Segment Digit 7
////////////////////////////	LED		////////////////////////////
output	[8:0]	LEDG;					//	LED Green[8:0]
output	[17:0]	LEDR;					//	LED Red[17:0]
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable

////////////////////////	GPIO	////////////////////////////////
inout	[35:0]	GPIO_0;					//	GPIO Connection 0
inout	[35:0]	GPIO_1;					//	GPIO Connection 1
//(* chip_pin = "D25" *) output Hbridge_InA; //GPIO_0[0]
//(* chip_pin = "J22" *) output Hbridge_InB; //GPIO_0[1]
//(* chip_pin = "E26" *) output Hbridge_PWM; //GPIO_0[2]
//(* chip_pin = "E25" *) input encoderAin; //GPIO_0[3]
//(* chip_pin = "F24" *) input encoderBin; //GPIO_0[4]
//(* chip_pin = "F23" *) input beam; //GPIO_0[5]
wire Hbridge_InA; assign Hbridge_InA = GPIO_0[0];
wire Hbridge_InB; assign Hbridge_InB = GPIO_0[1];
wire Hbridge_PWM; assign Hbridge_PWM = GPIO_0[2];
wire encoderAin; assign encoderAin = GPIO_0[3];
wire encoderBin; assign encoderBin = GPIO_0[4];
wire beam; assign beam = GPIO_0[5];

assign LEDG[5] = beam;




wire [1:0] encodersIn;
assign encodersIn[1] = encoderAin;
assign encodersIn[0] = encoderBin;

reg  [31:0] microseconds;
reg  			latencyreg;
wire  [31:0] enc_count;
wire  [31:0] motormagn;
wire  [31:0] motorvolt;

assign GPIO_1[0] = encoderAin;
assign GPIO_1[1] = latencyreg;	// for interrupt latency check
assign GPIO_1[2] = Hbridge_PWM;		// for PWM check

reg	[31:0]		CE_count;
wire					CLOCK_PWM = (CE_count==4);
always @(posedge CLOCK_50) begin
	if (CLOCK_PWM)	CE_count <=0;
	else 				CE_count <= CE_count + 1'b1;
end

LK u0 (
        .clk_clk                        (CLOCK_50),  //                       clk.clk
        .sram_0_external_interface_DQ   (SRAM_DQ),   // sram_0_external_interface.DQ
        .sram_0_external_interface_ADDR (SRAM_ADDR), //                          .ADDR
        .sram_0_external_interface_LB_N (SRAM_LB_N), //                          .LB_N
        .sram_0_external_interface_UB_N (SRAM_UB_N), //                          .UB_N
        .sram_0_external_interface_CE_N (SRAM_CE_N), //                          .CE_N
        .sram_0_external_interface_OE_N (SRAM_OE_N), //                          .OE_N
        .sram_0_external_interface_WE_N (SRAM_WE_N), //                          .WE_N
        .slidersw_export                (SW),         //                  slidersw.export
		  .hexdisplay3to0_HEX0            (HEX0),      //            hexdisplay3to0.HEX0
        .hexdisplay3to0_HEX1            (HEX1),      //                          .HEX1
        .hexdisplay3to0_HEX2            (HEX2),      //                          .HEX2
        .hexdisplay3to0_HEX3            (HEX3),      //                          .HEX3
        .hexdisplay7to4_HEX4            (HEX4),      //            hexdisplay7to4.HEX4
        .hexdisplay7to4_HEX5            (HEX5),      //                          .HEX5
        .hexdisplay7to4_HEX6            (HEX6),      //                          .HEX6
        .hexdisplay7to4_HEX7            (HEX7),      //                          .HEX7
//        .ledgreen_export                (LEDG),      //                  ledgreen.export
//        .ledred_export                  (LEDR),      //                    ledred.export
        .keys_export                    (KEY),       //                      keys.export
		  .encoders_export					 (encodersIn),
		  .microseconds_export				 (microseconds),
		  .isrbits_export						 (latencyreg),
		  .rdencoder_export						(enc_count),		//input
		  .motormagn_export				    (motormagn),			//input
		  .motorvolt_export				    (motorvolt),			//output
		  .beamsensor_export					 (beam)
		  );

assign LEDR = SW;  // if you want this, disable .ledred_export line above
assign motormagn[31:10] = {(23){motormagn[9]}};

//PWM pwm1(
//		.clk_in			 (CLOCK_50),
//		.CE_in			 (CLOCK_PWM),
//		.synch_reset_in (~KEY[0]),
//		.PWM_data_input (SW[9:0]),
//		.signmode       (SW[17]),
//		.PWM_out			 (GPIO_0[2]),
//		.dirout			 (GPIO_0[1:0])
//);

pwm pwm1(
		.clk				 (CLOCK_50),
		.CE				 (CLOCK_PWM),
		.OE				 (1'b1),
		.synch_reset	 (~KEY[0]),
		.data_in			 (motorvolt[9:0]),
		.out				 (GPIO_0[2]),
		.dir				 (GPIO_0[1:0]),
		.cmp_magn		 (motormagn[9:0])
);

encoder e0 (
			.clk		(CLOCK_50),
			.synch_reset	(~KEY[0]),
			.chA		(encodersIn[1]),
			.chB		(encodersIn[0]),
			.count	(enc_count)
);

endmodule
