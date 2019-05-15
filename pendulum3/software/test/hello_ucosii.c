/*************************************************************************
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.      *
* All rights reserved. All use of this software and documentation is     *
* subject to the License Agreement located at the end of this file below.*
**************************************************************************
* Description:                                                           *
* The following is a simple hello world program running MicroC/OS-II.The * 
* purpose of the design is to be a very simple application that just     *
* demonstrates MicroC/OS-II running on NIOS II.The design doesn't account*
* for issues such as checking system call return codes. etc.             *
*                                                                        *
* Requirements:                                                          *
*   -Supported Example Hardware Platforms                                *
*     Standard                                                           *
*     Full Featured                                                      *
*     Low Cost                                                           *
*   -Supported Development Boards                                        *
*     Nios II Development Board, Stratix II Edition                      *
*     Nios Development Board, Stratix Professional Edition               *
*     Nios Development Board, Stratix Edition                            *
*     Nios Development Board, Cyclone Edition                            *
*   -System Library Settings                                             *
*     RTOS Type - MicroC/OS-II                                           *
*     Periodic System Timer                                              *
*   -Know Issues                                                         *
*     If this design is run on the ISS, terminal output will take several*
*     minutes per iteration.                                             *
**************************************************************************/


#include <stdio.h>
#include "includes.h"
#include "system.h" // IO addresses & IRQs of ports
#include "stdlib.h"
#include "alt_types.h"
#include "altera_up_avalon_parallel_port.h"
#include "sys/alt_irq.h" //needed only if using interrupts
#define false 0
#define true 1
typedef INT8U bool;

INT8U err;
#define CE(x) if ((err = x) != OS_NO_ERR) \
 printf("Runtime error: %d line %d - see ucos_ii.h\n", err, __LINE__);


/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      3


alt_up_parallel_port_dev 	*hexdisplays7to4_dev,
							*hexdisplays3to0_dev,
							*PIO_RDencoder_dev,
							*PIO_motormagn_dev,
							*PIO_motorvolt_dev,
							*PIO_beamsensor_dev,
							*PIO_usecs_dev;


// lookup table for hex displays
int hexLU[] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};

// global variables
int angle, angle_hw, EncCount_hw;

int start_time;

/*
 * =====================================================================
 * ==== UTILITY FUNCTIONS ==============================================
 * =====================================================================
 */

void OpenPortDevs(void){
	PIO_RDencoder_dev = alt_up_parallel_port_open_dev("/dev/PIO_RDencoder");
	if (PIO_RDencoder_dev == NULL) printf("Failed to open PIO_RDencoder\n");
	else printf("Opened PIO_RDencoder\n");

	PIO_motormagn_dev = alt_up_parallel_port_open_dev("/dev/PIO_motormagn");
	if (PIO_motormagn_dev == NULL) printf("Failed to open PIO_motormagn\n");
	else printf("Opened PIO_motormagn\n");

	PIO_beamsensor_dev = alt_up_parallel_port_open_dev("/dev/PIO_beamsensor");
	if (PIO_beamsensor_dev == NULL) printf("Failed to open PIO_beamsensor\n");
	else printf("Opened PIO_beamsensor\n");

	PIO_motorvolt_dev = alt_up_parallel_port_open_dev("/dev/PIO_motorvolt");
	if (PIO_motorvolt_dev == NULL) printf("Failed to open PIO_motorvolt\n");
	else printf("Opened PIO_motorvolt\n");

	hexdisplays7to4_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays7to4");
	if (hexdisplays7to4_dev == NULL) printf("Failed to open hexdisplays7to4\n");
	else printf("Opened hexdisplays7to4\n");

	hexdisplays3to0_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays3to0");
	if (hexdisplays3to0_dev == NULL) printf("Failed to open hexdisplays3to0\n");
	else printf("Opened hexdisplays3to0\n");

	PIO_usecs_dev = alt_up_parallel_port_open_dev("/dev/PIO_usecs");
	if (PIO_usecs_dev == NULL) printf("Failed to open PIO_usecs\n");
	else printf("Opened PIO_usecs\n");
}

