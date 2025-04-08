module mm.vmm;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 5, 2025
 */

import mm.pmm;
import lib.log;
import util.string;
import init.entry;
import lib.math;
import init.limine;

/* External */
__gshared extern (C) extern char[] limineStart, limineEnd;
__gshared extern (C) extern char[] textStart, textEnd;
__gshared extern (C) extern char[] rodataStart, rodataEnd;
__gshared extern (C) extern char[] dataStart, dataEnd;

/* Constants */
enum VMM_PRESENT = 1LU << 0;
enum VMM_WRITE = 1LU << 1;
enum VMM_USER = 1LU << 2;
enum VMM_NX = 1LU << 63;

enum PAGE_MASK = 0x000FFFFFFFFFF000;
enum PAGE_INDEX_MASK = 0x1FF;

enum PML1_SHIFT = 12;
enum PML2_SHIFT = 21;
enum PML3_SHIFT = 30;
enum PML4_SHIFT = 39;

/* Globals */
__gshared PageMap kernelPagemap;

/* The big man */
struct PageMap
{
    ulong* table;

    this(ulong* t)
    {
        assert(t, "Invalid table passed to pagemap constructor");
        this.table = t;
    }

    private ulong pageIndex(ulong virt, uint shift) const
    {
        return (virt >> shift) & PAGE_INDEX_MASK;
    }

    private ulong* getTableOrAlloc(ulong* table, ulong index, ulong flags)
    {
        if (!(table[index] & VMM_PRESENT))
        {
            const newPage = physRequestPages(1, false);
            memset(cast(void*)(cast(ulong) newPage + hhdmOffset), 0, PAGE_SIZE);
            table[index] = cast(ulong) newPage | flags;
        }
        else
        {
            table[index] |= (flags & ~VMM_NX) & 0xff;
        }
        return cast(ulong*)((table[index] & PAGE_MASK) + hhdmOffset);
    }

    private ulong* getTable(ulong* table, ulong index)
    {
        return cast(ulong*)((table[index] & PAGE_MASK) + hhdmOffset);
    }

    ulong virtToPhys(ulong virt)
    {
        const pml4Idx = pageIndex(virt, PML4_SHIFT);
        if (!(kernelPagemap.table[pml4Idx] & VMM_PRESENT))
            return 0;

        ulong* pml3 = getTable(kernelPagemap.table, pml4Idx);
        const pml3Idx = pageIndex(virt, PML3_SHIFT);
        if (!(pml3[pml3Idx] & VMM_PRESENT))
            return 0;

        ulong* pml2 = getTable(pml3, pml3Idx);
        const pml2Idx = pageIndex(virt, PML2_SHIFT);
        if (!(pml2[pml2Idx] & VMM_PRESENT))
            return 0;

        ulong* pml1 = getTable(pml2, pml2Idx);
        const pml1Idx = pageIndex(virt, PML1_SHIFT);
        if (!(pml1[pml1Idx] & VMM_PRESENT))
            return 0;

        return pml1[pml1Idx] & PAGE_MASK;
    }

    void map(ulong virt, ulong phys, ulong flags)
    {
        assert(kernelPagemap.table, "Invalid table in pagemap!");
        const pml4Idx = pageIndex(virt, PML4_SHIFT);
        const pml3Idx = pageIndex(virt, PML3_SHIFT);
        const pml2Idx = pageIndex(virt, PML2_SHIFT);
        const pml1Idx = pageIndex(virt, PML1_SHIFT);

        ulong* pml3 = getTableOrAlloc(kernelPagemap.table, pml4Idx, flags);
        ulong* pml2 = getTableOrAlloc(pml3, pml3Idx, flags);
        ulong* pml1 = getTableOrAlloc(pml2, pml2Idx, flags);

        const newEntry = (phys & PAGE_MASK) | flags;

        if (!(pml1[pml1Idx] & VMM_PRESENT))
            pml1[pml1Idx] = newEntry;
        else
            pml1[pml1Idx] = (pml1[pml1Idx] & ~PAGE_MASK) | newEntry;
    }

    void unmap(ulong virt)
    {
        const pml4Idx = pageIndex(virt, PML4_SHIFT);
        const pml3Idx = pageIndex(virt, PML3_SHIFT);
        const pml2Idx = pageIndex(virt, PML2_SHIFT);
        const pml1Idx = pageIndex(virt, PML1_SHIFT);

        if (!(kernelPagemap.table[pml4Idx] & VMM_PRESENT))
            return;

        ulong* pml3 = cast(ulong*)((kernelPagemap.table[pml4Idx] & PAGE_MASK) + hhdmOffset);
        if (!(pml3[pml3Idx] & VMM_PRESENT))
            return;

        ulong* pml2 = cast(ulong*)((pml3[pml3Idx] & PAGE_MASK) + hhdmOffset);
        if (!(pml2[pml2Idx] & VMM_PRESENT))
            return;

        ulong* pml1 = cast(ulong*)((pml2[pml2Idx] & PAGE_MASK) + hhdmOffset);
        if (pml1[pml1Idx] & VMM_PRESENT)
            pml1[pml1Idx] = 0;
    }
}

