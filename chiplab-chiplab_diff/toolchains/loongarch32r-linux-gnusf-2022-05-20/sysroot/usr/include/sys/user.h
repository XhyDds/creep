/* Copyright (C) 2001-2018 Free Software Foundation, Inc.
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
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#ifndef _SYS_USER_H
#define _SYS_USER_H	1

#include <stdint.h>

struct user_regs_struct
{
#ifdef __loongarch64
  uint64_t gpr[32];
  uint64_t pc;
  uint64_t badvaddr;
  uint64_t reserved[11];
#elif defined __loongarch32r
  uint32_t gpr[32];
  uint32_t pc;
  uint32_t badvaddr;
  uint32_t reserved[11];
#else
#error "not defined ISA in loongarch"
#endif
};

#endif	/* _SYS_USER_H */
