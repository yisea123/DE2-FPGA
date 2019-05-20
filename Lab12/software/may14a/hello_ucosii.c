
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
#include "system.h"
#include <time.h>
#include <math.h>

#include"alt_types.h"
#include "altera_up_avalon_parallel_port.h"
#include "sys/alt_irq.h"
#define false 0
#define true 1
typedef INT8U bool;

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    PIDtask_stk[TASK_STACKSIZE];
OS_STK    tunePIDtask_stk[TASK_STACKSIZE];
OS_STK    Beamtask_stk[TASK_STACKSIZE];

INT8U err;
#define CE(x) if ((err = x) != OS_NO_ERR) \
	printf("Runtime error: %d line %d - see ucos_ii.h\n", err, __LINE__);

///////////////// Declare events ////////////////
OS_EVENT *Sem;
//OS_EVENT *SemBeam;
//OS_EVENT *SemUpdatePos;
//OS_EVENT *SemKeyPress;

///////////////// Declare ports ////////////////
alt_up_parallel_port_dev *usecs_dev;
alt_up_parallel_port_dev *sw_dev;
alt_up_parallel_port_dev *ledgreen_dev;
alt_up_parallel_port_dev *ledred_dev;
alt_up_parallel_port_dev *hex3to0_dev;
alt_up_parallel_port_dev *hex7to4_dev;
alt_up_parallel_port_dev *pidout_dev;
alt_up_parallel_port_dev *encoderinA;
alt_up_parallel_port_dev *encoderinB;
alt_up_parallel_port_dev *beam_dev;

////////////////// Declare variables ///////////////
static int start_time;
int pid_time = 0;
volatile int enc_tick = 0;
volatile int sw = 0;
int sw_digit[8];
unsigned int key;
int ref_angle = 0;
int Kpid[3] = {4, 1, 10};

/* Definition of Task Priorities */

#define PIDtask_PRIORITY    	1
#define tunePIDtask_PRIORITY    3
#define Beamtask_PRIORITY		5

////////////////////// Function prototype /////////////////////
void * ENC_A_context;
void * ENC_B_context;
void * BEAM_context;
void * KEY_context;
void OpenPortDevs(void);
int display(int);
static void IRQ_encoderAin(void *);
static void IRQ_encoderBin(void *);
static void IRQ_SWITCHES(void *);
static void IRQ_beam(void *);
int motorVolt(int);

/*Open ports*/
void OpenPortDevs(void){
	// For timer
	sw_dev = alt_up_parallel_port_open_dev("/dev/SliderSW");
	if (sw_dev == NULL) printf("Failed to open sw_dev\n");
	else printf("Opened sw_dev\n");
	// For timer
	usecs_dev = alt_up_parallel_port_open_dev("/dev/PIO_usecs");
	if (usecs_dev == NULL) printf("Failed to open usecs_dev\n");
	else printf("Opened usecs_dev\n");
	// Green LED
	ledgreen_dev = alt_up_parallel_port_open_dev("/dev/LEDGreen");
	if (ledgreen_dev == NULL) printf("Failed to open ledgreen_dev\n");
	else printf("Opened ledgreen_dev\n");
    // Red LED
	ledred_dev = alt_up_parallel_port_open_dev("/dev/LEDred");
	if (ledred_dev == NULL) printf("Failed to open ledred_dev\n");
	else printf("Opened ledred_dev\n");
	// Hex30
	hex3to0_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays3to0");
	if (hex3to0_dev == NULL) printf("Failed to open hex3to0_dev\n");
	else printf("Opened hex3to0_dev\n");
    // Hex74
	hex7to4_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays7to4");
	if (hex7to4_dev == NULL) printf("Failed to open hex7to4_dev\n");
	else printf("Opened hex7to4_dev\n");
	// Connect to PWM in Verilog
	pidout_dev = alt_up_parallel_port_open_dev("/dev/PID_out");
	if (pidout_dev == NULL) printf("Failed to open PID_out_dev\n");
	else printf("Opened PID_out_dev\n");
	// Encoder A
	encoderinA = alt_up_parallel_port_open_dev("/dev/EncoderAin");
	if (encoderinA == NULL) printf("Failed to open EncoderA\n");
	else printf("Opened Successful EncoderA\n");
	// Encoder B
	encoderinB = alt_up_parallel_port_open_dev("/dev/EncoderBin");
	if (encoderinB == NULL) printf("Failed to open EncoderB\n");
	else printf("Opened Successful EncoderB\n");
	// For beam
	beam_dev = alt_up_parallel_port_open_dev("/dev/Beam");
	if (beam_dev == NULL) printf("Failed to open beam\n");
	else printf("Opened Successful beam\n");
}

