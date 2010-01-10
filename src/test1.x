

#include <avr32/io.h>

 // Export symbol.
//.data
//.extern video_memory

//.section .rodata
//.extern tile_memory
#define video_port_addr r0



.extern line_number
.extern video_memory
.extern tile_memory


.section .text
.align 4
_do_return:
	stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack
	ldm		sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _do_return


_do_line_scan:
	stm     --sp, r0,r5,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack

	// we are now at video line 15, one line before active video
	//  we can use this time to setup for the next scan.
	// we must keep exact counts from now on to insure that
	// timing is maintained.
	// from here on we ignore the TC2 timer interrupts ( since we have not yet returned from the interupt service routine)
	// so we can only poll the TC2 timer to get synchronized
	//




	 ldm             sp++, r0,r5,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _do_line_scan


_line_hsync:
	       stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack

 	       // Set R0 to GPIO LOCAL PORT0 base address for video DAC
	        mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
	        orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

	        // timer done cysnc hi  on PORT A Bit 31
	        mov  R7, 0x0000                                //c4
	        orh      R7, 0x8000                                //c5
	        st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c6


        ldm             sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_hsync

_line_vsync:
               stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack


               // Set R0 to GPIO LOCAL PORT0 base address for video DAC
                mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
                orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

                // timer done, Csync high   on PORT A Bit 31
                mov  R7, 0x0000                                //c4
                orh      R7, 0x8000                                //c5
                st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c6



        ldm             sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_vsync

_line_vsync_low:
               stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack


               // Set R0 to GPIO LOCAL PORT0 base address for video DAC
                mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
                orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

                // timer done, Csync low   on PORT A Bit 31
                mov  R7, 0x0000                                //c4
                orh      R7, 0x8000                                //c5
                st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // Clear CSYNC bit 31 forPORT 0 bit 31  //c6



        ldm             sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_vsync_low


_line_data:
        stm     --sp, r0,r5,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack
        // make R8= video line number
        // Set R0 to line_number  address for global variable
          mov R0, LO(line_number)
          orh R0, HI(line_number)

          ld.w r8,r0[0]

         // Set R0 to GPIO LOCAL PORT0 base address for video DAC
         mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
         orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

         // Csync high   on PORT A Bit 31
         mov  R7, 0x0000                                //c4
         orh      R7, 0x8000                                //c5
         st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // set CSYNC bit 31 forPORT 0 bit 31  //c6

         // USE OFFSET to ACCESS Output Value register
         mov  r7, 0x0000
         orh      r7, 0x0000                                             // RGB=0,0,0
         st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7

         // get video memory address into r11
         mov R11, LO(video_memory)
         orh R11, HI(video_memory)

         // get tile memory address into r12
         mov R12, LO(tile_memory)
         orh R12, HI(tile_memory)

         // get sprite_video_buffers into r5
         mov R5, LO(sprite_video_buffer)
         orh R5, HI(sprite_video_buffer)



.rept 1*10  // delay line beginning
        nop
.endr
         rcall send_video_line_indexed_wsprites:

        // USE OFFSET to ACCESS Output Value register
        mov  r7, 0x0000
        orh      r7, 0x0000                                             // RGB=0,0,0
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7




        ldm             sp++, r0,r5,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_data

_line_end:
        stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack
        // Set R0 to line_number  address for global variable
          mov R0, LO(line_number)
          orh R0, HI(line_number)

          ld.w r8,r0[0]
          sub r8,-1 //  inc line number at end of line
          cp.w r8,263
          brne lend1
          sub r8,262    // wrap to line 1 after line 262
lend1:

            st.w r0[0],r8 // save in global variable

        // Set R0 to GPIO LOCAL PORT0 base address for video DAC
         mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
         orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

         // Csync low for 4.7us  on PORT A Bit 31
         mov  R7, 0x0000                                //c4
         orh      R7, 0x8000                                //c5
         st.w R0[AVR32_GPIO_LOCAL_OVRT + 0], R7  // CLR CSYNC bit 31 forPORT 0 bit 31  //c6

        // USE OFFSET to ACCESS Output Value register
        mov  r7, 0x0000
        orh      r7, 0x0000                                             // RGB=0,0,0
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7


        ldm             sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_end


_line_end_no_inc:
        stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r7-r9 and link register on stack
        // Set R0 to line_number  address for global variable
          mov R0, LO(line_number)
          orh R0, HI(line_number)

          ld.w r8,r0[0]
          sub r8,-1 //  inc line number at end of line
          cp.w r8,263
          brne lend2
          sub r8,262    // wrap to line 1 after line 262
