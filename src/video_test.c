// Vid32 AVR32UC3B Video Game Source files
// This file implements a video generator for simple video games of your childhood
// most of the 60 Mips of awesome 32 bit CPu power is used to generate 320X240 pixel
//  4 bit RGB (12 bit s total 4096 colors) of on-screen goodness.
//
//  Video generation is all interrupt driven so once you initialize it , the video
// is generated and you get about 1-2 mips during the vertical blanking interval
//  when there are no active pixel being drawn.

// schematics of the design are available as well as PCBs and stuffed boards
// contact davelandia@verizon.net for more info


/* This source file is part of the ATMEL AVR32-SoftwareFramework-AT32UC3B-1.4.0 Release */

/*This file has been prepared for Doxygen automatic documentation generation.*/
/*! \file *********************************************************************
 *
 * \brief GPIO example application for AVR32 using the local bus interface.
 *
 * - Compiler:           IAR EWAVR32 and GNU GCC for AVR32
 * - Supported devices:  All AVR32 devices with GPIO.
 * - AppNote:
 *
 * \author               Atmel Corporation: http://www.atmel.com \n
 *                       Support and FAQ: http://support.atmel.no/
 *
 *****************************************************************************/

/*! \page License
 * Copyright (C) 2006-2008, Atmel Corporation All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. The name of ATMEL may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ATMEL ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE EXPRESSLY AND
 * SPECIFICALLY DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*! \mainpage
 * \section intro Introduction
 * This is the documentation for the data structures, functions, variables,
 * defines, enums, and typedefs for the GPIO driver.
 *
 * The General Purpose Input/Output manages the I/O pins of the microcontroller. Each I/O line
 * may be dedicated as a general-purpose I/O or be assigned to a function of an embedded peripheral.
 * This assures effective optimization of the pins of a product.
 *
 * The given example covers various uses of the GPIO controller and demonstrates
 * different GPIO functionalities using the local bus interface.
 *
 * This interface operates with high clock frequency (fCPU), and its timing is
 * deterministic since it does not need to access a shared bus which may be
 * heavily loaded.
 *
 * To use this interface, the clock frequency of the peripheral bus on which the
 * GPIO peripheral is connected must be set to the CPU clock frequency
 * (fPB = fCPU).
 *
 * The example toggles PA10 on each CPU clock cycle. The CPU is set at the
 * maximal frequency at which instructions can be fetched from flash without
 * wait states, i.e. 33 MHz. Hence, the pin signal frequency is
 * \f$ \frac{33 MHz}{2} = 16.5 MHz \f$ because the pin is toggled at 33 MHz.
 * This can be observed with an oscilloscope.
 *
 * \section files Main Files
 * - gpio.c: GPIO driver;
 * - gpio.h: GPIO driver header file;
 * - gpio_local_bus_example.c: GPIO example application using the local bus.
 *
 * \section compinfo Compilation Info
 * This software was written for the GNU GCC for AVR32 and IAR Systems compiler
 * for AVR32. Other compilers may or may not work.
 *
 * \section deviceinfo Device Info
 * All AVR32 devices with a GPIO module can be used. This example has been tested
 * with the following setup:
 *   - EVK1100 or EVK1101 evaluation kit.
 *
 * \section setupinfo Setup Information
 * CPU speed: <i> 33 MHz from 12-MHz Osc0 crystal </i>.
 *
 * \section contactinfo Contact Information
 * For further information, visit
 * <A href="http://www.atmel.com/products/AVR32/">Atmel AVR32</A>.\n
 * Support and FAQ: http://support.atmel.no/
 */

/*
 * vid32 platform code.. David L Anderson Released under GNU Publice License
 * Except for atmel parts ( they are noted above)
 */



#include "compiler.h"
#include "preprocessor.h"
#include "pm.h"
#include "gpio.h"
#include "board.h"
#include "flashc.h"
#include "tiles.h"
#include "cycle_counter.h"
#include "intc.h"
#include "tc.h"

//extern void _do_video_line( U16[],U8[]);
extern void _do_video_test_pattern(const U16[],U8[] );
extern void _do_video_memory_test(const U16[],U8[] );
extern void _do_return(void);
extern void _line_hsync(void);
extern void _line_vsync(void);
extern void _line_vsync_low(void);
extern void _line_data(void);
extern void _line_end(void);
extern void _line_end_no_inc(void);
extern void _do_line_scan(void);

//static const gpio_map_t RGB_GPIO_MAP =
//   {
//      {AVR32_PIN_PB00,  AVR32_PIN_PB00_FUNCTION },  // BLUe0
//      {AVR32_PIN_PB01,  AVR32_PIN_PB01_FUNCTION },  // Blu1
//      {AVR32_PIN_PB2,  AVR32_PIN_PB2_FUNCTION },  // BLU2
//      {AVR32_PIN_PB3,  AVR32_PIN_PB3_FUNCTION },  // Blu3
//      {AVR32_PIN_PB4,  AVR32_PIN_PB4_FUNCTION }   // grn 0
//   };
//



