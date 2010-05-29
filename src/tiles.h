/*
 * tiles.c
 *
 *  Created on: Oct 19, 2009
 *      Author: Administrator
 */
#ifndef _TILES_H_
#define _TILES_H_

#include "compiler.h"
// Choose your video mode Here.. Uncomment one of these lines
#define VIDEOMODE1  //240X240 interlaced display with 8x8 tiles and Sprites

#ifdef VIDEOMODE1  //240X240 interlaced display with 8x8 tiles and 32 8x8 Sprites

#define HORIZONTAL_RES 320
#define VERTICAL_RES 240
#define TILE_SIZE_X 8
#define TILE_SIZE_Y 8
#define NUM_TILES_X HORIZONTAL_RES/TILE_SIZE_X
#define NUM_TILES_Y VERTICAL_RES/TILE_SIZE_Y
#define NUM_SPRITES 32
#endif


enum spritemode {inactive,stop,running,manual,invisible};

// Sprites are same size as tiles and share tile image memory
// sprite objects have location and heading and velocity data
struct sprite_object{
    U16 xloc;
    U16 yloc;
    U8 zplane;
    U8 collision;
    enum spritemode mode;  // inactive, stop,running,manual,invisible
    U8 blinkrate; // 0=no blink, 60=toggel every 60 scans.. 1 per sec
    U8 alpha_style; // 0= black rgb=000 is alpha  1= white rgb=fff is alpha
    U16 xvelocity;  // pixels per video scan
    U16 yvelocity;  // pixels per video scan (1/2  frame)
    U16 heading;   // compass vector of motion

    U8 tile_number;  //pointer to tile video data for the sprite
};


extern U8 video_memory[NUM_TILES_X*NUM_TILES_Y];
extern U16 tile_memory[];
extern U16 sprite_video_buffer[NUM_TILES_X*TILE_SIZE_X];
extern struct sprite_object sprites [ NUM_SPRITES ];
extern U16 sprite_video_buffer[NUM_TILES_X*TILE_SIZE_X];



#endif  //_TILES_H