lend2:

        //    st.w r0[0],r8 // save in global variable
          nop                   // DO NOT STORE, but take the same # of cycles
        // Set R0 to GPIO LOCAL PORT0 base address for video DAC
         mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
         orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

         // Csync low for 4.7us  on PORT A Bit 31
         mov  R7, 0x0000                                //c4
         orh      R7, 0x8000                                //c5
         st.w R0[AVR32_GPIO_LOCAL_OVRT + 0], R7  // CLR CSYNC bit 31 forPORT 0 bit 31  //c6

        // USE OFFSET to ACCESS Output Value register
        mov  r7, 0x0000
        orh      r7, 0x0000                                             // RGB=0,0,0
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7


        ldm             sp++, r0,r6,r7,r8,r9,r10, pc //  restore r7-r9 and move link register to pc... return from call

.global _line_end_no_inc



//
//when called from "C" we must watch the stack
//
  .global _do_video_test_pattern  //2 parameters r11--video memory address
  							// r12-- tile memory address
_do_video_test_pattern:
	stm     --sp, r0,r6,r7,r8,r9,r10, lr  // save r6-r9 and link register on stack

	mov	r7, sp			// save sp in r7 as reference to the base of the stack fram of this function
	sub     sp, 8		// allocate 2 local word variables on stack
//	mov		R8, tile_memory  //Global tile memory does not work

	mov		R8, 0   // start at video row 0
	mov		r9, 0   // start at video index 0

	// Set R0 to GPIO LOCAL PORT0 base address for video DAC
	mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
	orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

	// USE OFFSET to ACCESS Output Value register
	mov  r7, 0x0000
	orh	 r7, 0x0000						// RGB=0,0,0
	st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7

//lines 10-15
	// start with 6 lines black lines
lp1:	mov  r8, 0x0000

	        orh      r8, 0x0000

.rept 7
         // rcall   send_vsync_pos              // call not nestable
         rcall   send_hsync              // call not nestable
	rcall  one_line_black
.endr

#ifdef stripes
// lines 16-256
//30 tiles *8 =240 lines
.rept 15
        rcall   send_hsync              // call not nestable
        rcall  one_line_red
        rcall   send_hsync              // call not nestable
        rcall  one_line_red
        rcall   send_hsync              // call not nestable
        rcall  one_line_red
        rcall   send_hsync              // call not nestable
        rcall  one_line_red

        rcall   send_hsync              // call not nestable
        rcall  one_line_blue
        rcall   send_hsync              // call not nestable
        rcall  one_line_blue
        rcall   send_hsync              // call not nestable
        rcall  one_line_blue
        rcall   send_hsync              // call not nestable
        rcall  one_line_blue

        rcall   send_hsync              // call not nestable
        rcall  one_line_white
        rcall   send_hsync              // call not nestable
        rcall  one_line_white
        rcall   send_hsync              // call not nestable
        rcall  one_line_white
        rcall   send_hsync              // call not nestable
        rcall  one_line_white

//        rcall   send_hsync              // call not nestable
//        rcall  one_line_black
//        rcall   send_hsync              // call not nestable
//        rcall  one_line_black
//        rcall   send_hsync              // call not nestable
//        rcall  one_line_black
//        rcall   send_hsync              // call not nestable
//        rcall  one_line_black

        mov r6,r9
        rcall   send_hsync              // call not nestable
        mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_color_r6
        rcall   send_hsync              // call not nestable
        mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_color_r6
        rcall   send_hsync              // call not nestable
        mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_color_r6
        rcall   send_hsync              // call not nestable
        mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_color_r6


.endr

#endif


// lines 16-256
//30 tiles *8 =240 lines
.rept 15
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte

        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte

        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        rcall  one_line_smpte


        //mov r6,r9
        rcall   send_hsync              // call not nestable
        //mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        //mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        //mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_smpte
        rcall   send_hsync              // call not nestable
        //mov  r6, 0x03F0                 // 1 clock ?
        rcall  one_line_smpte


.endr






//lines 257-262
        // end with 6 lines black lines
.rept 6
        rcall   send_hsync              // call not nestable
        rcall  one_line_black
.endr
//lines 1-9
// vertical sync
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable



// USE OFFSET to ACCESS Output Value register
mov  r7, 0x0000
orh	 r7, 0x0000						// RGB=0,0,0
st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7

rjmp lp1
// return to "c" land
sub     sp, -8 		// remove 2 local word variables ,clean up stack, Reset Frame Pointer
ldm		sp++, r0,r6,r7,r8,r9,r10, pc //  restore r6-r10 and move link register to pc... return from call




