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

__gshared MemmapResponse* memmap;
__gshared ubyte[] bitmap;
__gshared ulong bitmapPages;
__gshared ulong bitmapSize;
__gshared ulong hhdmOffset;
void initPMM()
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

    bitmapPages = high / PAGE_SIZE;
    bitmapSize = alignUp!ulong(bitmapPages / 8, PAGE_SIZE);
    kprintf("HHDM Offset: 0x%.16llx", hhdmOffset);
    kprintf("Bitmap Pages: %d", bitmapPages);
    kprintf("Bitmap Size: %d", bitmapSize);

    foreach (i; 0 .. memmap.entryCount)
    {
        MemmapEntry* entry = memmap.entries[i];
        if (entry.type == MemoryMapUsable && entry.length >= bitmapSize)
        {
            ubyte* bitmapPtr = cast(ubyte*) entry.base + hhdmOffset;
            bitmap = bitmapPtr[0 .. bitmapSize];
            memset(cast(void*) bitmap, 0xFF, bitmapSize);
            entry.base += bitmapSize;
            entry.length -= bitmapSize;
            kprintf("Bitmap -> 0x%.16llx", cast(ulong)&bitmap);
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
                bitmapClear(bitmap, (j / PAGE_SIZE));
            }
        }
    }
}

void* pmm_request_pages(size_t pages, bool higherHalf)
{
    ulong lastIdx = 0;

    while (lastIdx < bitmapPages)
    {
        size_t consecutiveFreePages = 0;

        foreach (i; 0 .. pages)
        {
            if (!bitmapGet(bitmap, lastIdx + i))
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
                bitmapSet(bitmap, lastIdx + i);
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

void pmm_release_pages(void* ptr, size_t pages)
{

    ulong start = ((cast(ulong) ptr) / PAGE_SIZE);
    for (uint i = 0; i < pages; ++i)
    {
        bitmapClear(bitmap, start + i);
    }
}