int InitMicrosecs(void){ return alt_up_parallel_port_read_data(usecs_dev); }

int GetMicrosecs(unsigned long int start_t){	return (alt_up_parallel_port_read_data(usecs_dev) - start_t); }

void int_to_bin_digit(unsigned int in, int count, int* out)
{
	int i;
	for (i = count; i >= 0; i--)
	{
		int k = in >> i;
		if (k & 1) out[i] = 1;
		else out[i] = 0;
	}
}

///////////////// Display HEX ///////////////
int display(int value)
{
	switch (value)
	{
		case -1:	return (0x40);
		case 0:		return (0x3F);
		case 1:		return (0x6);
		case 2:		return (0x5B);
		case 3:		return (0x4F);
		case 4:		return (0x66);
		case 5:		return (0x6D);
		case 6:		return (0x7D);
		case 7:		return (0x07);
		case 8:		return (0x7F);
		case 9:		return (0x6F);
		default:	return (0x0);
	}
	return (0x0);
}

///////////////// Display set position ///////////////
void displayRef(int value)
{
	int angle = value;
	int DIGITS[4];
	int k;
	if(angle <0)
	{
		DIGITS[3] = -1;
		angle = -angle;
	}
	else
	{
		DIGITS[3] = 10;
	}
	for(k=0;k<3;k++)
	{
		DIGITS[k] = angle % 10;
		angle /= 10;
	}
	alt_up_parallel_port_write_data(hex7to4_dev, display(DIGITS[3])<<24 | display(DIGITS[2])<<16 | display(DIGITS[1])<<8 | display(DIGITS[0])<<0);
	return;
}

///////////////// Display set position ///////////////
void displayAct(int value)
{
	int angle = value;
	int DIGITS[4];
	int k;
	if(angle <0)
	{
		DIGITS[3] = -1;
		angle = -angle;
	}
	else
	{
		DIGITS[3] = 10;
	}
	for(k=0;k<3;k++)
	{
		DIGITS[k] = angle % 10;
		angle /= 10;
	}
	alt_up_parallel_port_write_data(hex3to0_dev, display(DIGITS[3])<<24 | display(DIGITS[2])<<16 | display(DIGITS[1])<<8 | display(DIGITS[0])<<0);
	return;
}

///////////////   ISR Encoder A  //////////////////////
static void IRQ_encoderAin(void *context)
{
	OSSemPend(Sem,0,&err);

	IOWR(ENCODERAIN_BASE, 3, 0);
	if (IORD(ENCODERAIN_BASE, 0) ^ IORD(ENCODERBIN_BASE, 0))
		++enc_tick;
	else
		--enc_tick;
	OSSemPost(Sem);
}

///////////////   ISR Encoder B  //////////////////////
static void IRQ_encoderBin(void *context)
{
	OSSemPend(Sem,0,&err);

	IOWR(ENCODERBIN_BASE, 3, 0x01);

	if (!(IORD(ENCODERAIN_BASE, 0) ^ IORD(ENCODERBIN_BASE, 0)))
		++enc_tick;
	else
		--enc_tick;

	OSSemPost(Sem);
}

///////////////   ISR Switches  //////////////////////
void IRQ_SWITCHES(void* context)
{
	OSSemPend(Sem,0,&err);
	IOWR(SLIDERSW_BASE,3,0x01);
	sw = alt_up_parallel_port_read_data(sw_dev);

	int_to_bin_digit(sw, 8, sw_digit);

	printf("@@@@@@@@@@@@@@ sw_dev = %d @@@@@@@@@@@@@@@@\n", sw);

	if((sw_digit[0] == 0) && (sw_digit[1] == 0))		ref_angle = 0;
	else if ((sw_digit[1] == 0) && (sw_digit[0] == 1))	ref_angle = 90;
	else if ((sw_digit[1] == 1) && (sw_digit[0] == 0))	ref_angle = 180;
	else if ((sw_digit[1] == 1) && (sw_digit[0] == 1))	ref_angle = 270;
	//printf("sw_digit[0]=%d, sw_digit[1]=%d, sw_digit[2]=%d\n",sw_digit[0],sw_digit[1],sw_digit[2]);
	printf("sw = %d, ref_angle = %d\n", sw, ref_angle);
	displayRef(ref_angle);

	OSSemPost(Sem);
	return;
}

