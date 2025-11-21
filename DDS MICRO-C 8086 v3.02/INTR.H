/*
 * DDS MICRO-C MS-DOS/8086 intr() register passing structure
 *
 * Copyright 1997-2020 Dave Dunfield
 * All rights reserved.
 */

struct REGPACK {
	union {
		struct {
			unsigned char r_al, r_ah, r_bl, r_bh, r_cl, r_ch, r_dl, r_dh;
		} _REGPACK_;
		struct {
			unsigned r_ax, r_bx, r_cx, r_dx;
		} _REGPACK_;
	} _REGPACK_;
	unsigned r_bp, r_si, r_di, r_ds, r_es, r_flags; };
