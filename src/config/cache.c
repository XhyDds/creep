// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2020-2021 Loongson Technology Corporation Limited
 *
 * Derived from MIPS:
 * Copyright (C) 1994 - 2003, 06, 07 by Ralf Baechle (ralf@linux-mips.org)
 * Copyright (C) 2007 MIPS Technologies, Inc.
 */
#include <linux/export.h>
#include <linux/fcntl.h>
#include <linux/fs.h>
#include <linux/highmem.h>
#include <linux/kernel.h>
#include <linux/linkage.h>
#include <linux/mm.h>
#include <linux/sched.h>
#include <linux/syscalls.h>

#include <asm/cacheflush.h>
#include <asm/cpu.h>
#include <asm/cpu-features.h>
#include <asm/dma.h>
#include <asm/loongarchregs.h>
#include <asm/processor.h>
#include <asm/setup.h>

/* Cache operations. */
void local_flush_icache_range(unsigned long start, unsigned long end)
{
	asm volatile ("\tibar 0\n"::);
}

void __update_cache(unsigned long address, pte_t pte)
{
	struct page *page;
	unsigned long pfn, addr;

	pfn = pte_pfn(pte);
	if (unlikely(!pfn_valid(pfn)))
		return;
	page = pfn_to_page(pfn);
	if (Page_dcache_dirty(page)) {
		if (PageHighMem(page))
			addr = (unsigned long)kmap_atomic(page);
		else
			addr = (unsigned long)page_address(page);

		if (PageHighMem(page))
			kunmap_atomic((void *)addr);

		ClearPageDcacheDirty(page);
	}
}

void cache_error_setup(void)
{
	extern char __weak except_vec_cex;
	set_merr_handler(0x0, &except_vec_cex, 0x80);
}

static unsigned long icache_size __read_mostly;
static unsigned long dcache_size __read_mostly;
static unsigned long scache_size __read_mostly;

static char *way_string[] = { NULL, "direct mapped", "2-way",
	"3-way", "4-way", "5-way", "6-way", "7-way", "8-way",
	"9-way", "10-way", "11-way", "12-way",
	"13-way", "14-way", "15-way", "16-way",
};

#ifdef CONFIG_32BIT

/* DMA cache operations. */
void (*_dma_cache_wback_inv)(unsigned long start, unsigned long size);
void (*_dma_cache_wback)(unsigned long start, unsigned long size);
void (*_dma_cache_inv)(unsigned long start, unsigned long size);

static void la32_dma_cache_wback_inv(unsigned long addr, unsigned long size)
 {
     /* Catch bad driver code */
     BUG_ON(size == 0);

     if (size >= dcache_size) {
         blast_dcache16();
     } else {
         blast_dcache_range(addr, addr + size);
     }
}

static void la32_dma_cache_inv(unsigned long addr, unsigned long size)
{
    /* Catch bad driver code */
    BUG_ON(size == 0);

    if ( size >= dcache_size) {
        blast_dcache16();
    } else {
        unsigned long lsize = cpu_dcache_line_size();
        unsigned long almask = ~(lsize - 1);

        cache_op(Hit_Writeback_Inv_D, addr & almask);
        cache_op(Hit_Writeback_Inv_D, (addr + size - 1)  & almask);
        blast_inv_dcache_range(addr, addr + size);
    }

}

#endif

static void probe_pcache(void)
{
	struct cpuinfo_loongarch *c = &current_cpu_data;
	// unsigned int lsize, sets, ways;
	// unsigned int config;

	// config = 0xfe994cd3;

	// lsize = (config >> 19) & 7;
	// sets  = 1 << ((config & CPUCFG17_L1I_SETS_M) >> CPUCFG17_L1I_SETS);
	// ways  = ((config & CPUCFG17_L1I_WAYS_M) >> CPUCFG17_L1I_WAYS) + 1;

	// if (lsize)
    //                     c->icache.linesz = 2 << lsize;
    //             else
    //                     c->icache.linesz = 0;
	// c->icache.sets = 64 << ((config >> 22) & 7);
	// c->icache.ways = 1 + ((config >> 16) & 7);
	c->icache.linesz = 128;
	c->icache.sets = 32;
	c->icache.ways = 2;
	icache_size = c->icache.sets *
                                          c->icache.ways *
                                          c->icache.linesz;
	c->icache.waysize = icache_size / c->icache.ways;


	// lsize = (config >> 10) & 7;
	// sets  = 1 << ((config & CPUCFG18_L1D_SETS_M) >> CPUCFG18_L1D_SETS);
	// ways  = ((config & CPUCFG18_L1D_WAYS_M) >> CPUCFG18_L1D_WAYS) + 1;

	// if (lsize) {
    //     c->dcache.linesz = 2 << lsize;
    // }
    // else {
    //     c->dcache.linesz = 0;
    // }
	// c->dcache.sets = 64 << ((config >> 13) & 7);
	// c->dcache.ways = 1 + ((config >> 7) & 7);
	c->dcache.linesz = 128;
	c->dcache.sets = 32;
	c->dcache.ways = 2;
	dcache_size = c->dcache.sets *
                                          c->dcache.ways *
                                          c->dcache.linesz;
	c->dcache.waysize = dcache_size / c->dcache.ways;

	c->scache.linesz = 128;
	c->scache.sets = 32;
	c->scache.ways = 8;
	scache_size = c->scache.sets *
                                          c->scache.ways *
                                          c->scache.linesz;
	c->scache.waysize = scache_size / c->scache.ways;

	c->options |= LOONGARCH_CPU_PREFETCH;

	pr_info("Primary instruction cache %ldkB, %s, %s, linesize %d bytes.\n",
		icache_size >> 10, way_string[c->icache.ways], "VIPT", c->icache.linesz);

	pr_info("Primary data cache %ldkB, %s, %s, %s, linesize %d bytes\n",
		dcache_size >> 10, way_string[c->dcache.ways], "VIPT", "no aliases", c->dcache.linesz);

	pr_info("l2cache %ldkB, %s, %s, %s, linesize %d bytes\n",
		scache_size >> 10, way_string[c->scache.ways], "PIPT", "no aliases", c->scache.linesz);
		
#ifdef CONFIG_32BIT
    _dma_cache_wback_inv    = la32_dma_cache_wback_inv;
    _dma_cache_wback    = la32_dma_cache_wback_inv;
    _dma_cache_inv      = la32_dma_cache_inv;
#endif

}

void cpu_cache_init(void)
{
	probe_pcache();
	shm_align_mask = PAGE_SIZE - 1;
}