///////////////   ISR Keys  //////////////////////
void IRQ_KEYS(void* context)
{
	OSSemPend(Sem,0,&err);
	IOWR(KEYBUTTONS_BASE,3,0x01);

	key = IORD(KEYBUTTONS_BASE, 0);

	IOWR(SLIDERSW_BASE,3,0x01);
	sw = alt_up_parallel_port_read_data(sw_dev);
	int_to_bin_digit(sw, 8, sw_digit);

	switch(key)
	{
		case 1: // KEY 0 - Reset PID
			Kpid[0] = 0;
			Kpid[1] = 0;
			Kpid[2] = 0;
			break;
		case 8: // KEY 1 - Tune Kp
			if(sw_digit[2] == 0) Kpid[0]++;
			else 	   			 Kpid[0]--;
			break;
		case 4: // KEY 2 - Tune Ki
			if(sw_digit[2] == 0) Kpid[1]++;
			else 	   			 Kpid[1]--;
			break;
		case 2: // KEY 3 - Tune Kd
			if(sw_digit[2] == 0) Kpid[2]++;
			else 	   			 Kpid[2]--;
			break;
	}

	printf("Kp: %d, Ki: %d, Kd: %d\n", Kpid[0], Kpid[1], Kpid[2]);

	OSSemPost(Sem);
	return;
}

///////////////   ISR beam sensor  //////////////////////
static void IRQ_beam(void *context)
{
	OSSemPend(Sem,0,&err);

	IOWR(BEAM_BASE, 3, 0x01);

	OSSemPost(Sem);
}

/////////////////////   PID function  //////////////////////
int motorVolt(new_err) {
	static int old_err = 0;
	static int err_acc = 0;
	static int pwm = 0;

	err_acc += new_err;
	if(new_err > 0)
		pwm = (Kpid[0]*new_err + Kpid[2]*(new_err-old_err) + (128+Kpid[1]*err_acc)/256+128)/256;
	else
		pwm = -((Kpid[0]*abs(new_err) + Kpid[2]*abs(new_err-old_err) + (128+Kpid[1]*abs(err_acc))/256+128)/256);

	old_err = new_err;
	return pwm;
}

////////////////////// PID Task ////////////////////////
void PIDtask(void* pdata)
{
	int a_err = 0;
	int volt = 0;
	while (1)
	{
		OSSemPend(Sem,0,&err);

		a_err = ref_angle*10/3 - enc_tick;

		// Convert volt to pwm signal
		start_time = InitMicrosecs();
		volt = motorVolt(a_err);
		pid_time = GetMicrosecs(start_time);
		printf("PID execution time = %d us\n", pid_time);

		// send pwm signal to port PIDout
		alt_up_parallel_port_write_data(pidout_dev, volt);

		printf("Set Position:     %d, Angle: %d\n",ref_angle*10/3, ref_angle);
		printf("Encoder feedback: %d, Angle: %d\n", enc_tick, enc_tick*3/10);
		printf("error: %d, angle_error %d\n", a_err, a_err*3/10);
		printf("Voltage to PWM: %d\n\n",volt);

		displayAct(enc_tick*3/10);

		OSSemPost(Sem);
		OSTimeDlyHMSM(0, 0, 0, 10); // Run every 10 miliseconds
	}
}

////////////////////// Tune PID Task ////////////////////////
void tunePIDtask(void* pdata)
{
	while (1)
	{
		OSSemPend(Sem,0,&err);
		key = IORD(KEYBUTTONS_BASE, 0);

		IOWR(SLIDERSW_BASE,3,0x01);
		sw = alt_up_parallel_port_read_data(sw_dev);
		int_to_bin_digit(sw, 8, sw_digit);

		switch(key)
		{
			case 1: // KEY 0 - Reset PID
				Kpid[0] = 0;
				Kpid[1] = 0;
				Kpid[2] = 0;
				break;
			case 8: // KEY 1 - Tune Kp
				if(sw_digit[2] == 0) Kpid[0]++;
				else 	   			 Kpid[0]--;
				break;
			case 4: // KEY 2 - Tune Ki
				if(sw_digit[2] == 0) Kpid[1]++;
				else 	   			 Kpid[1]--;
				break;
			case 2: // KEY 3 - Tune Kd
				if(sw_digit[2] == 0) Kpid[2]++;
				else 	   			 Kpid[2]--;
				break;
		}

		printf("Kp: %d, Ki: %d, Kd: %d\n", Kpid[0], Kpid[1], Kpid[2]);
		OSSemPost(Sem);
		OSTimeDlyHMSM(0, 0, 0, 500); // Update every 100 miliseconds
	}
}

