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
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    keyTask_stk[TASK_STACKSIZE];
OS_STK    PIDtask_stk[TASK_STACKSIZE];

alt_up_parallel_port_dev *usecs_dev;
alt_up_parallel_port_dev *hex3to0_dev;
alt_up_parallel_port_dev *hex7to4_dev;
//alt_up_parallel_port_dev *twiddlingBit_dev;
alt_up_parallel_port_dev *pidout;

int enc_tick = 0;
OS_EVENT *SemDisplay;
OS_EVENT *SemBeam;
OS_EVENT *SemUpdatePos;
OS_EVENT *SemKeyPress;
INT8U err;
int speed = 0;
int displayK = 0;


volatile int * twidBit = (int *) TWIDDLINGBIT_BASE;

////////////////////// Function prototype /////////////////////
void * ENC_A_context;
void * ENC_B_context;
void * BEAM_context;
void * KEY_context;
int dsp(int);
static void enc_A_ISR(void *, alt_u32);
static void enc_B_ISR(void *, alt_u32);
static void beam_ISR(void *, alt_u32);
static void key_ISR(void *, alt_u32);
void init_ISR(void);
int InitMicrosecs(void);
int GetMicrosecs(unsigned long int);
void displayAngle(int);
void displayPID(int);
//////////////////////////////////////////////////////////////

/* Definition of Task Priorities */
#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      2
#define keyTask_PRIORITY    3
#define PIDtask_PRIORITY	0

int dsp(int value) {
	switch (value) {
	case -1:
		return (0x40);
	case 0:
		return (0x3F);
	case 1:
		return (0x6);
	case 2:
		return (0x5B);
	case 3:
		return (0x4F);
	case 4:
		return (0x66);
	case 5:
		return (0x6D);
	case 6:
		return (0x7D);
	case 7:
		return (0x07);
	case 8:
		return (0x7F);
	case 9:
		return (0x6F);
	default:
		return (0x0);
	}
	return (0x0);
}

int InitMicrosecs(void){
	return alt_up_parallel_port_read_data(usecs_dev);
}
int GetMicrosecs(unsigned long int start_time){
	return alt_up_parallel_port_read_data(usecs_dev) - start_time;
}

int Kpid[3] = {0, 0, 0}; //P=~10,I=~100,D=~10
int motorVolt(new_err) {
	static int old_err = 0;
	static int err_acc = 0;
	static int pwm =0;

	err_acc += new_err;
	if(new_err>0)
		pwm = (Kpid[0]*new_err + Kpid[2]*(new_err-old_err) + (128+Kpid[1]*err_acc)/256+128)/256;
	else
		pwm = -((Kpid[0]*abs(new_err) + Kpid[2]*abs(new_err-old_err) + (128+Kpid[1]*abs(err_acc))/256+128)/256);
	old_err = new_err;
	return pwm;
}

void displayAngle(int value) {
	int angle = value / 10 * 3;
	int DIGITS[4];
	int k;
	if(angle <0) {
		DIGITS[3] = -1;
		angle = -angle;
	} else {
		DIGITS[3] = 10;
	}
	for(k=0;k<3;k++) {
		DIGITS[k] = angle % 10;
		angle /= 10;
	}
	alt_up_parallel_port_write_data(hex7to4_dev, dsp(DIGITS[3])<<24 | dsp(DIGITS[2])<<16 | dsp(DIGITS[1])<<8 | dsp(DIGITS[0])<<0);
	return;
}

void displayPID(int k) {
	int i;
	int DIGITS[3];
	int Kpid_tmp = Kpid[k];
	for(i=0;i<3;i++) {
		DIGITS[i] = Kpid_tmp % 10;
		Kpid_tmp /= 10;
	}
	alt_up_parallel_port_write_data(hex3to0_dev, dsp(k)<<24 | dsp(DIGITS[2])<<16 | dsp(DIGITS[1])<<8 | dsp(DIGITS[0])<<0);
	return;
}

