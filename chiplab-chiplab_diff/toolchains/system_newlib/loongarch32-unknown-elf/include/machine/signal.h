/*
 * Copyright (c) 1996-2004 MIPS Technologies, Inc.
 * Copyright (C) 2009 CodeSourcery, LLC.
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 *      * Redistributions of source code must retain the above copyright
 *        notice, this list of conditions and the following disclaimer.
 *      * Redistributions in binary form must reproduce the above
 *      copyright
 *        notice, this list of conditions and the following disclaimer
 *        in the documentation and/or other materials provided with
 *        the distribution.
 *      * Neither the name of MIPS Technologies Inc. nor the names of its
 *        contributors may be used to endorse or promote products derived
 *        from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * signal.h : SDE signal handling definitions
 */


#ifndef __SYS_SIGNAL_H
#ifdef __cplusplus
extern "C" {
#endif
#define __SYS_SIGNAL_H

#if 0
#include <sys/posix.h>
#endif
#if !defined(_ANSI_SOURCE) || defined(_POSIX_SOURCE)
#include <sys/types.h>
#endif

#define	SIGHUP		1	/* hangup */
#define SIGINT		2	/* interrupt */
#define SIGQUIT		3	/* quit */
#define SIGILL		4	/* illegal instruction */
#ifndef _POSIX_SOURCE
#define SIGTRAP		5	/* break point trap */
#endif
#define SIGABRT		6	/* abort */
#ifndef _POSIX_SOURCE
#define SIGIOT		SIGABRT
#define SIGEMT		7	/* emulator trap */
#endif
#define SIGFPE		8	/* floating point exception */
#define SIGKILL		9	/* kill */
#ifndef _POSIX_SOURCE
#define SIGBUS		10	/* bus error */
#endif
#define SIGSEGV		11	/* segmentation violation */
#ifndef _POSIX_SOURCE
#define SIGSYS		12	/* bad argument to system call */
#endif
#define SIGPIPE		13	/* write on a pipe with no one to read it */
#define SIGALRM		14	/* alarm clock */
#define SIGTERM		15	/* software termination signal */
#ifndef _POSIX_SOURCE
#define SIGURG		16	/* urgent condition (on socket) */
#endif
#define SIGSTOP		17	/* stop (cannot be caught or ignored) */
#define SIGTSTP		18	/* interactive stop signal */
#define SIGCONT		19	/* continue if stopped */
#define SIGCHLD		20	/* child process terminated or stopped */
#define SIGTTIN		21	/* to reader's process group on bg read */
#define SIGTTOU		22	/* to writer's process group on bg write */
#ifndef _POSIX_SOURCE
#define	SIGIO		23	/* input/output possible signal */
#define SIGPOLL		23	/* System V i/o possible */
#define	SIGXCPU		24	/* exceeded CPU time limit */
#define	SIGXFSZ		25	/* exceeded file size limit */
#define	SIGVTALRM	26	/* virtual time alarm */
#define	SIGPROF		27	/* profiling time alarm */
#define SIGWINCH	28	/* window size changes */
#define SIGINFO		29	/* information request */
#endif
#define SIGUSR1		30	/* user defined signal 1 */
#define SIGUSR2		31	/* user defined signal 2 */

#if _POSIX_C_SOURCE >= 199309L
#define SIGRTMIN	33
#define SIGRTMAX	64
#endif

#define _NSIG	65
#ifndef _POSIX_SOURCE
#define NSIG	_NSIG
#endif

/* ANSI C */
#define	SIG_DFL		(void (*)())0
#define	SIG_IGN		(void (*)())1
#define	SIG_ERR		(void (*)())-1

/* argument to sigprocmask */
#define SIG_BLOCK 	1
#define SIG_UNBLOCK	2
#define SIG_SETMASK	3

#ifndef __ASSEMBLER__
__extension__ typedef unsigned long long sigset_t;

/* A type which can be written or read atomically, without signals intervening */
typedef int sig_atomic_t;

#if _POSIX_C_SOURCE >= 199309L
union sigval {
  void	*sival_ptr;
  int	sival_int;
};

typedef struct siginfo {
  int		si_signo;
  int		si_code;
#define SI_USER		0	/* kill, raise */
#define SI_QUEUE 	1	/* from sigqueue */
#define SI_TIMER 	2	/* timer expired */
#define SI_ASYNCIO	3	/* aio complete */
#define SI_MESGQ	4	/* real-time mesgq */
#define SI_SIGIO	5	/* queued SIGIO */
#define SI_NOINFO	6	/* no value */
#define SI_KERNEL	7	/* somewhere else */
#define SI_FAULT	8	/* cpu fault/exception */
  union sigval	si_value;
} siginfo_t;

struct sigevent {
  int		sigev_notify;
#define SIGEV_NONE	0
#define SIGEV_SIGNAL	1
#define SIGEV_THREAD	2
  int		sigev_signo;
  union sigval	sigev_value;
};

struct timespec;

int sigwaitinfo (const sigset_t *, siginfo_t *);
int sigtimedwait (const sigset_t *, siginfo_t *, const struct timespec *);
int sigwait (const sigset_t *, int *);
int sigqueue (pid_t, int, const union sigval);

#endif /* _POSIX_C_SOURCE >= 199309L */

/* signal vector template */
struct siginfo;

struct sigaction {
  union {
    void	(*usa_handler)(int); 	/* signal handler */
    void	(*usa_sigaction)(int,struct siginfo *,void *);
  } sa_u;
#define sa_handler	sa_u.usa_handler
#define sa_sigaction	sa_u.usa_sigaction
  sigset_t	sa_mask;	 	/* signal mask to apply */
  int		sa_flags;		/* BSD unsupport */
};

#if !defined(_ANSI_SOURCE) && !defined(_POSIX_SOURCE)
/*
 * BSD 4.3 compatibility:
 * Signal vector "template" used in sigvec call.
 */
struct  sigvec {
        void    (*sv_handler) (int); 	/* signal handler */
    	int 	sv_mask;                /* signal mask to apply */
        int     sv_flags;               /* see signal options below */
};
#define SV_ONSTACK      SA_ONSTACK
#define SV_INTERRUPT    SA_RESTART      /* same bit, opposite sense */
#define SV_RESETHAND    SA_RESETHAND
#define sv_onstack sv_flags
#endif

#endif

/* sa_flags */
#ifndef _POSIX_SOURCE
#define SA_ONSTACK 	0x0001		/* run on private stack */
#define SA_RESTART 	0x0002		/* restart some system calls */
#define SA_ONESHOT	0x0008		/* restore default handler */
#define SA_RESETHAND	0x0008		/* ditto */
#endif
#define SA_NOCLDSTOP 	0x0004		/* no SIGCHLD for stopped procs */
#define SA_SIGINFO 	0x0010		/* call sa_sigaction */

#ifndef __ASSEMBLER__
/* 
 * Prototypes
 */
void	(*signal (int,void (*)(int))) (int);
int	raise (int);

#if !defined(_ANSI_SOURCE) || defined(_POSIX_SOURCE)
int	kill (pid_t, int);
int	sigaction (int, const struct sigaction *, struct sigaction *);
int	sigpending (sigset_t *);
int	sigprocmask (int, const sigset_t *, sigset_t *);
int	sigsuspend (const sigset_t *);

#define sigemptyset(x)	(*(x)= 0 )
#define sigfillset(x)	(*(x)= ~(sigset_t)0, 0)
#define sigaddset(x,n)	(*(x) |= ((sigset_t)1<<((n)-1)), 0)
#define sigdelset(x,n)	(*(x) &= ~((sigset_t)1<<((n)-1)), 0)
#define sigismember(x,n)(((*x) & ((sigset_t)1<<((n)-1))) != 0)
#endif	/* !_ANSI_SOURCE */

#endif


#ifdef __cplusplus
}
#endif
#endif /* !__SYS_SIGNAL_H */