////////////////////// Beam sensor Task ////////////////////////
void Beamtask(void* pdata)
{
	unsigned long int recordedTime[3] = {0, 0, 0};
	unsigned int timePtr = 0;
	unsigned long int startTime = 0;
	int speed;

	while (1)
	{
		OSSemPend(Sem, 200,&err);

		if (err == OS_NO_ERR)
		{
			switch (timePtr)
			{
				case 0:
					startTime = InitMicrosecs();
					timePtr++;
					break;
				case 1:
					recordedTime[0] = GetMicrosecs(startTime);
					timePtr++;
					break;
				case 2:
					recordedTime[1] = GetMicrosecs(startTime) - recordedTime[0];
					timePtr++;
					break;
				case 3:
					recordedTime[2] = GetMicrosecs(startTime) - recordedTime[1] - recordedTime[0];
					speed = 40*1000000 / (recordedTime[0]+recordedTime[1]+recordedTime[2]); // 40 is length of the beam, unit: mm/us = 10^6 mm/s

					if(recordedTime[0] >= recordedTime[1] && recordedTime[0] >= recordedTime[2])
						printf("CW, 0 = %d, 1 = %d, 2 = %d, speed =  %d (mm/s)\n", recordedTime[0], recordedTime[1], recordedTime[2], speed);
					else if (recordedTime[2] >= recordedTime[1] && recordedTime[2] >= recordedTime[0])
						printf("CCW, 0 = %d, 1 = %d, 2 = %d, speed = %d (mm/s)\n", recordedTime[0], recordedTime[1], recordedTime[2], speed);
					else
						printf("DIR ERROR\n");

					timePtr = 0;
					break;
				default:
					printf("Beam case error\n");
					break;
			}
		}
		else if (err == OS_ERR_TIMEOUT)
		{
			printf("OS_ERR_TIMEOUT\n");
			timePtr = 0;
			startTime = 0;
			recordedTime[0] = 0;
			recordedTime[1] = 0;
			recordedTime[2] = 0;
			recordedTime[3] = 0;
		}
		else printf("Beam case error: %d\n", err);

		OSSemPost(Sem);
		OSTimeDlyHMSM(0, 0, 0, 3); // Update every 3 miliseconds
	}
}

//////////////////////////@@@@@@@@@@@@@@/////////////////////////
/////////////////////////////////////////////////////////////////
/* The main function creates two task and starts multi-tasking */
int main(void)
{
  Sem = OSSemCreate(1);
  OpenPortDevs();

  OSTaskCreateExt(PIDtask,
                  NULL,
                  (void *)&PIDtask_stk[TASK_STACKSIZE-1],
                  PIDtask_PRIORITY,
                  PIDtask_PRIORITY,
                  PIDtask_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

  /*OSTaskCreateExt(tunePIDtask,
                  NULL,
                  (void *)&tunePIDtask_stk[TASK_STACKSIZE-1],
                  tunePIDtask_PRIORITY,
                  tunePIDtask_PRIORITY,
                  tunePIDtask_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);*/
  /*OSTaskCreateExt(Beamtask,
                  NULL,
                  (void *)&Beamtask_stk[TASK_STACKSIZE-1],
                  Beamtask_PRIORITY,
                  Beamtask_PRIORITY,
                  Beamtask_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);*/

  IOWR(ENCODERAIN_BASE,2,0x01);
  IOWR(ENCODERBIN_BASE,2,0x01);
  IOWR(SLIDERSW_BASE,2,0xf);
  IOWR(KEYBUTTONS_BASE,2,0xf);

  alt_irq_register(ENCODERAIN_IRQ, NULL,(void *)IRQ_encoderAin);
  alt_irq_register(ENCODERBIN_IRQ, NULL,(void *)IRQ_encoderBin);
  alt_irq_register(SLIDERSW_IRQ, NULL,(void *)IRQ_SWITCHES);
  alt_irq_register(KEYBUTTONS_IRQ, NULL,(void *)IRQ_KEYS);

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
