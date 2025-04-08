module mm.pmm;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 3, 2025
 */

import lib.log;
import init.entry;
import init.limine;
import util.bitmap;
import lib.math;
import util.string;

/* Globals */
__gshared MemmapResponse* memmap;
__gshared ubyte[] physBitmap;
__gshared ulong physBitmapPages;
__gshared ulong physBitmapSize;
__gshared ulong hhdmOffset;

/* Main logic */
void pmmInit()
{
    memmap = memmapReq.response;
    hhdmOffset = hhdmReq.response.offset;
    ulong top = 0;
    ulong high = 0;

    foreach (i; 0 .. memmap.entryCount)
    {
        MemmapEntry* entry = memmap.entries[i];
        if (entry.type == MemoryMapUsable)
        {
            ulong entryTop = entry.base + entry.length;
            if (entryTop > high)
                high = entryTop;
            kprintf("Usable entry @ 0x%.16llx, top: 0x%.16llx, high: 0x%.16llx", entry.base, entryTop, high);
        }
    }

    physBitmapPages = high / PAGE_SIZE;
    physBitmapSize = alignUp!ulong(physBitmapPages / 8, PAGE_SIZE);
    kprintf("HHDM Offset: 0x%.16llx", hhdmOffset);
    kprintf("Bitmap Pages: %d", physBitmapPages);
    kprintf("Bitmap Size: %d", physBitmapSize);

    foreach (i; 0 .. memmap.entryCount)
    {
        MemmapEntry* entry = memmap.entries[i];
        if (entry.type == MemoryMapUsable && entry.length >= physBitmapSize)
        {
            ubyte* bitmapPtr = cast(ubyte*) entry.base + hhdmOffset;
            physBitmap = bitmapPtr[0 .. physBitmapSize];
            memset(cast(void*) physBitmap, 0xFF, physBitmapSize);
            entry.base += physBitmapSize;
            entry.length -= physBitmapSize;
            break;
        }
    }

    foreach (i; 0 .. memmap.entryCount)
    {
        MemmapEntry* entry = memmap.entries[i];
        if (entry.type == MemoryMapUsable)
        {
            for (ulong j = entry.base; j < entry.base + entry.length; j += PAGE_SIZE)
            {
                if (j / PAGE_SIZE < physBitmapPages)
                {
                    bitmapClear(physBitmap, (j / PAGE_SIZE));
                }
            }
        }
    }
}

void* physRequestPages(size_t pages, bool higherHalf)
{
    ulong lastIdx = 0;

    while (lastIdx < physBitmapPages)
    {
        size_t consecutiveFreePages = 0;

        foreach (i; 0 .. pages)
        {
            if (lastIdx + i >= physBitmapPages)
            {
                return null;
            }

            if (!bitmapGet(physBitmap, lastIdx + i))
            {
                consecutiveFreePages++;
            }
            else
            {
                consecutiveFreePages = 0;
                break;
            }
        }

        if (consecutiveFreePages == pages)
        {
            foreach (i; 0 .. pages)
            {
                bitmapSet(physBitmap, lastIdx + i);
            }

            if (higherHalf)
            {
                return cast(void*)((hhdmOffset + (lastIdx * PAGE_SIZE)));
            }
            else
            {
                return cast(void*)(lastIdx * PAGE_SIZE);
            }
        }

        lastIdx++;
    }

    return null;
}

void physReleasePages(void* ptr, size_t pages)
{
    ulong start = ((cast(ulong) ptr) / PAGE_SIZE);
    for (uint i = 0; i < pages; ++i)
    {
        if ((start + i) < physBitmapPages)
        {
            bitmapClear(physBitmap, start + i);
        }
    }
}

/* Utilities */
enum MemoryStatus
{
    Critical,
    Low,
    OK
}

MemoryStatus checkMemoryStatus(ulong freeMemoryMiB)
{
    if (freeMemoryMiB < 32)
    {
        kprintf("\033[91mInsufficient memory: Only %d MiB available. System performance may be severely impacted.\033[0m\n", freeMemoryMiB);
        return MemoryStatus.Critical;
    }
    else if (freeMemoryMiB < 64)
    {
        kprintf("\033[93mLow available memory: %d MiB remaining. Consider upgrading hardware.\033[0m\n", freeMemoryMiB);
        return MemoryStatus.Low;
    }
    else
    {
        kprintf(
            "\033[92mSufficient memory: %d MiB available. System operating running smoooooth.\033[0m\n", freeMemoryMiB);
        return MemoryStatus.OK;
    }
}

ulong physGetFreeMemory()
{
    ulong freePages = 0;

    foreach (i; 0 .. physBitmapPages)
    {
        if (!bitmapGet(physBitmap, i))
        {
            freePages++;
        }
    }

    return freePages * PAGE_SIZE;
}

string memoryTypeToString(ulong type)
{
    switch (type)
    {
    case MemoryMapUsable:
        return "Usable";
    case MemoryMapReserved:
        return "Reserved";
    case MemoryMapACPIReclaimable:
        return "ACPI Reclaimable";
    case MemoryMapACPINVS:
        return "ACPI NVS";
    case MemoryMapBadMemory:
        return "Bad Memory";
    case MemoryMapBootloaderReclaimable:
        return "Bootloader Reclaimable";
    case MemoryMapKernelAndModules:
        return "Kernel and Modules";
    case MemoryMapFramebuffer:
        return "Framebuffer";
    default:
        return "Unknown";
    }
}
