// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. ZhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	DE2 TOP LEVEL
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Chen       :| 05/08/19  :|      Initial Revision
//   V1.1 :| Johnny Chen       :| 05/11/16  :|      Added FLASH Address FL_ADDR[21:20]
//   V1.2 :| Johnny Chen       :| 05/11/16  :|		Fixed ISP1362 INT/DREQ Pin Direction.   
//   V1.3 :| Johnny Chen       :| 05/11/16  :|		Added the Dedicated TV Decoder Line-Locked-Clock Input for DE2 v2.X PCB.
// --------------------------------------------------------------------

//LK: 5/4/2011. To avoid this error: "Error: Can't place multiple pins assigned to pin location Pin_AE24 (IOC_X65_Y2_N2)"
//		Goto Assignments->Device->Device and Pin Options ... ->Dual Purpose Pins  
//			Change nCEO to "use as regular IO" from  "Use as programming pin" (double click in table right hand column and use drop down menu).
// Modifier: Nguyen Xuan Anh
// Date: 14/05/2019

 module Lab12(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_50,						//	50 MHz
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

		////////////////////	GPIO	////////////////////////////
		GPIO_1,							//	GPIO Connection 1
		
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		
		////////////////////Encoder///////////////////
		encoderain, 
		encoderbin, 
		oscilloscope,
		latency,
		
		Hbridge_InA, //GPIO_0[0]
		Hbridge_InB, //GPIO_0[1]
		Hbridge_PWM, //GPIO_0[2]
		beam,			//GPIO_0[5]
		pid_out, 
		microseconds
	);

////////////////////////	Clock Input	 	////////////////////////
input			CLOCK_50;				//	50 MHz
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	[17:0]	SW;						//	Toggle Switch[17:0]
////////////////////////// Encoder//////////////////////////////
input encoderain;
input encoderbin;
input beam;
///////////////////////////Hbridge///////////////////////////////
output Hbridge_InA; //GPIO_0[0]
output Hbridge_InB; //GPIO_0[1]
output Hbridge_PWM; //GPIO_0[2]
output oscilloscope;
output latency;
output [9:0] pid_out;
output [31:0] microseconds;
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

////////////////////////	GPIO	////////////////////////////////
output   [2:0] GPIO_1;					//	GPIO Connection 

////////////////////////	NIOS MODULE	////////////////////////////////

nios_system  p0(
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
        .ledgreen_export                (LEDG),      //                  ledgreen.export
		//.ledred_export                  (LEDR),      //                    ledred.export
		  .encoderain_export  			(encoderain),
		  .encoderbin_export  			(encoderbin),
		  .keys_export                    (KEY),        //                      keys.export
		  .microseconds_export            (microseconds),
		//.motorvoltage_export 			(motorvoltage),
		  .beam_export						(beam_out),
		  .pid_out_export              (pid_out)
		//.oscilloscope_export           (oscilloscope)			
	);

assign LEDR = SW; // Connect LED_red to SW

wire tempIn_A;
wire tempIn_B;

reg dir;

assign tempIn_A = dir? 1 :0;
assign tempIn_B = dir? 0 :1;
 
assign Hbridge_InA = tempIn_A;
assign Hbridge_InB = tempIn_B;



/*
////////////////////	 unsigned  PWM MODULES	/////////////////  
//////////////// Change CE count as well////////

reg[3:0] CEcount;
wire CE10MHz = (CEcount==4);

always@(posedge CLOCK_50)
begin
	if(CE10MHz)		CEcount <=0;
	else			CEcount <= CEcount+1'b1;
end
 
 assign Hbridge_PWM=out;
 parameter PWM_IN_SIZE = 9;
 
 assign GPIO_1[0]=out;
 reg out; 
 reg [PWM_IN_SIZE-1:0] count = 0; 
 
 always @(posedge CLOCK_50) 
 begin
	if (!KEY[0]) 	out <= 0;
	else if (CE10MHz)	
    begin
		count = count+1;
		if (count<=SW[8:0])	out <=1'b1; 
		else 						out <= 1'b0;	
	end
end
*/