//
	//when called from "C" we must watch the stack
	//
	  .global _do_video_memory_test  //2 parameters r11--video memory address
	                                                        // r12-- tile memory address
	_do_video_memory_test:
	        stm     --sp, r0,r1,r2,r6,r7,r8,r9,r10, lr  // save r6-r9 and link register on stack

	        mov     r7, sp                  // save sp in r7 as reference to the base of the stack fram of this function
	        sub     sp, 8           // allocate 2 local word variables on stack
	//      mov             R8, tile_memory  //Global tile memory does not work

	        mov             R8, 0   // start at video row 0
	        mov             r9, 0   // start at video index 0

	        mov   r1,r11     // save r11
	        mov   r2,r12     // save r12


	        // Set R0 to GPIO LOCAL PORT0 base address for video DAC
	        mov R0, LO(AVR32_GPIO_LOCAL_ADDRESS)
	        orh R0, HI(AVR32_GPIO_LOCAL_ADDRESS)

	        // USE OFFSET to ACCESS Output Value register
	        mov  r7, 0x0000
	        orh      r7, 0x0000                                             // RGB=0,0,0
	        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7

	//lines 10-15
	        // start with 6 lines black lines
	video_mem1:    mov  r8, 0x0000

                orh      r8, 0x0000
                mov   r11,r1     // restore r11
                mov   r12,r2     // restore r12
	.rept 7
	         rcall   send_hsync              // call not nestable
	        rcall  one_line_black
	.endr
//
//
//

.rept 30 // 30 tile rows = 240 lines

        rcall send_tile_row
        // fix up pointers
        sub r11,-40   // next vidoe memory tile line

.endr

//lines 257-262
        // end with 6 lines black lines
.rept 6
        rcall   send_hsync              // call not nestable
        rcall  one_line_black
.endr
//lines 1-9
// vertical sync
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_pos              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable
rcall   send_vsync_neg              // call not nestable



// USE OFFSET to ACCESS Output Value register
mov  r7, 0x0000
orh      r7, 0x0000                                             // RGB=0,0,0
st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7

rjmp video_mem1
// return to "c" land
sub     sp, -8          // remove 2 local word variables ,clean up stack, Reset Frame Pointer
ldm             sp++, r0,r1,r2,r6,r7,r8,r9,r10, pc //  restore r6-r10 and move link register to pc... return from call


// 8 video lines make up a row


send_tile_row:


	stm --sp,lr  // save return address
        rcall  send_hsync
        mov  r10,r11       // IRAM access get next tile number,  2 cycles
        rcall send_video_line
        //rcall one_line_black
        sub r11,40             // fix up tile pointer
        sub r12,-16              // add 8 words (1 line) to r12 ,R12 POINTS TO next line
        nop
        nop
        nop


.rept 6
        nop
        nop

	rcall  send_hsync
	mov  r10,r11       // IRAM access get next tile number,  2 cycles
	rcall send_video_line
	//rcall one_line_black
	sub r11,40             // fix up tile pointer
	sub r12,-16              // add 8 words (1 line) to r12 ,R12 POINTS TO next line
	nop
	nop

.endr
        nop
        nop
        rcall  send_hsync
        mov  r10,r11       // IRAM access get next tile number,  2 cycles
        rcall send_video_line
        //rcall one_line_black
        sub r11,40             // fix up tile pointer
        sub r12,128-16              // add 8 words (1 line) to r12 ,R12 POINTS TO next line



          ldm sp++ ,lr

mov             pc,lr           // return from rcall 1 cycle???

// destroys r6,r10
// inputs r12 =tile memory pointer ram,word wide
//        r11= video memory pointer ram,byte wide
//  3640-580=3060 counts
send_video_line:
.rept 40   // 40 tile loop , 1 video line , 1 row in pixelmap, 9 clocks per pixel
        ld.ub   r10,r11++[0]       //  get next tile number from video memory,  2 cycles
        lsl     r10,7                   // tiles are 128 =8*8*2 bytes long,
        ld.uh	r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	sub		r12,-2     //  add 1 word to r12 1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop


	ld.uh	r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 2 save to local port   1 cycle
	sub		r12,-2     //add 1  word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 3 save to local port   1 cycle
	sub		r12,-2     //add 1 word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 4 save to local port   1 cycle
	sub		r12,-2     //add 1 word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 5 save to local port   1 cycle
	sub		r12,-2     //add 1 word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 6 save to local port   1 cycle
	sub		r12,-2     //add 1 word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 7 save to local port   1 cycle
	sub		r12,-2     //add 1 word to r12  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop					// 1 cycle
	nop
	nop

	ld.uh	r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	st.h	R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 8 save to local port   1 cycle
	sub		r12,14     //back to beginning of tile row  1 cycle
	nop					//1 cycle
	nop					// 1 cycle
	nop
	nop
	nop
.endr


// USE OFFSET to ACCESS Output Value register
mov  r7, 0x0000
orh      r7, 0x0000                                             // RGB=0,0,0
st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R7
.rept 34
       nop