int openPortDevs(void){
	int err;
	usecs_dev = alt_up_parallel_port_open_dev("/dev/PIO_usecs");
	if (usecs_dev == NULL) err++;

	hex3to0_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays3to0");
	if (hex3to0_dev == NULL) err++;

	hex7to4_dev = alt_up_parallel_port_open_dev("/dev/HexDisplays7to4");
	if (hex7to4_dev == NULL) err++;

	/*twiddlingBit_dev = alt_up_parallel_port_open_dev("/dev/twiddlingBit");
	if (twiddlingBit_dev == NULL) err++;*/

	pidout = alt_up_parallel_port_open_dev("/dev/PID_out");
		if (pidout == NULL) err++;

	return err;
}

void init_ISR(void) {
	IOWR(ENCODERAIN_BASE, 3, 0);
	alt_irq_register(ENCODERAIN_IRQ, ENC_A_context, enc_A_ISR);
	IOWR(ENCODERAIN_BASE, 2, 0x1);
	IOWR(ENCODERAIN_BASE, 3, 0x1);

	IOWR(ENCODERBIN_BASE, 3, 0);
	alt_irq_register(ENCODERBIN_IRQ, ENC_B_context, enc_B_ISR);
	IOWR(ENCODERBIN_BASE, 2, 0x1);
	IOWR(ENCODERBIN_BASE, 3, 0x1);

	IOWR(BEAMSIGNAL_BASE, 3, 0);
	alt_irq_register(BEAMSIGNAL_IRQ, BEAM_context, beam_ISR);
	IOWR(BEAMSIGNAL_BASE, 2, 0x1);
	IOWR(BEAMSIGNAL_BASE, 3, 0x1);

	IOWR(KEYBUTTONS_BASE, 3, 0);
	alt_irq_register(KEYBUTTONS_IRQ, KEY_context, key_ISR);
	IOWR(KEYBUTTONS_BASE, 2, 0xf);
	IOWR(KEYBUTTONS_BASE, 3, 0xf);
	return;
}

///////////////   ISR   //////////////////////
static void enc_A_ISR(void *isr_context, alt_u32 id) 
{
	IOWR(ENCODERAIN_BASE, 3, 0);
	if (IORD(ENCODERAIN_BASE, 0) ^ IORD(ENCODERBIN_BASE, 0))
		++enc_tick;
	else
		--enc_tick;
	OSSemPost(SemDisplay);
}

static void enc_B_ISR(void *isr_context, alt_u32 id) 
{
	IOWR(ENCODERBIN_BASE, 3, 0);
	if (!(IORD(ENCODERAIN_BASE, 0) ^ IORD(ENCODERBIN_BASE, 0)))
		++enc_tick;
	else
		--enc_tick;
	OSSemPost(SemDisplay);
}

static void beam_ISR(void *isr_context, alt_u32 id) 
{
	IOWR(BEAMSIGNAL_BASE, 3, 0);
	OSSemPost(SemBeam);
}

static void key_ISR(void *isr_context, alt_u32 id) 
{
	IOWR(KEYBUTTONS_BASE, 3, 0);
	OSSemPost(SemKeyPress);
}

//////////////////////////////////////////////

int ref_angle = 90;
void PIDtask(void* pdata)
{
	printf("PIDtask created\n");
	int angle_err = 0;
	int angle = 0;
	int volt = 0;
	while (1)
	{
		angle = enc_tick/10*3;
		angle_err = ref_angle - angle;
		volt = motorVolt(angle_err);


		//Convert volt to pwm signal

		//send pwm signal to port PIDout
		alt_up_parallel_port_write_data(pidout,0);

		printf("Angle: %d\n",angle);
		printf("error: %d\n",angle_err);
		printf("Volt: %d\n\n",volt);
		OSTimeDlyHMSM(0, 0, 0, 500);
	}
}