#define GPIO_PIN_EXAMPLE  AVR32_PIN_PA10

// csync pin on pa31
#define GPIO_PIN_CSYNC AVR32_PIN_PA31

#define GPIO_PIN_RGB_PORT  AVR32_PIN_PB00

// Osc1 crystal is not mounted by default. Set the following definitions to the
// appropriate values if a custom Osc1 crystal is mounted on your board.
#define FOSC1           14318181                              //!< Osc1 frequency: Hz.
#define OSC1_STARTUP    AVR32_PM_OSCCTRL1_STARTUP_2048_RCOSC  //!< Osc1 startup time: RCOsc periods.

// timer counter 2 runs double rate for vsync pulses
// timer counter 2 is used to generate Vsync timing.  this takes some of the cycle counting
// accuracy off of the cpu since the time will change on exactly the correct count regardless of cpu loading
//  Then we get an interrupt and can fix up the pointers to prepare for a vsync interval

// Note that TC_A1_0_0 pin is pin 45(PA21) on AT32UC3B0256 QFP64.
#  define VSYNC_TC_CHANNEL_ID         1
#  define TCA1_TC_CHANNEL_PIN        AVR32_TC_A1_0_0_PIN
#  define TCA1_TC_CHANNEL_FUNCTION   AVR32_TC_A1_0_0_FUNCTION

/// values for TC1 chan 2 RA and RB registers that set interrupts for line timing
// each video line is timed by the timer 2 RA and RB settings.  This allows for more accurate timing
// since the timer will count exact clock cycles and will not have interrupt latency issues.
// the IO pin to the AD723 chages state based on the timer Not on the software timeing.
// pixel positions are still software timed, but the basic line and frame rates are EXACT based upon
// timer counts.
//
// Note tha the time runs at 1/2 the cpu clock so all actual timer counts are 1/2 any cpu cycle counts

// Define RA to count the horizontal sync high width of 4.749us
// this will drop the hsync line when in should go low.
#define CSYNC_HIGH_COUNT 136  //RA == 4.749us*57.2727200Mhz/2=136 pba clocks
// Define RB to determine when the active video shoudl start after the Hsync pulse drops
// This timeout will define the left hand position of the video on the screen.
// less time here and the video moves over to the left
#define ACTIVE_VIDEO_COUNT 311 // RB=10.895us

// define the length of a horizontal video line.  The Hsync pulse will go back high here ( in hardware)
// to insure that the  line is completed at exactly the correct time.  The CPU must have finished it's video line
// and begun pre-calculating the next line.  Actually it must return 2-3us later so the next interrupt of RA can prep the next line.

#define line_rate_count 1820 // RC

// define Pins and functions for the CSYNC pin
#  define CSYNC_TC_CHANNEL_ID         2
#  define TCA2_TC_CHANNEL_PIN        AVR32_TC_A2_0_0_PIN
#  define TCA2_TC_CHANNEL_FUNCTION   AVR32_TC_A2_0_0_FUNCTION


// Note that TC_A2_0_0 pin is pin 30(PA11) on AT32UC3B0256 QFP64.
#  define TCB2_TC_CHANNEL_PIN        AVR32_TC_B2_0_0_PIN
#  define TCB2_TC_CHANNEL_FUNCTION   AVR32_TC_B2_0_0_FUNCTION
// Note that TC_B2_0_1 pin is pin 31(PA12) on AT32UC3B0256 QFP64.

#define GPIO_LED_HORZ_TRIG  AVR32_PIN_PA23
#define GPIO_LED_VERT_TRIG  AVR32_PIN_PA24

static const  tc_interrupt_t tc_int_settings=
  { .etrgs=0 ,
    .ldrbs=0 ,
    .ldras=0 ,
    .cpcs= 1,
    .cpbs= 1,
    .cpas= 1,
    .lovrs= 0,
    .covfs= 0

};

static const  tc_interrupt_t tc1_int_settings=
  { .etrgs=0 ,
    .ldrbs=0 ,
    .ldras=0 ,
    .cpcs= 0,
    .cpbs= 0,
    .cpas= 0,
    .lovrs= 0,
    .covfs= 0

};