.endr

	mov		pc,lr		// return from rcall 1 cycle???


	// video line number in R8
	// destroys r6,r10
	// inputs r12 =tile memory pointer ram,word wide-- modified
	//        r11= video memory pointer ram,byte wide-- modified
	//  40*9*8+2=2882 clock counts
	//  or 1441 timer ticks
	send_video_line_indexed:

                // r8 contains video line number we are doing,
                // calculate r11 offset for this video line
// active video starts on   line 16 end on line 240
//  map 1200 tile locations in video memory to these video lines
                sub     r8,16  // start on line 16 as active video line 0
                mov     r6,r8  // copy r8 into temp r6
                lsr     r8,3 // divide by 8 to get video memory row
                mul     r8,r8,40  // multiply video memory row (r8) by 40 to get video memory index offset
                add     r11,r8 // add r8 line offset to video memory pointer
                              // r11 now points to 1st column tile # in video memory for this line

                // now get r12 to point to proper line in tile memory

                andl     r6,0x07 // video line number..keep only lower 3 bits mask out others
                lsl     r6,4  // multiply by 16 ( 2 bytes *8 pixels rows)
                add     r12,r6  // this is the offset for r12
	.rept 37   // 40 tile loop , 1 video line , 1 row in pixelmap, 9 clocks per pixel
	        ld.ub   r10,r11++[0]       //  get next tile number from video memory,  2 cycles
	        lsl     r10,7                   // tiles are 128 =8*8*2 bytes long,
	        ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	        sub             r12,-2     //  add 1 word to r12 1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop


	        ld.uh   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 2 save to local port   1 cycle
	        sub             r12,-2     //add 1  word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 3 save to local port   1 cycle
	        sub             r12,-2     //add 1 word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 4 save to local port   1 cycle
	        sub             r12,-2     //add 1 word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 5 save to local port   1 cycle
	        sub             r12,-2     //add 1 word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 6 save to local port   1 cycle
	        sub             r12,-2     //add 1 word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] // get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 7 save to local port   1 cycle
	        sub             r12,-2     //add 1 word to r12  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop

	        ld.uh   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 8 save to local port   1 cycle
	        sub             r12,14     //back to beginning of tile row  1 cycle
	        nop                                     //1 cycle
	        nop                                     // 1 cycle
	        nop
	        nop
	        nop
	.endr


	// USE OFFSET to ACCESS Output Value register
	mov  r6, 0x0FFF
	orh      r6, 0x0000                                             // RGB=0,0,0
	st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6

	        mov             pc,lr           // return from rcall 1 cycle???











	        .align 4
	        // video line number in R8
	        // destroys r5,r6,r7,r8,r10
	        //        r5= sprite_video_buffer pointer
	        // inputs r12 =tile memory pointer ram,word wide-- modified
	        //        r11= video memory pointer ram,byte wide-- modified
	        //  40*9*8+2=2882 clock counts
	        //  or 1441 timer ticks
	        send_video_line_indexed_wsprites:

	                // r8 contains video line number we are doing,
	                // calculate r11 offset for this video line
	// active video starts on   line 16 end on line 240
	//  map 1200 tile locations in video memory to these video lines
	                sub     r8,16  // start on line 16 as active video line 0
	                mov     r6,r8  // copy r8 into temp r6
	                lsr     r8,3 // divide by 8 to get video memory row
	                mul     r8,r8,40  // multiply video memory row (r8) by 40 to get video memory index offset
	                add     r11,r8 // add r8 line offset to video memory pointer
	                              // r11 now points to 1st column tile # in video memory for this line

	                // now get r12 to point to proper line in tile memory

	                andl     r6,0x07 // video line number..keep only lower 3 bits mask out others
	                lsl     r6,4  // multiply by 16 ( 2 bytes *8 pixels rows)
	                add     r12,r6  // this is the offset for r12
	        .rept 36   // 40 tile loop , 1 video line , 1 row in pixelmap, 9 clocks per pixel
	                ld.ub   r10,r11       //  1 cycles get next tile number from video memory,  2 cycles
	                lsl     r10,7                   // tiles are 128 =8*8*2 bytes long,

	                ld.sh   r7,r5++       // 2 cycles get sprite buffer pixel
	                cp.w    r7,0          // test if sprite has a msb set on the pixel word
	                ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                movmi   r6,r7    // put tile word in r6
	                st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                sub             r12,-2     //  add 1 word to r12 1 cycle
	                st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                sub      R11,-1                           // INC R11 1 cycle


                                ld.sh   r7,r5++        // 2 cycles get sprite buffer pixel
                                cp.w   r7,0          // test if sprite has a msb set on the pixel word
	                        ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                        movmi   r6,r7    // put tile word in r6
	                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                        sub             r12,-2     //  add 1 word to r12 1 cycle
	                        st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                        nop                                     // 1 cycle



	                        ld.sh   r7,r5++       // 2 cycles  get sprite buffer pixel
	                        cp.w   r7,0          // test if sprite has a msb set on the pixel word
	                         ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                         movmi   r6,r7    // put tile word in r6
	                         st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                         sub             r12,-2     //  add 1 word to r12 1 cycle
	                         st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                         nop                                     // 1 cycle



	                         ld.sh   r7,r5++        // 2 cycles get sprite buffer pixel
	                         cp.w   r7,0          // test if sprite has a msb set on the pixel word
	                          ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                          movmi   r6,r7   // put tile word in r6
	                          st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                          sub             r12,-2     //  add 1 word to r12 1 cycle
	                          st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                          nop                                     // 1 cycle



	                          ld.sh   r7,r5++        // 2 cycles  get sprite buffer pixel
	                          cp.w   r7,0         // test if sprite has a msb set on the pixel word
	                           ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                           movmi   r6,r7     // put tile word in r6
	                           st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                           sub             r12,-2     //  add 1 word to r12 1 cycle
	                           st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                           nop                                     // 1 cycle



	                           ld.sh   r7,r5++        // 2cycles get sprite buffer pixel
	                           cp.w   r7,0         // test if sprite has a msb set on the pixel word
	                            ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                            movmi   r6,r7     // put tile word in r6
	                            st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                            sub             r12,-2     //  add 1 word to r12 1 cycle
	                            st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                            nop                                     // 1 cycle



	                            ld.sh   r7,r5++       // 2 cycles  get sprite buffer pixel
	                            cp.w   r7,0         // test if sprite has a msb set on the pixel word
	                             ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                             movmi   r6,r7    // put tile word in r6
	                             st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                             sub             r12,-2     //  add 1 word to r12 1 cycle
	                             st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle
	                             nop                                     // 1 cycle



	                             ld.sh   r7,r5++       // 2 cycles  get sprite buffer pixel
	                             cp.w   r7,0         // test if sprite has a msb set on the pixel word
	                              ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                              movmi   r6,r7    // put tile word in r6
	                              st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                              sub             r12,14     //  add 1 word to r12 1 cycle
	                              st.h    r5[-2],R0                         //zero out sprite buffer 1 cycle                                     //1 cycle



	        .endr


	        // USE OFFSET to ACCESS Output Value register
	        mov  r6, 0x0FFF
	        orh      r6, 0x0000                                             // RGB=0,0,0
	        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6

	                mov             pc,lr           // return from rcall 1 cycle???



                        ld.sh   r7,r5++[0]      // get sprite buffer pixel
                        cp.w   r7,0            // test if sprite has a msb set on the pixel word
                        ld.uh   r6,r12[R10] // HSB Access get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
                        movmi   r6,r7       // put tile word in r6
                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
                        sub             r12,-2     //  add 1 word to r12 1 cycle
                        nop                                     //1 cycle
                        nop                                     // 1 cycle
                        nop
















	        // video line number in R8
	        // destroys r6,r10
	        // inputs r12 =tile memory pointer ram,word wide-- modified
	        //        r11= video memory pointer ram,byte wide-- modified
	        //  40*9*8+2=2882 clock counts
	        //  or 1441 timer ticks
	        send_video_line_indexed_32bit:

	                // r8 contains video line number we are doing,
	                // calculate r11 offset for this video line
	// active video starts on   line 16 end on line 240
	//  map 1200 tile locations in video memory to these video lines
	                sub     r8,16  // start on line 16 as active video line 0
	                mov     r6,r8  // copy r8 into temp r6
	                lsr     r8,3 // divide by 8 to get video memory row
	                mul     r8,r8,40  // multiply video memory row (r8) by 40 to get video memory index offset
	                add     r11,r8 // add r8 line offset to video memory pointer
	                              // r11 now points to 1st column tile # in video memory for this line

	                // now get r12 to point to proper line in tile memory

	                andl     r6,0x07 // video line number..keep only lower 3 bits mask out others
	                lsl     r6,4  // multiply by 16 ( 2 bytes *8 pixels rows)
	                add     r12,r6  // this is the offset for r12
	        .rept 37   // 40 tile loop , 1 video line , 1 row in pixelmap, 9 clocks per pixel
	                ld.ub   r10,r11++[0]       //  get next  tile number from video memory,  2 cycles
	                lsl     r10,7                   // tiles are 128 =8*8*2 bytes long,
	                ld.w   r6,r12[R10] // localAccess get pixel word for 2tile pixels->   1 cycle + 1+1Wait =3 cycles
	                st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 1 save to local port   1 cycle
	                sub             r12,-4     //  add 1 word to r12 1 cycle
	                swap.h r6         //prepare next pixel save from upper half word                       //1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle



	                nop
	                st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 2 save to local port   1 cycle
	                nop           // 1 cycle
	                nop                                     //1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop
	                nop

	                ld.w   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
	                st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 3 save to local port   1 cycle
	                sub             r12,-4     //add 1 word to r12  1 cycle
	                swap.h r6                                //1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop
	                nop

	                nop
	                st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 4 save to local port   1 cycle
	                nop            // 1 cycle
	                nop                                     //1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop                                     // 1 cycle
	                nop
	                nop

                        ld.w   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 3 save to local port   1 cycle
                        sub             r12,-4     //add 1 word to r12  1 cycle
                        swap.h r6                                //1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop
                        nop

                        nop
                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 4 save to local port   1 cycle
                        nop            // 1 cycle
                        nop                                     //1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop
                        nop

                        ld.w   r6,r12[R10] //  get pixel word for tile->   1 cycle + 1+1Wait =3 cycles
                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 3 save to local port   1 cycle
                        sub             r12,-4     //add 1 word to r12  1 cycle
                        swap.h r6                                //1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop
                        nop

                        nop
                        st.h    R0[AVR32_GPIO_LOCAL_OVR+0x100],r6  // pixel 4 save to local port   1 cycle
                        sub             r12,16           // 1 cycle
                        nop                                     //1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop                                     // 1 cycle
                        nop
                        nop
	        .endr


	        // USE OFFSET to ACCESS Output Value register
	        mov  r6, 0x0FFF
	        orh      r6, 0x0000                                             // RGB=0,0,0
	        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6

	                mov             pc,lr           // return from rcall 1 cycle???