/*
assign Hbridge_PWM=out;

// Not update the desired speed
unsignedpwm(
.clk_in (CLOCK_50), 
.CE_in (CE10MHz),
.synch_reset_in (!KEY[0]), 
.PWM_data_in (SW[9:0]), 
.PWM_out (out)
);
*/



/////////////////signed  PWM Module///////////
///// Change CE count as well	/////////

reg[3:0] CEcount;
wire CE10MHz = (CEcount==4);

always@(posedge CLOCK_50)
begin
	if(CE10MHz)
		CEcount <=0;
	else
		CEcount <= CEcount+1'b1;
end

///////////////////////////////////

assign Hbridge_PWM = out;
parameter PWM_IN_SIZE = 10;
reg signed [PWM_IN_SIZE-1:0] value;
reg out;
	 
reg [PWM_IN_SIZE-2:0] count = 0; 
wire [PWM_IN_SIZE-1:0] magn_temp = (value[PWM_IN_SIZE-1]? 1'b0-value : value);
reg [PWM_IN_SIZE-1:0] magn;  
localparam [PWM_IN_SIZE-2:0] maxvalue = {(PWM_IN_SIZE-1){1'b1}}; 
reg dir1;

always @(posedge CLOCK_50) 
begin 
	value <= pid_out;//SW[9:0]; 
	if (!KEY[0]) 
	begin 
	    count <= 0; 
		magn <= magn_temp;
		dir1 <= value[9];
	end
	else if (CE10MHz) 
	begin 
		if (count == maxvalue) 
		begin 
			dir1 <= value[9]; 
			magn <= magn_temp; 
		end 
		
		count <= count + 1'b1;
		dir <= dir1; 
		if (count < magn) 	out <= 1'b1; 
		else 				out <= 1'b0; 
	end
end	


/////$$$$$$$$$$$// for timer //$$$$$$$$$$$$/////
reg[6:0] CEcount1;
reg [31:0] microseconds;
wire CE_micro = (CEcount1 == 49);

always@(posedge CLOCK_50)
	if(CE_micro) 	CEcount1 <= 0;
	else 			CEcount1 <= CEcount1 + 1'b1;

always@(posedge CLOCK_50)
	if(CE_micro)	microseconds <= microseconds + 1'b1;


/*
/////////////////////////////// Hard Encoder ///////////////////////////////

reg As,Bs;//synchronised A,B
reg A_prev, B_prev;
reg signed [31:0] count1;
reg signed [31:0] count2;
reg signed [9:0] count3;
reg flag;

always@(posedge CLOCK_50)begin
	//prev update
	A_prev <= As;
	B_prev <= Bs;

	As<=encoderain; 
	Bs<=encoderbin;
	
	count3 <= SW[9:0];
end

always@(posedge CLOCK_50) begin	
	if(~KEY[1]) count1<=0;
	if(count1 >= 1200 || ~KEY[3]) 	count1<=0;
	else if(count1<=-1200)				count1<=0;
   else 
		begin
		flag = 1'b1;
		flag = 1'b0;
         case ({A_prev,B_prev,As,Bs})
			4'b0010: count1<=count1 - 1'b1;
			4'b1011: count1<=count1 - 1'b1;
			4'b1101: count1<=count1 - 1'b1;
			4'b0100: count1<=count1 - 1'b1;
			
			4'b0001: count1<=count1 + 1'b1;
			4'b0111: count1<=count1 + 1'b1;
			4'b1110: count1<=count1 + 1'b1;
			4'b1000: count1<=count1 + 1'b1;
			default:;// do nothing
			endcase
		end
	end

reg[6:0] hex0; assign HEX0 = hex0;
reg[6:0] hex1; assign HEX1 = hex1;
reg[6:0] hex2; assign HEX2 = hex2;
reg[6:0] hex3; assign HEX3 = hex3; 
reg[6:0] hex4; assign HEX4 = hex4; 
reg[6:0] hex5 = 7'b 1111111; assign HEX5 = hex5;
reg[6:0] hex6 = 7'b 1111111; assign HEX6 = hex6;
reg[6:0] hex7 = 7'b 1111111; assign HEX7 = hex7;
	 
always@(posedge CLOCK_50)
begin
	//............... Display encoder pulse ..................
	if (count1 < 0)	begin // Check the sign of pulse
		hex4 <= 7'b 0111111;
		count2 = -count1;
	end
	else 	begin
		hex4 <= 7'b 1111111;
		count2 = count1;
	end
	
	case (count2%10)
		0: hex0  <= 7'b 1000000;
		1: hex0  <= 7'b 1111001;
		2: hex0  <= 7'b 0100100;
		3: hex0  <= 7'b 0110000;
		4: hex0  <= 7'b 0011001;
		5: hex0  <= 7'b 0010010;
		6: hex0  <= 7'b 0000010;
		7: hex0  <= 7'b 1111000;
		8: hex0  <= 7'b 0000000;
		9: hex0  <= 7'b 0011000;
	endcase
	
	case (count2/10-(count2/100)*10)
		0: hex1  <= 7'b 1000000;
		1: hex1  <= 7'b 1111001;
		2: hex1  <= 7'b 0100100;
		3: hex1  <= 7'b 0110000;
		4: hex1  <= 7'b 0011001;
		5: hex1  <= 7'b 0010010;
		6: hex1  <= 7'b 0000010;
		7: hex1  <= 7'b 1111000;
		8: hex1  <= 7'b 0000000;
		9: hex1  <= 7'b 0011000;
	endcase
	
	case (count2/100-(count2/1000)*10)
		0: hex2  <= 7'b 1000000;
		1: hex2  <= 7'b 1111001;
		2: hex2  <= 7'b 0100100;
		3: hex2  <= 7'b 0110000;
		4: hex2  <= 7'b 0011001;
		5: hex2  <= 7'b 0010010;
		6: hex2  <= 7'b 0000010;
		7: hex2  <= 7'b 1111000;
		8: hex2  <= 7'b 0000000;
		9: hex2  <= 7'b 0011000;
	endcase
	
	case (count2/1000-(count2/10000)*10)
		0: hex3  <= 7'b 1000000;
		1: hex3  <= 7'b 1111001;
		2: hex3  <= 7'b 0100100;
		3: hex3  <= 7'b 0110000;
		4: hex3  <= 7'b 0011001;
		5: hex3  <= 7'b 0010010;
		6: hex3  <= 7'b 0000010;
		7: hex3  <= 7'b 1111000;
		8: hex3  <= 7'b 0000000;
		9: hex3  <= 7'b 0011000;
	endcase
	
	//............... Display speed ..................
	case (count3%10)
		0: hex5  <= 7'b 1000000;
		1: hex5  <= 7'b 1111001;
		2: hex5  <= 7'b 0100100;
		3: hex5  <= 7'b 0110000;
		4: hex5  <= 7'b 0011001;
		5: hex5  <= 7'b 0010010;
		6: hex5  <= 7'b 0000010;
		7: hex5  <= 7'b 1111000;
		8: hex5  <= 7'b 0000000;
		9: hex5  <= 7'b 0011000;
	endcase
	
	case (count3/10-(count3/100)*10)
		0: hex6  <= 7'b 1000000;
		1: hex6  <= 7'b 1111001;
		2: hex6  <= 7'b 0100100;
		3: hex6  <= 7'b 0110000;
		4: hex6  <= 7'b 0011001;
		5: hex6  <= 7'b 0010010;
		6: hex6  <= 7'b 0000010;
		7: hex6  <= 7'b 1111000;
		8: hex6  <= 7'b 0000000;
		9: hex6  <= 7'b 0011000;
	endcase
	
	case (count3/100-(count3/1000)*10)
		0: hex7  <= 7'b 1000000;
		1: hex7  <= 7'b 1111001;
		2: hex7  <= 7'b 0100100;
		3: hex7  <= 7'b 0110000;
		4: hex7  <= 7'b 0011001;
		5: hex7  <= 7'b 0010010;
		6: hex7  <= 7'b 0000010;
		7: hex7  <= 7'b 1111000;
		8: hex7  <= 7'b 0000000;
		9: hex7  <= 7'b 0011000;
	endcase
		
end
*/

/////////////////////////////// PID Controller ///////////////////////////////



/////////////////////////////////////////////	
endmodule 
