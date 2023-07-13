/* Copyright (C) 2020-2021 Free Software Foundation, Inc.

   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <http://www.gnu.org/licenses/>.  */

/* Don't rely on this, the interface is currently messed up and may need to
   be broken to be fixed.  */
#ifndef _SYS_UCONTEXT_H
#define _SYS_UCONTEXT_H	1

#include <features.h>

#include <bits/types/sigset_t.h>
#include <bits/types/stack_t.h>

typedef unsigned long int __loongarch_mc_gp_state[32];

#ifdef __USE_MISC
# define LARCH_NGREG	32

# define LARCH_REG_RA 1
# define LARCH_REG_SP 3
# define LARCH_REG_S0 23
# define LARCH_REG_S1 24
# define LARCH_REG_A0 4
# define LARCH_REG_S2 25
# define LARCH_REG_NARGS 8

typedef unsigned long int greg_t;

/* Container for all general registers.  */
typedef __loongarch_mc_gp_state gregset_t;

/* Container for floating-point state.  */
typedef union __loongarch_mc_fp_state fpregset_t;
#endif



union __loongarch_mc_fp_state {
    unsigned int   __val32[256 / 32];
    unsigned long long   __val64[256 / 64];
};

typedef struct mcontext_t {
    unsigned long long   __pc;
    unsigned long long   __gregs[32];
    unsigned int   __flags;

    unsigned int   __fcsr;
    unsigned int   __vcsr;
    unsigned long long   __fcc;
    union __loongarch_mc_fp_state    __fpregs[32] __attribute__((__aligned__ (32)));

    unsigned int   __reserved;
} mcontext_t;

/* Userlevel context.  */
typedef struct ucontext_t
  {
    unsigned long int  __uc_flags;
    struct ucontext_t *uc_link;
    stack_t            uc_stack;
    mcontext_t uc_mcontext;
    sigset_t           uc_sigmask;
  } ucontext_t;

#endif /* sys/ucontext.h */