send_hsync:
    // 580 clocks exactly  including return
        sub  r8,-1    // one more line
        mov  r6, 0x0000                 //c1 clock
        orh  r6, 0x0000                                             // BLACK RGB=0,0,0 //c2 clock
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                //c3 clock

//     /// wait ~2us 114 clock cycles
//        mov  r6,114/5   //1 cycle
//h0:     sub  r6,1    // 1 cycle
//        brne  h0         // 3 cycles if br taken
//        nop   //c116
//        nop   //c117

    // Csync low for 4.7us  on PORT A Bit 31
	mov  R7, 0x0000                                //c4
	orh	 R7, 0x8000                                //c5
	st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // CLR CSYNC bit 31 forPORT 0 bit 31  //c6

   /// wait 4.7us 269 clock cycles
        mov  r6,265/5  //1 cycle
h1:        sub  r6,1    // 1 cycle
        brne  h1         // 3 cycles if br taken
        nop  //c268



    // Csync high  269

	st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c269
//
// wait  311 more clocks until active line time

       mov  r6,310/5   //1 cycle
h2:    sub  r6,1    // 1 cycle
       brne  h2         // 3 cycles if br taken

       nop  // 311

       nop  //c579
//  run audio here??

//	mov		video_port_addr,AVR32_GPIO_LOCAL

	mov		pc,lr		// return from rcall 1clock  //c3640

