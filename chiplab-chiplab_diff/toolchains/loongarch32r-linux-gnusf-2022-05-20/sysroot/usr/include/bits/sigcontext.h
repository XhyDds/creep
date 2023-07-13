/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 1996, 1997, 1999 by Ralf Baechle
 * Copyright (C) 1999 Silicon Graphics, Inc.
 */
#ifndef _BITS_SIGCONTEXT_H
#define _BITS_SIGCONTEXT_H

/*
 * Keep this struct definition in sync with the sigcontext fragment
 * in arch/mips/kernel/asm-offsets.c
 *
 * Warning: this structure illdefined with sc_badvaddr being just an unsigned
 * int so it was changed to unsigned long in 2.6.0-test1.  This may break
 * binary compatibility - no prisoners.
 * DSP ASE in 2.6.12-rc4.  Turn sc_mdhi and sc_mdlo into an array of four
 * entries, add sc_dsp and sc_reserved for padding.  No prisoners.
 */

#define FPU_REG_WIDTH           256
#define FPU_ALIGN               __attribute__((aligned(32)))

struct sigcontext {
    unsigned long long   sc_pc;
    unsigned long long    sc_regs[32];
    unsigned int   sc_flags;

    unsigned int   sc_fcsr;
    unsigned int   sc_vcsr;
    unsigned long long    sc_fcc;

    unsigned long long    sc_scr[4];

    union {
                unsigned int        val32[FPU_REG_WIDTH / 32];
                unsigned long long  val64[FPU_REG_WIDTH / 64];
        } sc_fpregs[32] FPU_ALIGN;
    unsigned char   sc_reserved[4096] __attribute__((__aligned__(16)));

};


#endif /* _BITS_SIGCONTEXT_H */