void switchPagemap(PageMap* pagemap)
{
    const phys = cast(ulong) pagemap.table - hhdmOffset;
    kprintf("Switching to pagemap with phys=0x%.16llx", phys);
    asm
    {
        mov RAX, phys;
        mov CR3, RAX;
    }
}

void vmmInit()
{
    kernelPagemap = PageMap(cast(ulong*) physRequestPages(1, true));
    assert(kernelPagemap.table, "Failed to allocate kernel pagemap");
    kprintf("Kernel pagemap table allocated at: 0x%.16llx", cast(ulong) kernelPagemap.table);
    memset(kernelPagemap.table, 0, PAGE_SIZE);

    kprintf("Kernel Stack Top Address: 0x%.16llx", kernelStackTop);
    kprintf("Got kernel phys: 0x%.16llx, virt: 0x%.16llx", kernelAddrPhys, kernelAddrVirt);

    kprintf("Sections:");
    kprintf("  limine: start=0x%.16llx, end=0x%.16llx", cast(ulong)&limineStart, cast(ulong)&limineEnd);
    kprintf("  text  : start=0x%.16llx, end=0x%.16llx", cast(ulong)&textStart, cast(ulong)&textEnd);
    kprintf("  rodata: start=0x%.16llx, end=0x%.16llx", cast(ulong)&rodataStart, cast(ulong)&rodataEnd);
    kprintf("  data  : start=0x%.16llx, end=0x%.16llx", cast(ulong)&dataStart, cast(ulong)&dataEnd);

    if (cast(ulong)&limineStart - cast(ulong)&limineEnd != 0)
    {
        ulong limineStartAligned = alignDown!ulong(cast(ulong)&limineStart, PAGE_SIZE);
        ulong limineEndAligned = alignUp!ulong(cast(ulong)&limineEnd, PAGE_SIZE);
        for (ulong i = limineStartAligned; i < limineEndAligned; i += PAGE_SIZE)
        {
            kernelPagemap.map(i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_WRITE);
        }
        kprintf("Mapped limine section");
    }
    else
    {
        kprintf("Size of limine section's are zero?");
    }

    kernelStackTop = alignUp!ulong(kernelStackTop, PAGE_SIZE);
    for (ulong i = kernelStackTop - 65536; i < kernelStackTop; i += PAGE_SIZE)
    {
        kernelPagemap.map(i, i - hhdmOffset, VMM_PRESENT | VMM_WRITE | VMM_NX);
    }
    kprintf("Mapped kernel stack");

    // Map sections
    ulong textStartAligned = alignDown!ulong(cast(ulong)&textStart, PAGE_SIZE);
    ulong textEndAligned = alignUp!ulong(cast(ulong)&textEnd, PAGE_SIZE);
    for (ulong i = textStartAligned; i < textEndAligned; i += PAGE_SIZE)
    {
        kernelPagemap.map(i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT);
    }
    kprintf("Mapped text section");

    ulong rodataStartAligned = alignDown!ulong(cast(ulong)&rodataStart, PAGE_SIZE);
    ulong rodataEndAligned = alignUp!ulong(cast(ulong)&rodataEnd, PAGE_SIZE);
    for (ulong i = rodataStartAligned; i < rodataEndAligned; i += PAGE_SIZE)
    {
        kernelPagemap.map(i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_NX);
    }
    kprintf("Mapped rodata section");

    ulong dataStartAligned = alignDown!ulong(cast(ulong)&dataStart, PAGE_SIZE);
    ulong dataEndAligned = alignUp!ulong(cast(ulong)&dataEnd, PAGE_SIZE);
    for (ulong i = dataStartAligned; i < dataEndAligned; i += PAGE_SIZE)
    {
        kernelPagemap.map(i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_WRITE | VMM_NX);
    }
    kprintf("Mapped data section");

    // Map HHDM
    for (ulong addr = 0; addr < 0x100000000; addr += PAGE_SIZE)
    {
        kernelPagemap.map(addr + hhdmOffset, addr, VMM_PRESENT | VMM_WRITE);
    }
    kprintf("Mapped HHDM");

    // Map memory regions
    foreach (i; 0 .. memmap.entryCount)
    {
        // Just for debug
        MemmapEntry* entry = memmap.entries[i];
        kprintf("Entry %u: Base=0x%016lx Length=0x%016lx Type=%s",
            i,
            entry.base,
            entry.length,
            cast(char*) memoryTypeToString(entry.type).ptr
        );
    }

    for (ulong addr = 0; addr < 0x100000000; addr += PAGE_SIZE)
    {
        foreach (i; 0 .. memmap.entryCount)
        {
            MemmapEntry* entry = memmap.entries[i];
            if (entry.type == MemoryMapUsable || entry.type == MemoryMapKernelAndModules || entry.type == MemoryMapFramebuffer)
            {
                ulong entry_start = entry.base;
                ulong entry_end = entry.base + entry.length;

                if (addr >= entry_start && addr < entry_end)
                {
                    kernelPagemap.map(addr + hhdmOffset, addr, VMM_PRESENT | VMM_WRITE);
                    break;
                }
            }
        }
    }
    kprintf("Mapped usable memory regions.");

    switchPagemap(&kernelPagemap);
}