send_vsync_neg:
// send negative going vsync pulse at twice the frame rate
// 3640 clocks exactly  including return
// seperated into 2 section 1820 clock each
     sub  r8,-1    // one more line
     mov  r6, 0x0000                 //c1 clock
     orh  r6, 0x0000                                             // BLACK RGB=0,0,0 //c2 clock
     st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                //c3 clock

//  /// wait ~2us 114 clock cycles
//     mov  r6,114/5   //1 cycle
//vn0:     sub  r6,1    // 1 cycle
//     brne  vn0         // 3 cycles if br taken
//     nop   //c116
//     nop   //c117

 // Csync low for 4.7us  on PORT A Bit 31
     mov  R7, 0x0000                                //c118
     orh      R7, 0x8000                                //c119
     st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // CLR CSYNC bit 31 forPORT 0 bit 31  //c120

/// wait 4.7us 269 clock cycles
     mov  r6,265/5   //1 cycle
vn1:        sub  r6,1    // 1 cycle
     brne  vn1         // 3 cycles if br taken
     nop  //c265
     nop  //c266
     nop  //c267
     nop  //c268

 // Csync high  269

     st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c269
//
// wait  for 1820-269-6= 1545 clock cycles 1/2 active line time

    mov  r6,1545/5   //1 cycle
vn2:    sub  r6,1    // 1 cycle
    brne  vn2         // 3 cycles if br taken

    nop  //c1819
    nop  //c1820
//  run audio here??

    // second half
    // 1820 clocks exactly  including return
         mov  r6, 0x0000                 //c1821 clock
         orh  r6, 0x0000                                             // BLACK RGB=0,0,0 //c1822 clock
         st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                //c1823 clock

