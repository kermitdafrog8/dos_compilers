/*
 * Screen color definitions for DDS MICRO-C
 *
 * Contains definitions for common colors, and a MACRO to build the
 * value to be passed to MICRO-C's video and windowing functions from
 * the individual foreground and background colors.
 *
 * This file **REQUIRES** the extended pre-processor (MCP).
 *
 * Contributed by Steffen Kaiser
 * Copyright 1995-2020 Dave Dunfield
 * All rights reserved.
 */

#define C_BLACK		0
#define C_BLUE		1
#define C_GREEN		2
#define C_CYAN		3
#define C_RED		4
#define C_MAGENTA	5
#define C_BROWN		6
#define C_GREY		7

#define C_DARKGREY	8
#define C_YELLOW	14
#define C_WHITE		15

#define COLOR(f,b) (((b) & 0x7) << 4 | ((f) & 0xF))