const  tc_waveform_opt_t tc2_settings=
  {.channel = CSYNC_TC_CHANNEL_ID ,
      .bswtrg = TC_EVT_EFFECT_NOOP,
      .beevt = TC_EVT_EFFECT_NOOP,
      .bcpc = TC_EVT_EFFECT_CLEAR,
      .bcpb = TC_EVT_EFFECT_SET,

      .aswtrg = TC_EVT_EFFECT_NOOP,
      .aeevt = TC_EVT_EFFECT_NOOP,
      .acpc = TC_EVT_EFFECT_CLEAR,
      .acpa = TC_EVT_EFFECT_SET,

      .wavsel =TC_WAVEFORM_SEL_UP_MODE_RC_TRIGGER ,
      .enetrg = FALSE,							// external trigger disabled  so Video runs at normal rate
      .eevt= TC_EXT_EVENT_SEL_XC2_OUTPUT,
      .eevtedg = TC_SEL_RISING_EDGE,
      .cpcdis = FALSE,
      .cpcstop = FALSE,
      .burst = TC_BURST_NOT_GATED,
      .clki = TC_CLOCK_RISING_EDGE,
      .tcclks = TC_CLOCK_SOURCE_TC2  // timer clock2 is pbaclk/2
  };


const  tc_waveform_opt_t tc2_settings_ext_trigger=
  {.channel = CSYNC_TC_CHANNEL_ID ,
      .bswtrg = TC_EVT_EFFECT_NOOP,
      .beevt = TC_EVT_EFFECT_NOOP,
      .bcpc = TC_EVT_EFFECT_CLEAR,
      .bcpb = TC_EVT_EFFECT_SET,

      .aswtrg = TC_EVT_EFFECT_NOOP,
      .aeevt = TC_EVT_EFFECT_NOOP,
      .acpc = TC_EVT_EFFECT_CLEAR,
      .acpa = TC_EVT_EFFECT_SET,

      .wavsel =TC_WAVEFORM_SEL_UP_MODE_RC_TRIGGER ,
      .enetrg = TRUE,						//  external trigger enabled  so video line is truncated by a Timer 1 event
      .eevt= TC_EXT_EVENT_SEL_XC2_OUTPUT,
      .eevtedg = TC_SEL_RISING_EDGE,
      .cpcdis = FALSE,
      .cpcstop = FALSE,
      .burst = TC_BURST_NOT_GATED,
      .clki = TC_CLOCK_RISING_EDGE,
      .tcclks = TC_CLOCK_SOURCE_TC2  // timer clock2 is pbaclk/2
  };


//  TC1 runs 1/2 a video line only during vsync lines ( vertical blanking interval)
//  We need to do some csync pules at twice the horizontal rate during the blanking, so this
// timer mode is enabled during that time to get us CSYNC pulsing twice every horizontal line
//
// this T1 Event forces a reset on the CSync line  setup in TC2 above half way thru its cycle,
// so T2 then restarts and runs again.. but since T2 was only 1/2 way thru it's cycle it now runs at twice the
// effective horizontal rate while TC1 is activly bumping it.

// This generates a second CSYNC pulse in the center of the video line during vertical interval lines.
// note that the TIOA1 T1 output is used internally to trigger a reset of TC2 every 910 (PBA/2) timer clocks
//// this is a loopback feedback of 2 timers to generate a complex pattern of CSYNC pulses

const  tc_waveform_opt_t tc1_settings=
  {.channel = VSYNC_TC_CHANNEL_ID ,
      .bswtrg = TC_EVT_EFFECT_NOOP,
      .beevt = TC_EVT_EFFECT_NOOP,
      .bcpc = TC_EVT_EFFECT_CLEAR,
      .bcpb = TC_EVT_EFFECT_SET,

      .aswtrg = TC_EVT_EFFECT_NOOP,
      .aeevt = TC_EVT_EFFECT_NOOP,
      .acpc = TC_EVT_EFFECT_CLEAR,
      .acpa = TC_EVT_EFFECT_SET,

      .wavsel =TC_WAVEFORM_SEL_UP_MODE_RC_TRIGGER ,
      .enetrg = FALSE,
      .eevt= TC_EXT_EVENT_SEL_XC0_OUTPUT,
      .eevtedg = TC_SEL_NO_EDGE,
      .cpcdis = FALSE,
      .cpcstop = FALSE,
      .burst = TC_BURST_NOT_GATED,
      .clki = TC_CLOCK_RISING_EDGE,
      .tcclks = TC_CLOCK_SOURCE_TC2  // timer clock2 is pbaclk/2
  };

void fill_sprite_buffer();
void init_color_bars();
volatile U16 ctr_sprite=0;
volatile U16 ctr_before =0;
volatile U16 ctr_after =0;
volatile U16 ctr_delta =0;

volatile U32 halfline = 0;
volatile U32 tc_tick = 0;
volatile U32 line_number =0;
volatile U8 active_lines =0;  // true when activelay displaying video
// The timer/counter instance and channel number are used in several functions.

   volatile avr32_tc_t *tc = &AVR32_TC;