//      /// wait ~2us 114 clock cycles
//         mov  r6,114/4   //1 cycle
// vn3:     sub  r6,1    // 1 cycle
//         brne  vn3         // 3 cycles if br taken
//         nop   //c1939
//         nop   //c1940

     // Csync low for 4.7us  on PORT A Bit 31
         mov  R7, 0x0000                                //c1941
         orh      R7, 0x8000                                //c1942
         st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // CLR CSYNC bit 31 forPORT 0 bit 31  //c1943

    /// wait 4.7us 269 clock cycles
         mov  r6,265/5   //1 cycle
 vn4:        sub  r6,1    // 1 cycle
         brne  vn4         // 3 cycles if br taken
         nop  //c2088
         nop
         nop
         nop

     // Csync high  269

         st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c2089
 //
 // wait 24.4us for 1548 clock cycles active line time

        mov  r6,1545/5   //1 cycle
 vn5:    sub  r6,1    // 1 cycle
        brne  vn5         // 3 cycles if br taken

        nop  // 3638
        nop  //c3639
 //  run audio here??

//  run audio here??


        mov             pc,lr           // return from rcall  // c3640

send_vsync_pos:
        // send negative going vsync pulse at twive the frame rate
        // 3640 clocks exactly  including return
        // seperated into 2 section 1820 clock each
             sub  r8,-1    // one more line
             mov  r6, 0x0000                 //c1 clock
             orh  r6, 0x0000                                             // BLACK RGB=0,0,0 //c2 clock
             st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                //c3 clock

//          /// wait ~2us 114 clock cycles
//             mov  r6,114/4   //1 cycle
//     vp0:     sub  r6,1    // 1 cycle
//             brne  vp0         // 3 cycles if br taken
//             nop   //c116
//             nop   //c117

         // Csync high for 4.7us  on PORT A Bit 31
             mov  R7, 0x0000                                //c118
             orh      R7, 0x8000                                //c119
             st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // SET CSYNC bit 31 forPORT 0 bit 31  //c120

        /// wait 4.7us 269 clock cycles
             mov  r6,265/5   //1 cycle
        vp1:        sub  r6,1    // 1 cycle
             brne  vp1         // 3 cycles if br taken
             nop
             nop
             nop
             nop  //c268
         // Csync low  269

             st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // CLEAR CSYNC bit 31 forPORT 0 bit 31  //c269
        //
        // wait 24.4us for 1545 clock cycles 1/2 active line time

            mov  r6,1545/5   //1 cycle
        vp2:    sub  r6,1    // 1 cycle
            brne  vp2         // 3 cycles if br taken

            nop  //c1819
            nop  //c1820
        //  run audio here??

            // second half
            // 1820 clocks exactly  including return
                 mov  r6, 0x0000                 //c1821 clock
                 orh  r6, 0x0000                                             // BLACK RGB=0,0,0 //c1822 clock
                 st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                //c1823 clock

//              /// wait ~2us 114 clock cycles
//                 mov  r6,114/4   //1 cycle
//         vp3:     sub  r6,1    // 1 cycle
//                 brne  vp3         // 3 cycles if br taken
//                 nop   //c1939
//                 nop   //c1940

             // Csync high for 4.7us  on PORT A Bit 31
                 mov  R7, 0x0000                                //c1941
                 orh      R7, 0x8000                                //c1942
                 st.w R0[AVR32_GPIO_LOCAL_OVRS + 0], R7  // set CSYNC bit 31 forPORT 0 bit 31  //c1943

            /// wait 4.7us 269 clock cycles
                 mov  r6,265/5   //1 cycle
         vp4:        sub  r6,1    // 1 cycle
                 brne  vp4         // 3 cycles if br taken
                 nop
                 nop
                 nop
                 nop  //c2088
             // Csync high  269

                 st.w R0[AVR32_GPIO_LOCAL_OVRC + 0], R7  // clr CSYNC bit 31 forPORT 0 bit 31  //c2089
         //
         // wait 24.4us for 1548 clock cycles active line time

                mov  r6,1545/5   //1 cycle
         vp5:    sub  r6,1    // 1 cycle
                brne  vp5         // 3 cycles if br taken

                nop  // 3638
                nop  //c3639
         //  run audio here??

        //  run audio here??


                mov             pc,lr           // return from rcall  // c3640


one_line_black:
	//52.6us  3640-580 =3060 clocks
        // USE OFFSET to ACCESS Output Value register
        mov  r6, 0x0000                 // 1 clock ?
        orh  r6, 0x0000                                             // RGB=0,0,0 // 1 clock ?
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

        mov  r6,3050/5
s1:        sub  r6,1    // 1 cycle
        brne  s1         // 3 cycles if br taken
        nop
        nop
        nop

        mov  r6, 0x0000                 // 1 clock ?  back to black
         st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
         mov             pc,lr           // return from rcall 1 cycle???

	mov             pc,lr           // return from rcall 1 cycle???


one_line_red:
     //52.6us  3640-580 =3060 clocks
     // USE OFFSET to ACCESS Output Value register
        mov  r6, 0x0F00                 // 1 clock ?
	orh  r6, 0x0000                                             // RGB=F,0,0 // 1 clock ?
	st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

	mov  r6,3050/5