void InitMicrosecs(void){
	start_time = alt_up_parallel_port_read_data(PIO_usecs_dev);
}

int four7seg(int num){
	//int dig2 = num/10;
	//int dig1 = num - dig2*10;
	int hex2[10] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F};
	return (((num<0)?0x40:0x00) << 24) +	// sign bit
	  				(hex2[(abs(num)/100)%10] << 16) +
	  				(hex2[(abs(num)/10)%10] << 8) +
	  				(hex2[abs(num)%10]);
	//return (hex2[dig2]<<8) | hex2[dig1]; //(hex2[dig2]*10) |
}

/*
 * =====================================================================
 * ==== INTERRUPT HANDLERS =============================================
 * =====================================================================
 */
/* Executes when either encoder phase changes (only for software encoder) */
static void encoder_isr(void* context, alt_u32 id) {
	static int levelcapture;
	static int levelcaptureold = 0x0;
	static int leveledges;

	volatile int* angle_ptr = (volatile int*) context;

	levelcapture = IORD(PIO_ENCODERS_BASE,0);

	leveledges = ((levelcapture & 0x3)<<2 | (levelcaptureold & 0x3));

	switch (leveledges) {
	case 0x8: case 0xE: case 0x1: case 0x7:
		(*angle_ptr)++; break;
	case 0x4: case 0xD: case 0xB: case 0x2:
		(*angle_ptr)--; break;
	}

	levelcaptureold = levelcapture;

	if (angle>1000)  angle=-999;
	else if (angle<-999) angle=999;

	IOWR(PIO_ENCODERS_BASE,3,0x0); // write to edge capture register to reset interrupt

	IOWR(PIO_ISRBITS_BASE,0,((levelcapture>>1)?0x1:0x0)); // output A encoder value, for interrupt latency check

	return;
}

/* Executes on change of beam sensor reading */
static void beamsensor_isr(void* context, alt_u32 id) {
	int beam[4];
	static int idx = 0;

	beam[idx]= alt_up_parallel_port_read_data(PIO_usecs_dev);

	idx++; idx%=4;

	printf(".");
}


/*
 * ========================================================
 * ==== TASK FUNCTIONS ====================================
 * ========================================================
 */

/* Prints encoder angle to HEX7-4, '.' to console */
void print_angle(void* pdata)
{
  while (1)
  { 
  	static int keycapture;
  	keycapture   = IORD(KEYBUTTONS_BASE,0);

		if ((keycapture & 0x1)) {
			angle=0;
		}

		static int angledisp;
		static int degreemode;

		degreemode = (IORD(SLIDERSW_BASE,0)>>15) & 0x1; // check SW15

		if (degreemode) {
			angledisp = (angle*180)/1000;
		} else {
			angledisp = angle;
		}
  	IOWR(HEXDISPLAYS7TO4_BASE,0,
  				(((angledisp<0)? 0x40 :
  						((abs(angledisp)/1000)%10) ? (hexLU[(abs(angledisp)/1000)%10]):0x00) << 24) +	// sign bit
  				(hexLU[(abs(angledisp)/100)%10] << 16) +
  				(hexLU[(abs(angledisp)/10)%10] << 8) +
  				(hexLU[abs(angledisp)%10]));

    static int motormagn;

    motormagn = alt_up_parallel_port_read_data(PIO_motormagn_dev);

    //printf("%d", motormagn);
    /*if (motormagn>512) {
    	motormagn = -motormagn;
    }*/
    alt_up_parallel_port_write_data(hexdisplays3to0_dev, four7seg(motormagn));

    //printf(" %d\n", motormagn);


  	printf(".");
    OSTimeDlyHMSM(0, 0, 0, 20);
  }
}