#if __GNUC__
__attribute__((__always_inline__))
#endif
extern __inline__ void gpio_local_enable_pin_interrupt(unsigned int pin)
{
  AVR32_GPIO_LOCAL.port[pin >> 5].oders = 1 << (pin & 0x1F);
}
// timer counter 2 TC2 video interrupt service routine.  This sets the video CSYNC timing to the AD723 video
// generator IC,  The steam of video data is determined by the video rendering code called by this interupt.
// the video active interrupt
/// Video interrupt
#if __GNUC__
__attribute__((__interrupt__))
#elif __ICCAVR32__
#pragma handler = AVR32_TC_IRQ_GROUP, 1
__interrupt
#endif
extern void tc2_irq(void)
{ int status;
  // Increment the timer interupt counter to keep track of which video line ( or effective line ) we are
// on.   The video line number is needed to determine what video data will be rendered on this interupt.
  tc_tick++;

  // Clear the interrupt flag. This is a side effect of reading the TC SR.
 //status= tc_read_sr(&AVR32_TC, &AVR32_TC);
  // beware  ... hard coded channel number... make it a #define...
  // see which TC2 event cause the interupt.
 status= AVR32_TC.channel[2].sr;


 if (active_lines) // active lines are places where video is actually rendered... lines 15 to 262
 {  // render the active line here...  use the proper routine depending on video mode selected at compile
	 // time.  not that this saves memory space and CPU cycles by selectively compiling in only one set
	 // of video modes into any one program.
	 if(status & 0x04)
		 {	// _line_hsync();  set csync high  then run video line
	                 //AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrs= 1<< ( GPIO_PIN_CSYNC & 0x1F );
					 //if (line_number ==15)
	 	                  // active_lines=1;  // back to active lines
	 					#ifdef VIDEOMODE1  // 240*240 32 sprites
	 						 _line_data(); // line 15 ( dummy ) to line 255
	 					#endif

	 						 // note that the interupt flag might still be set from the current line... clear it befor we return
	 						 status= AVR32_TC.channel[2].sr;// clear int flag
		 }

	 else if (status & 0x10)  // line is over.. clear csync
	               { // _line_end();   //cleear csync      // inc line number here
	                 AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrc= 1<< ( GPIO_PIN_CSYNC & 0x1F );
	                 line_number++;
	                 if (line_number>256)// next  line is 257
	                 	 	active_lines=0;
	               }
 }

 else  // its not an active video frame so we just make sync pulse here..
	    // This is currently software driven so the CSYNC and VSYNC edges are dependant on software execution time.
	    //  When the CSYNC and VSYNC pins are from the timers then this timing will be guranteed by timer clock cycles.

	   /// But for now...
	   //  we just need to make sure that we transition in and out of vertical mode and double rate vertical mode
	   // on the correct video line numbers.
   {
 switch (line_number){

   case 1:   // normal VSYNC lines 1-9
   case 2:
   case 3:
   case 7:
   case 8:
   case 9: // begin halfline mode.
     { if(status & 0x04) /// timer event??? what
       //_line_vsync();
       // Set Csync high
         AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrs= 1<< ( GPIO_PIN_CSYNC & 0x1F );

       // scope trigger high here
     AVR32_GPIO_LOCAL.port[GPIO_LED_VERT_TRIG >> 5].ovrs= 1<< ( GPIO_LED_VERT_TRIG & 0x1F );

     if (status & 0x10) //timer event ??? what
       { // toggel csync at half the horizontal linecount
         AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrt= 1<< ( GPIO_PIN_CSYNC & 0x1F );

        if (halfline)  // we are running interrupts at 2x the line rate during vsync
           {
             //_line_end_no_inc();  // so we only inc line number every other interrupt during vsync
             halfline=0;
           }
       else
           {
            //_line_end();        // inc line number here
            halfline=1;
            line_number++;
            //if (line_number >262)
            //  line_number=262;

            if (line_number ==10 )  // vertical sync done at end of line 9
               { // set up normal line 1x interrupt timings
                 tc_write_ra(tc, CSYNC_TC_CHANNEL_ID, CSYNC_HIGH_COUNT);     // Set RA value. 135 counts... 4.7us
                 tc_write_rb(tc, CSYNC_TC_CHANNEL_ID, ACTIVE_VIDEO_COUNT);     // Set RB value. 290 counts  10.2us
                 tc_write_rc(tc, CSYNC_TC_CHANNEL_ID, line_rate_count);     // Set RC value. REset counter here  65.3535us

               }



           }
         }
       break;
     }
   case 4:   // inverted vertical sync lines 4-6
    case 5:
    case 6:

      { if(status & 0x04)
        //_line_vsync_low();
    	 // now csync is low pulsing high
      AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrc= 1<< ( GPIO_PIN_CSYNC & 0x1F );


      else if (status & 0x10)
        {// toggel csync at half line
          AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrt= 1<< ( GPIO_PIN_CSYNC & 0x1F );

         if (halfline)  // we are running interrupts at 2x the line rate during vsync
            {//_line_end_no_inc();  // so we only inc line number every other interrupt during vsync
              halfline=0;
            }
        else
            {
             //_line_end();        // inc line number here
              line_number++;
                 //if (line_number >262)
                 //   line_number=262;
              halfline=1;

            }
          }
        break;
      }
      case 10:   // 6 Black lines before active lines
      case 11:
      case 12:
      case 13:
      case 14:


        {
           if(status & 0x04)
             // _line_hsync();  set csync high
               AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrs= 1<< ( GPIO_PIN_CSYNC & 0x1F );
           else if (status & 0x10)
             { // _line_end();   //cleear csync      // inc line number here
               AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrc= 1<< ( GPIO_PIN_CSYNC & 0x1F );
               line_number++;
               if (line_number ==15)
                 { active_lines=1;  // back to active lines
                 // scope trigger low here
                   AVR32_GPIO_LOCAL.port[GPIO_LED_VERT_TRIG >> 5].ovrc= 1<< ( GPIO_LED_VERT_TRIG & 0x1F );

                 }
             }
         break;
        }
     case 257:   // 257-262 6 Black lines after active lines
     case 258:
     case 259:
     case 260:
     case 261:
      case 262:
        {
            if(status & 0x04)  // tc2 ra compare interrupt
             //  _line_hsync();  //set csync high
             AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrs= 1<< ( GPIO_PIN_CSYNC & 0x1F );

            else if (status & 0x10) //  tc2 rc compare interupt
              {
               //  _line_end();   //cleear csync      // inc line number here
                AVR32_GPIO_LOCAL.port[GPIO_PIN_CSYNC >> 5].ovrc= 1<< ( GPIO_PIN_CSYNC & 0x1F );

                 line_number=1;  // we are at the end of the frame  setup for line #1 and vertical sync

                   //line 1  change sync rate to 2X rate (i.e. 910)
                      //  it is turned back off at the end of line 9
                    tc_write_ra(tc, CSYNC_TC_CHANNEL_ID, CSYNC_HIGH_COUNT);     // Set RA value. 135 counts... 4.7us
                    tc_write_rb(tc, CSYNC_TC_CHANNEL_ID, ACTIVE_VIDEO_COUNT);     // Set RB value. 290 counts  10.2us
                    tc_write_rc(tc, CSYNC_TC_CHANNEL_ID, line_rate_count/2);     // Set RC value. REset counter here  65.3535us

                      //tc_init_waveform(tc, & tc2_settings);
                      // tc_init_waveform(tc, & tc2_settings_ext_trigger);

               }
              break;
            }






  } // end switch lines
   } // end else
}  // end interrupt tc2