s2:     sub  r6,1    // 1 cycle
	brne  s2         // 3 cycles if br taken
	nop
	nop
	nop

	mov  r6, 0x0000                 // 1 clock ?  back to black
	st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
        mov             pc,lr           // return from rcall 1 cycle???


one_line_blue:
    //52.6us  3640-580 =3060 clocks
    // USE OFFSET to ACCESS Output Value register
        mov  r6, 0x000F                 // 1 clock ?
        orh  r6, 0x0000                                             // RGB=0,0,F // 1 clock ?
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

        mov  r6,3050/5
s3:     sub  r6,1    // 1 cycle
        brne  s3         // 3 cycles if br taken
        nop
        nop
        nop
        mov  r6, 0x0000                 // 1 clock ?  back to black
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
        mov             pc,lr           // return from rcall 1 cycle???

        mov             pc,lr           // return from rcall 1 cycle???

one_line_white:
      //52.6us  3640-580 =3060 clocks
      // USE OFFSET to ACCESS Output Value register
        mov  r6, 0x0FFF                 // 1 clock ?
        orh      r6, 0x0000                                             // RGB=0,0,F // 1 clock ?
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

        mov  r6,3050/5
        s4:     sub  r6,1    // 1 cycle
        brne  s4         // 3 cycles if br taken
        nop
         nop
         nop
        mov  r6, 0x0000                 // 1 clock ?  back to black
        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
        mov             pc,lr           // return from rcall 1 cycle???

        mov             pc,lr           // return from rcall 1 cycle???

        one_line_color_r6:
              //52.6us  3640-580 =3060 clocks
              // USE OFFSET to ACCESS Output Value register
                nop
                // RGB=0,0,0 passed in r6
                st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

                mov  r6,3050/5
                oc1:     sub  r6,1    // 1 cycle
                brne  oc1         // 3 cycles if br taken
                nop
                 nop
                 nop
                mov  r6, 0x0000                 // 1 clock ?  back to black
                st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                mov             pc,lr           // return from rcall 1 cycle???

                mov             pc,lr           // return from rcall 1 cycle???

#define bar_delay 420/5
#define end_delay (3060-(7*bar_delay*5))/5
                one_line_smpte:
                      //52.6us  3640-580 =3060 clocks
                      // USE OFFSET to ACCESS Output Value register
                        mov  r6, 0x0FFF                 // WHITE 75 % color bar
                        orh      r6, 0x0000                                             // RGB=C,C,C 75% white // 1 clock ?
                        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?

                        mov  r6,bar_delay
                        sm1:     sub  r6,1    // 1 cycle
                        brne  sm1         // 3 cycles if br taken
                        nop // extra 1
                         nop// 436


                         mov  r6, 0x0FF0                // Yellow 75 % color bar
                           st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                           mov  r6,bar_delay
                            sm2:     sub  r6,1    // 1 cycle
                            brne  sm2         // 3 cycles if br taken
                            nop // extra 1
                             nop// 436


                             mov  r6, 0x00FF                // cyan 75 % color bar
                               st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                               mov  r6,bar_delay
                                sm3:     sub  r6,1    // 1 cycle
                                brne  sm3         // 3 cycles if br taken
                                nop // extra 1
                                 nop// 436

                                 mov  r6, 0x00F0                // green 75 % color bar
                                   st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                                   mov  r6,bar_delay
                                    sm4:     sub  r6,1    // 1 cycle
                                    brne  sm4         // 3 cycles if br taken
                                    nop // extra 1
                                     nop// 436


                                     mov  r6, 0x0F0F                // magenta  75 % color bar
                                       st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                                       mov  r6,bar_delay
                                        sm5:     sub  r6,1    // 1 cycle
                                        brne  sm5         // 3 cycles if br taken
                                        nop // extra 1
                                         nop// 436



                                         mov  r6, 0x0F00                // RED 75 % color bar
                                           st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                                           mov  r6,bar_delay
                                            sm6:     sub  r6,1    // 1 cycle
                                            brne  sm6         // 3 cycles if br taken
                                            nop // extra 1
                                             nop// 436


                                             mov  r6, 0x000F                // blue 75 % color bar
                                               st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                                               mov  r6,bar_delay
                                                sm7:     sub  r6,1    // 1 cycle
                                                brne  sm7         // 3 cycles if br taken
                                               // nop // extra 1
                                               //  nop// 436







                        mov  r6, 0x0000                 // 1 clock ?  back to black
                        st.h R0[AVR32_GPIO_LOCAL_OVR+0x100], R6                 // 1 clock ?
                        mov  r6,end_delay
                                sm8:     sub  r6,1    // 1 cycle
                                brne  sm8         // 3 cycles if br taken
                                  // nop // extra 1
                                  //  nop// 436


                        mov             pc,lr           // return from rcall 1 cycle???