void print_angle_hw(void* pdata)
{
  while (1)
  {
  	//static int keycapture;
  	//keycapture   = IORD(KEYBUTTONS_BASE,0);
  	angle_hw = alt_up_parallel_port_read_data(PIO_RDencoder_dev);

	static int angledisp;
	static int degreemode;

	degreemode = (IORD(SLIDERSW_BASE,0)>>15) & 0x1; // check SW15

	if (degreemode) {
		angledisp = (angle_hw*180)/1000;
	} else {
		angledisp = angle_hw;
	}

  	alt_up_parallel_port_write_data(hexdisplays7to4_dev, four7seg(angledisp));



    static int motormagn;

    motormagn = alt_up_parallel_port_read_data(PIO_motormagn_dev);

    printf("%d", motormagn);
    if (motormagn>512) {
    	motormagn = -motormagn;
    }
    alt_up_parallel_port_write_data(hexdisplays3to0_dev, four7seg(motormagn));

    printf(" %d\n", motormagn);

    OSTimeDlyHMSM(0, 0, 0, 20);
  }
}

void pid_control_update(void* pdata)
{

	int Kp = 2400,
		Ki = 120,
		Kd = 24000;
	//	int Kp = 1500,
	//		Ki = 130,
	//		Kd = 17500;
	int motorvolt = 0,
		err_prev = 0,
		err_n, err_sum, desired_pos;
	desired_pos = 500;

	int encCOUNT[1000], counter=0;
	int encCOUNT2[1000];


  while (1);//counter<1000)
  {

	static int angledisp;
	static int degreemode;

	//EncCount_hw = alt_up_parallel_port_read_data(PIO_RDencoder_dev);
	EncCount_hw = IORD(PIO_RDENCODER_BASE,0);
	degreemode = (IORD(SLIDERSW_BASE,0)>>15) & 0x1; // check SW15

	if (degreemode) {
		angledisp = (EncCount_hw*180)/1000;
	} else {
		angledisp = EncCount_hw;
	}

  	//alt_up_parallel_port_write_data(hexdisplays7to4_dev, four7seg(angledisp));
	IOWR(HEXDISPLAYS7TO4_BASE,0,four7seg(angledisp));
	printf(".");

    //printf("-%d:%d", EncCount_hw, motorvolt);
    OSTimeDlyHMSM(0, 0, 0, 10);
  }
  int i;
  for (i=0; i<1000; i++){
	  printf("%d\n", encCOUNT2[i]);
  }
  alt_up_parallel_port_write_data(PIO_motorvolt_dev, 0);
}

int main(void)
{
	OpenPortDevs();
	InitMicrosecs();

	/*IOWR(PIO_ENCODERS_BASE,2,0x3);
	void* angle_ptr = (void*) &angle;
	alt_irq_register(PIO_ENCODERS_IRQ,
			angle_ptr,
			encoder_isr);*/

	/*IOWR(PIO_BEAMSENSOR_BASE,2,0x1);
	alt_irq_register(PIO_BEAMSENSOR_IRQ,
			NULL,
			beamsensor_isr);*/

	OSTaskCreateExt(pid_control_update,
                  NULL,
                  (void *)&task1_stk[TASK_STACKSIZE-1],
                  TASK1_PRIORITY,
                  TASK1_PRIORITY,
                  task1_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);
  OSStart();
  return 0;
}

/******************************************************************************
*                                                                             *
* License Agreement                                                           *
*                                                                             *
* Copyright (c) 2004 Altera Corporation, San Jose, California, USA.           *
* All rights reserved.                                                        *
*                                                                             *
* Permission is hereby granted, free of charge, to any person obtaining a     *
* copy of this software and associated documentation files (the "Software"),  *
* to deal in the Software without restriction, including without limitation   *
* the rights to use, copy, modify, merge, publish, distribute, sublicense,    *
* and/or sell copies of the Software, and to permit persons to whom the       *
* Software is furnished to do so, subject to the following conditions:        *
*                                                                             *
* The above copyright notice and this permission notice shall be included in  *
* all copies or substantial portions of the Software.                         *
*                                                                             *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     *
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         *
* DEALINGS IN THE SOFTWARE.                                                   *
*                                                                             *
* This agreement shall be governed in all respects by the laws of the State   *
* of California and by the laws of the United States of America.              *
* Altera does not recommend, suggest or require that this reference design    *
* file be used in conjunction or combination with any other product.          *
******************************************************************************/