// timer counter 1 video interrupt
/// Video interrupt
#if __GNUC__
__attribute__((__interrupt__))
#elif __ICCAVR32__
#pragma handler = AVR32_TC_IRQ_GROUP, 1
__interrupt
#endif
static void tc1_irq(void)
{ int status;
  // Increment the ms seconds counter
  tc_tick++;

  // Clear the tc1 interrupt flag. This is a side effect of reading the TC SR.
 status= tc_read_sr(&AVR32_TC, VSYNC_TC_CHANNEL_ID);

 if (line_number < 10)  // vertical sync lines 1-9
  {
  if(status & 0x04)
    _line_vsync_low();  // drive csync low again, tc1 RA compare and tc2 ext trigger just occured
 //  if (status & 0x10)
 //   _line_end();        // inc line number here
  }


 if (line_number == 9)
   {
     //line 9 turn off vsync tc2 external trigger
     //  it is turned back on at the end of line 262

    // tc_init_waveform(tc, & tc2_settings);
    // tc_init_waveform(tc, & tc2_settings_ext_trigger);
   }

}




// initialize intc interupots  for video
// SEt up the timer TCA1 and TCA2 counters to time the video events and interupt us when it is required to maintain
// strict video timing.   We must finish the current video line and return BEFORE the next line interrupt occurs.
//  This is inefficient in CPU cycles( interupt calls pop registers on and off the stack in quick sucession)  but guantees the timing.
//
//  Two timer setups  are GLOBAL structures settings that are copied to the tiemr registers to init the timers
// this routine only uses tc1_settings and tc2_settings that are declaed global above.  To change the line or frame timing
// you must modify these structures.