/* Prints "Hello World" and sleeps for three seconds */
void task1(void* pdata)
{
	printf("Task 1 created\n");
	while (1)
	{
		OSSemPend(SemDisplay, 0, NULL);
		displayAngle(enc_tick);
		displayPID(displayK);
		OSTimeDlyHMSM(0, 0, 0, 200);
	}
}
/* Prints "Hello World" and sleeps for three seconds */
void task2(void* pdata)
{
	printf("Task 2 created\n");
	unsigned long int recordedTime[3] = {0, 0, 0};
	unsigned int timePtr = 0;
	unsigned long int startTime = 0;
	while (1)
	{
		OSSemPend(SemBeam, (INT16U) 200, &err);
		if (err == OS_NO_ERR) {
			//printf("OS_NO_ERR\n");
			switch (timePtr) {
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
				speed = 40*1000000 / (recordedTime[0]+recordedTime[1]+recordedTime[2]);
				if(recordedTime[0] >= recordedTime[1] && recordedTime[0] >= recordedTime[2]) printf("CW: %d\n", speed);
				else if (recordedTime[2] >= recordedTime[1] && recordedTime[2] >= recordedTime[0]) printf("CCW: %d\n", speed);
				else printf("DIR ERROR\n");
				timePtr = 0;
				break;
				break;
			default:
				printf("Beam case error\n");
				break;
			}
	  } else if (err == OS_ERR_TIMEOUT) {
		  //printf("OS_ERR_TIMEOUT\n");
		  timePtr = 0;
		  startTime = 0;
		  recordedTime[0] = 0;
		  recordedTime[1] = 0;
		  recordedTime[2] = 0;
		  recordedTime[3] = 0;
	  } else {
		  printf("Beam case error: %d\n", err);
	  }

		OSTimeDlyHMSM(0, 0, 0, 3);
  }
}

void keyTask(void* pdata) {
	unsigned int key;
	unsigned int sw;
	while (1) {
		OSSemPend(SemKeyPress, 0, &err);
		key = IORD(KEYBUTTONS_BASE, 0);
		sw = IORD(SLIDERSW_BASE, 0) >> 15;
		switch (key) {
		case 1: //KEY 0
			if(displayK < 2) displayK++;
			else displayK = 0;
			break;
		case 2: //KEY 1 - RESET
			enc_tick = 0;
			if(sw) {
				Kpid[0] = 0;
				Kpid[1] = 0;
				Kpid[2] = 0;
			}
			break;
		case 4: //KEY 2
			switch (sw) {
			case 1:
				Kpid[0]--;
				OSSemPost(SemDisplay);
				break;
			case 2:
				Kpid[1]--;
				OSSemPost(SemDisplay);
				break;
			case 4:
				Kpid[2]--;
				OSSemPost(SemDisplay);
				break;
			default:
				break;
			}
			break;
		case 8: //KEY 3
			switch (sw) {
			case 1:
				Kpid[0]++;
				OSSemPost(SemDisplay);
				break;
			case 2:
				Kpid[1]++;
				OSSemPost(SemDisplay);
				break;
			case 4:
				Kpid[2]++;
				OSSemPost(SemDisplay);
				break;
			default:
				break;
			}
			break;
		default : //ERR
			break;
		}
		OSTimeDlyHMSM(0, 0, 0, 500);
	}
}

/* The main function creates two task and starts multi-tasking */
int main(void)
{
	init_ISR();
	openPortDevs();
	SemDisplay = OSSemCreate(1);
	SemBeam = OSSemCreate(0);
	SemUpdatePos = OSSemCreate(0);
	SemKeyPress = OSSemCreate(0);
	OSTaskCreateExt(task1,
				  NULL,
				  (void *)&task1_stk[TASK_STACKSIZE-1],
				  TASK1_PRIORITY,
				  TASK1_PRIORITY,
				  task1_stk,
				  TASK_STACKSIZE,
				  NULL,
				  0);

    OSTaskCreateExt(task2,
                  NULL,
                  (void *)&task2_stk[TASK_STACKSIZE-1],
                  TASK2_PRIORITY,
                  TASK2_PRIORITY,
                  task2_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

   OSTaskCreateExt(keyTask,
                  NULL,
                  (void *)&keyTask_stk[TASK_STACKSIZE-1],
                  keyTask_PRIORITY,
                  keyTask_PRIORITY,
                  keyTask_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

   OSTaskCreateExt(PIDtask,
                     NULL,
                     (void *)&PIDtask_stk[TASK_STACKSIZE-1],
                     PIDtask_PRIORITY,
                     PIDtask_PRIORITY,
                     PIDtask_stk,
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
