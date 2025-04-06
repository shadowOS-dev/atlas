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

/* External */
__gshared extern (C) extern char[] limineStart;
__gshared extern (C) extern char[] limineEnd;
__gshared extern (C) extern char[] textStart;
__gshared extern (C) extern char[] textEnd;
__gshared extern (C) extern char[] rodataStart;
__gshared extern (C) extern char[] rodataEnd;
__gshared extern (C) extern char[] dataStart;
__gshared extern (C) extern char[] dataEnd;

/* Defines */
enum VMM_PRESENT = (1LU << 0);
enum VMM_WRITE = (1LU << 1);
enum VMM_USER = (1LU << 2);
enum VMM_NX = (1LU << 63);

alias PageMap = ulong*;

/* Globals */
__gshared PageMap kernelPagemap;

/* Functions */
ulong virtToPhys(PageMap pagemap, ulong virt)
{
    ulong pml1Idx = (virt >> 12) & 0x1FF;
    ulong pml2Idx = (virt >> 21) & 0x1FF;
    ulong pml3Idx = (virt >> 30) & 0x1FF;
    ulong pml4Idx = (virt >> 39) & 0x1FF;

    if (!(pagemap[pml4Idx] & 1))
        return 0;
    PageMap pml3 = cast(PageMap)((pagemap[pml4Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    if (!(pml3[pml3Idx] & 1))
        return 0;
    PageMap pml2 = cast(PageMap)((pml3[pml3Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    if (!(pml2[pml2Idx] & 1))
        return 0;
    PageMap pml1 = cast(PageMap)((pml2[pml2Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    if (!(pml1[pml1Idx] & 1))
        return 0;

    return pml1[pml1Idx] & 0x000FFFFFFFFFF000;
}

void virtMap(PageMap pagemap, ulong virt, ulong phys, ulong flags)
{
    ulong pml1Idx = (virt & cast(ulong) 0x1ff << 12) >> 12;
    ulong pml2Idx = (virt & cast(ulong) 0x1ff << 21) >> 21;
    ulong pml3Idx = (virt & cast(ulong) 0x1ff << 30) >> 30;
    ulong pml4Idx = (virt & cast(ulong) 0x1ff << 39) >> 39;

    if (!(pagemap[pml4Idx] & VMM_PRESENT))
    {
        pagemap[pml4Idx] = cast(ulong) physRequestPages(1, false) | 0b111;
        kprintf("PML3 -> 0x%.16llx", pagemap[pml4Idx]);
    }

    PageMap pml3 = cast(PageMap)((pagemap[pml4Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    if (!(pml3[pml3Idx] & VMM_PRESENT))
    {
        pml3[pml3Idx] = cast(ulong) physRequestPages(1, false) | 0b111;
        kprintf("PML2 -> 0x%.16llx", pml3[pml3Idx]);
    }

    PageMap pml2 = cast(PageMap)((pml3[pml3Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    kprintf("PML2=0x%.16llx", cast(ulong) pml2);
    if (!(pml2[pml2Idx] & VMM_PRESENT))
    {
        pml2[pml2Idx] = cast(ulong) physRequestPages(1, false) | 0b111;
    }

    PageMap pml1 = cast(PageMap)((pml2[pml2Idx] & 0x000FFFFFFFFFF000) + hhdmOffset);
    pml1[pml1Idx] = phys | flags;

    asm
    {
        invlpg virt;
    }
}

void virtUnMap(PageMap pagemap, ulong virt)
{
    assert(false, "virtUnMap is unimplemented");
}

void switchPagemap(PageMap pagemap)
{
    ulong phys = cast(ulong) pagemap - hhdmOffset;
    kprintf("Switching to pagemap with phys=0x%.16llx", phys);
    asm
    {
        mov RAX, phys;
        mov CR3, RAX;
    }
}

void initVMM()
{
    kernelPagemap = cast(PageMap)(cast(ulong) physRequestPages(1, true));
    assert(kernelPagemap, "Failed to allocate kernel pagemap");
    memset(kernelPagemap, 0, PAGE_SIZE);

    kprintf("Kernel Pagemap is @ 0x%.16llx", cast(ulong) kernelPagemap);
    kprintf("Kernel Stack Top Address: 0x%.16llx", kernelStackTop);
    kprintf("Got kernel phys: 0x%.16llx, virt: 0x%.16llx", kernelAddrPhys, kernelAddrVirt);

    kprintf("Sections:");
    kprintf("  limine: start=0x%.16llx, end=0x%.16llx", cast(ulong)&limineStart, cast(ulong)&limineEnd);
    kprintf("  text  : start=0x%.16llx, end=0x%.16llx", cast(ulong)&textStart, cast(ulong)&textEnd);
    kprintf("  rodata: start=0x%.16llx, end=0x%.16llx", cast(ulong)&rodataStart, cast(ulong)&rodataEnd);
    kprintf("  data  : start=0x%.16llx, end=0x%.16llx", cast(ulong)&dataStart, cast(ulong)&dataEnd);

    for (ulong i = alignDown!ulong(cast(ulong)&limineStart, PAGE_SIZE); i < alignUp!ulong(
            cast(ulong)&limineEnd, PAGE_SIZE); i += PAGE_SIZE)
        virtMap(kernelPagemap, i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_WRITE);
    kprintf("Mapped limine section");

    kernelStackTop = alignUp!ulong(kernelStackTop, PAGE_SIZE);
    for (ulong i = kernelStackTop - 65536; i < kernelStackTop; i += PAGE_SIZE)
        virtMap(kernelPagemap, i, i - hhdmOffset, VMM_PRESENT | VMM_WRITE | VMM_NX);
    kprintf("Mapped kernel stack");

    for (ulong i = alignDown!ulong(cast(ulong)&textStart, PAGE_SIZE); i < alignUp!ulong(
            cast(ulong)&textEnd, PAGE_SIZE); i += PAGE_SIZE)
        virtMap(kernelPagemap, i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT);
    kprintf("Mapped text section");

    for (ulong i = alignDown!ulong(cast(ulong)&rodataStart, PAGE_SIZE); i < alignUp!ulong(
            cast(ulong)&rodataEnd, PAGE_SIZE); i += PAGE_SIZE)
        virtMap(kernelPagemap, i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_NX);
    kprintf("Mapped rodata section");

    for (ulong i = alignDown!ulong(cast(ulong)&dataStart, PAGE_SIZE); i < alignUp!ulong(
            cast(ulong)&dataEnd, PAGE_SIZE); i += PAGE_SIZE)
        virtMap(kernelPagemap, i, i - kernelAddrVirt + kernelAddrPhys, VMM_PRESENT | VMM_WRITE | VMM_NX);
    kprintf("Mapped data section");

    for (ulong i = 0; i < 0x100000000; i += PAGE_SIZE)
        virtMap(kernelPagemap, i + hhdmOffset, i, VMM_PRESENT | VMM_WRITE);
    kprintf("Mapped HHDM");

    switchPagemap(kernelPagemap);
}