static void init_intc_interrupts(void)
{


// Disable all interrupts.
// Disable_global_interrupt();

 // Initialize interrupt vectors.
// INTC_init_interrupts();


 // Register the USART interrupt handler to the interrupt controller.
 // usart_int_handler is the interrupt handler to register.
 // EXAMPLE_USART_IRQ is the IRQ of the interrupt handler to register.
 // AVR32_INTC_INT0 is the interrupt priority level to assign to the group of
 // this IRQ.
 // void INTC_register_interrupt(__int_handler handler, unsigned int irq, unsigned int int_lev);


 //INTC_register_interrupt(&video_int_handler, EXAMPLE_TC_IRQ, AVR32_INTC_INT0);

// set a channel interrupt handler on left encoder
// gpio_enable_pin_interrupt(GPIO_CHAN_A_LEFT, GPIO_PIN_CHANGE);

 // The INTC driver has to be used only for GNU GCC for AVR32.
#if __GNUC__
 // Initialize interrupt vectors.
 INTC_init_interrupts();

 // Register the RTC interrupt handler to the interrupt controller.
 INTC_register_interrupt(&tc2_irq, AVR32_TC_IRQ2, AVR32_INTC_INT0);

 // Register the RTC interrupt handler to the interrupt controller.
  INTC_register_interrupt(&tc1_irq, AVR32_TC_IRQ1, AVR32_INTC_INT0);

#endif


 // Assign I/O to timer/counter channel pin & function. Pin 45
  gpio_enable_module_pin(TCA1_TC_CHANNEL_PIN, TCA1_TC_CHANNEL_FUNCTION);

 // Assign I/O to timer/counter channel pin & function.
  gpio_enable_module_pin(TCA2_TC_CHANNEL_PIN, TCA2_TC_CHANNEL_FUNCTION);
  // Assign I/O to timer/counter channel pin & function.
    gpio_enable_module_pin(TCB2_TC_CHANNEL_PIN, TCB2_TC_CHANNEL_FUNCTION);

  // Enable all interrupts.
   Enable_global_interrupt();

  tc_init_waveform(tc, & tc2_settings);
  tc_init_waveform(tc, & tc1_settings);
 //
 //  CLOCK is Clock/2
 //  57.27272Mhz/2=
 // Set the compare triggers.
   tc_write_ra(tc, CSYNC_TC_CHANNEL_ID, CSYNC_HIGH_COUNT);     // Set RA value. 135 counts... 4.7us
   tc_write_rb(tc, CSYNC_TC_CHANNEL_ID, ACTIVE_VIDEO_COUNT);     // Set RB value. 290 counts  10.2us
   tc_write_rc(tc, CSYNC_TC_CHANNEL_ID, line_rate_count);     // Set RC value. REset counter here  65.3535us

   tc_write_ra(tc, VSYNC_TC_CHANNEL_ID, 909);     // Set RA value. 135 counts... 4.7us
   tc_write_rb(tc, VSYNC_TC_CHANNEL_ID, ACTIVE_VIDEO_COUNT);     // Set RB value. 290 counts  10.2us
   tc_write_rc(tc, VSYNC_TC_CHANNEL_ID, line_rate_count);     // Set RC value. REset counter here  65.3535us

   //  block mode register sets XC2 to be driven by TIOA1 outout of timer 1
   // we use this as a trigger to reset timer 2 NOT as a clock line
   //  this is enabled only during vertical sync lines to cause them to run at twice the rate

   tc_select_external_clock(tc, 2, TC_CH2_EXT_CLK2_SRC_TIOA1);

   //INTC_register_interrupts(tc_irq, EXAMPLE_TC_CHANNEL_ID, &tc_int_settings);
   tc_configure_interrupts(tc, CSYNC_TC_CHANNEL_ID, &tc_int_settings);

   //INTC_register_interrupts(tc_irq, EXAMPLE_TC_CHANNEL_ID, &tc_int_settings);
   tc_configure_interrupts(tc, VSYNC_TC_CHANNEL_ID, &tc1_int_settings);

   // we start the frame from vsync section lines 1-9
   halfline=1;
   line_number=1;


   // Start the timer/counters.
   tc_start(tc, CSYNC_TC_CHANNEL_ID);
   tc_start(tc, VSYNC_TC_CHANNEL_ID);
   tc_sync_trigger(tc);

}

// fill video memory array with 0 (black screen)
void init_video_memory();
void pong();

/*! \brief This is an example showing how to toggle a GPIO pin at high speed.
 */
int main(void)
{
int x,y,z;
U16 * tptr;
unsigned int fstate;
U32 frame_time;
  //#ifdef dlaboard //BOARD == EVK1100 || BOARD == EVK1101

    // Switch main clock to external oscillator 1 (crystal).
    // Set PLL0 to Multply OSC1 XTAL by 8 for 14.31818Mhz*10=114.545454Mhz
   // then divide by 2 for 57.27272727Mhz CPU FREQ

   fstate=flashc_get_wait_state();
   fstate=1;
   flashc_set_wait_state(fstate);
   fstate=26;
   fstate=flashc_get_wait_state();


   pm_enable_osc1_crystal(&AVR32_PM, FOSC1);            // Enable the Osc1 in crystal mode

   pm_enable_clk1(&AVR32_PM, OSC1_STARTUP);                  // Crystal startup time - This parameter is critical and depends on the characteristics of the crystal

    pm_pll_setup(&AVR32_PM,0,7,1,1,16);                      // 7+1 is Mult by 8
    pm_pll_set_option(&AVR32_PM, 0, // pll.
                        1,  // pll_freq.
                        1,  // pll_div2.
                        0); // pll_wbwdisable.
    pm_pll_enable(&AVR32_PM, 0);

    pm_wait_for_pll0_locked(&AVR32_PM);
    pm_cksel(&AVR32_PM,
               0,   // pbadiv.  //pba=57.272727Mhz
               0,   // pbasel.
               0,   // pbbdiv.  //pbb=57.272727Mhz
               0,   // pbbsel.
               0,   // hsbdiv. /// cpu and hsb share same settings =57.272727Mhz
               0);  // hsbsel.

    pm_switch_to_clock(&AVR32_PM, AVR32_PM_MCCTRL_MCSEL_PLL0);  // Then switch main clock to Osc1 and PLL0



  // Enable the local bus interface for GPIO.
  gpio_local_init();

 // enable drive on RGB outputs
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB00);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB01);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB02);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB03);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB04);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB05);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB06);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB07);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB08);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB09);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB10);
  gpio_local_enable_pin_output_driver(AVR32_PIN_PB11);








  // Enable the output driver of the example pin.
  // Note that the GPIO mode of pins is enabled by default after reset.
  gpio_local_enable_pin_output_driver(GPIO_PIN_EXAMPLE);

  /// init the GPIO PORT LED IO ports to output drivers on
    gpio_local_enable_pin_output_driver(GPIO_LED_HORZ_TRIG);
    gpio_local_enable_pin_output_driver(GPIO_LED_VERT_TRIG);

// enable csync output driver
    gpio_local_enable_pin_output_driver(GPIO_PIN_CSYNC);

    gpio_local_set_gpio_pin(GPIO_LED_HORZ_TRIG);
    gpio_local_clr_gpio_pin(GPIO_LED_VERT_TRIG);
// Csync Low
    gpio_local_clr_gpio_pin(GPIO_PIN_CSYNC);

 // setup and enable the 4FSC Clock to AD723 Video gen
 // OSc1 drives pll0, use the PLL0 clock ( 57.2727)  and diveide it by 4.
    // for 14.381818Mhz
    pm_gc_setup(&AVR32_PM,
                      2,// gclk #2
                      1, // Use Osc (=0) or PLL (=1)
                      0, // Sel Osc0/PLL0 or Osc1/PLL1
                      1, // enable divider
                      1);  // div=1 is divide by 4= 2*(div+1)

    pm_gc_enable(&AVR32_PM,
                      2);

    gpio_enable_module_pin(AVR32_PM_GCLK_2_PIN, AVR32_PM_GCLK_2_FUNCTION);
    init_video_memory();


    init_intc_interrupts();


    tptr= tile_memory;
     x=sizeof(tile_memory[0]);
     y=sizeof(video_memory[0]);

     init_color_bars();


     while(1)
       {
         for (x=1; x<2; x++)
          {
            while (line_number==1);
            while (line_number !=1);
          }
     //    pong();
       }

     while(1)
        {

           x=0;
           y=0;
             while (line_number==1)
              y=y+1;
             while (line_number !=1)
              x=x+1;



          pong();
        }


     //_do_return();
     while (1)
     //_do_video_test_pattern(tile_memory,video_memory);
       {Set_sys_count(0);
     _do_video_memory_test(tile_memory,video_memory);
       frame_time=Get_sys_count();
       }
    // Toggle the example GPIO pin at high speed in a loop.
  while (1)
  { z=1;
  gpio_tgl_gpio_pin(GPIO_PIN_CSYNC);
    gpio_tgl_gpio_pin(GPIO_LED_HORZ_TRIG);
    gpio_tgl_gpio_pin(GPIO_LED_VERT_TRIG);
    for (x=1 ; x< 100; x++)
      for (y=1;y< 20000; y++)
        {gpio_tgl_gpio_pin(GPIO_PIN_CSYNC);
        z=z+1;}
    x=z+y;
  }
}

void pong()
{  //static int row=23;
   static int col =1;
   static U8 save=1;

    video_memory[col-1]=save;
    save= video_memory[col];
    video_memory[col]=6;

    col++;
    if (col ==NUM_TILES_X*NUM_TILES_Y )
      col=0;



}

// fil video memory array with 0 (black screen)
void init_video_memory()
{ int tile_pos,x;
// fill with green background
 for (tile_pos=0; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos++)
   video_memory[tile_pos]=5;

// for (tile_pos=20; tile_pos< 40*30; tile_pos+=40)
 //   video_memory[tile_pos]=2;

 for (tile_pos=0; tile_pos< NUM_TILES_X; tile_pos++)
     video_memory[tile_pos]=3;


 for (tile_pos=NUM_TILES_X*NUM_TILES_Y-NUM_TILES_X; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos++)
      video_memory[tile_pos]=1;

 for (tile_pos=0; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos+=NUM_TILES_X)
       video_memory[tile_pos]=1;


 video_memory[15*NUM_TILES_X+20]=4;
 video_memory[19*NUM_TILES_X+19]=2;
 video_memory[20*NUM_TILES_X+19]=2;



 video_memory[1]=2;
 video_memory[3]=3;
 video_memory[4]=1;
 video_memory[5]=2;
 video_memory[6]=3;
 video_memory[7]=1;

 video_memory[29*NUM_TILES_X+0]=9;
 video_memory[28*NUM_TILES_X+1]=9;
 video_memory[27*NUM_TILES_X+2]=9;

 for(x=0; x<NUM_SPRITES; x++)
  sprites[x].mode=invisible; /// all sprites inactive

 sprites[0].mode=invisible; // stopped but displayed
 sprites[0].xloc=21;
 sprites[0].yloc=40;
 sprites[0].tile_number=6;
 fill_sprite_buffer(45);

}

///  scan all sprites and place their video data for the next line into
// the sprite_video_buffer  which is a single line.
void fill_sprite_buffer(pixel_row)
{ int max_pix,pix,this_sprite;
  // sprite line buffer is cleared as we display it
  // so we only need to put sprites in their specific spot

  for (this_sprite=0; this_sprite<1; this_sprite++)
    {
      if (sprites[this_sprite].mode!=invisible)
      {
        if (((pixel_row-sprites[this_sprite].yloc )>-1) && ((pixel_row-sprites[this_sprite].yloc )<8))
        {  //display this sprite in the current video line
          // copy tile memory pixels into words of video line memory
          //
          max_pix=8;
          if (HORIZONTAL_RES-sprites[this_sprite].xloc  < 8 ) // don't allow sprite pixels to wrap to next line
              max_pix=HORIZONTAL_RES- sprites[this_sprite].xloc ;
            for (pix=0; pix<max_pix; pix++)
              {
                sprite_video_buffer[sprites[this_sprite].xloc+pix]=tile_memory[sprites[this_sprite].tile_number*64+(pixel_row-sprites[this_sprite].yloc)*8+pix]| 0x8000000;
              }
          }
      }
    }
   // sprite_video_buffer[20]=0x8fff;
  //sprite_video_buffer[24]=0x8fff;

  //sprite_video_buffer[28]=0x8f00;
 // sprite_video_buffer[45]=0x8f00;


}


void init_color_bars()
{ int tile_pos,col;
// fill with 75% white background
for (tile_pos=0; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos++)
   video_memory[tile_pos]=0;

// fill col 0 to col 40/8=4
for (col=0;col<5;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=10;

// fill col 5 to col 40/8=4
for (col=5;col<10;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=11;

// fill col 10 to col 15
for (col=10;col<15;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=12;

// fill col 10 to col 15  green
for (col=15;col<20;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=13;

// fill col 20 to col 25  Magenta
for (col=20;col<25;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=14;

// fill col 10 to col 15  red
for (col=25;col<30;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=15;

// fill col 10 to col 15  blue
for (col=30;col<35;col++)
	for (tile_pos=col; tile_pos< NUM_TILES_Y*NUM_TILES_X; tile_pos+=NUM_TILES_X)
      video_memory[tile_pos]=16;


//for (tile_pos=0; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos++)
//   video_memory[tile_pos]=10;

// for (tile_pos=20; tile_pos< 40*30; tile_pos+=40)
 //   video_memory[tile_pos]=2;

 // 75% white bar
// for (tile_pos=0; tile_pos< NUM_TILES_X; tile_pos++)
//     video_memory[tile_pos]=3;
//
//
// for (tile_pos=NUM_TILES_X*NUM_TILES_Y-NUM_TILES_X; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos++)
//      video_memory[tile_pos]=1;
//
// for (tile_pos=0; tile_pos< NUM_TILES_X*NUM_TILES_Y; tile_pos+=NUM_TILES_X)
//       video_memory[tile_pos]=1;
//
//
// video_memory[15*NUM_TILES_X+20]=4;
// video_memory[19*NUM_TILES_X+19]=2;
// video_memory[20*NUM_TILES_X+19]=2;
//
//
//
// video_memory[1]=2;
// video_memory[3]=3;
// video_memory[4]=1;
// video_memory[5]=2;
// video_memory[6]=3;
// video_memory[7]=1;
}

