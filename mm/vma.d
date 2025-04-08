module mm.vma;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 6, 2025
 */

import mm.vmm;
import mm.pmm;
import lib.log;
import util.string;
import init.entry;

// Note: All sizes are in pages

struct VMARegion
{
align(1):
    ulong start;
    ulong size;
    ulong flags;
    VMARegion* next;
    VMARegion* prev;
}

struct VMAContext
{
align(1):
    VMARegion* root;
    PageMap pagemap;
}

VMAContext* vmaCreateContext(PageMap pagemap)
{
    VMAContext* ctx = cast(VMAContext*) physRequestPages(1, true);
    assert(ctx, "Failed to allocate memory for VMA context");
    memset(ctx, 0, PAGE_SIZE);
    ctx.root = cast(VMARegion*) physRequestPages(1, true);
    memset(ctx.root, 0, PAGE_SIZE);
    assert(ctx.root, "Failed to allocate memory for VMA root");
    ctx.pagemap = pagemap;
    ctx.root.start = PAGE_SIZE;
    ctx.root.size = 0;
    return ctx;
}

void* vmaAllocPages(VMAContext* ctx, size_t pages, ulong flags)
{
    assert(ctx, "Invalid VMA context passed");
    assert(ctx.root, "Invalid VMA context passed");
    assert(ctx.pagemap.table, "Invalid VMA context passed");

    VMARegion* region = ctx.root;
    VMARegion* prevRegion = null;

    while (region != null)
    {
        kprintf("current vma region starts at 0x%.16llx", region.start);
        if (region.next == null || region.start + (region.size * PAGE_SIZE) < region.next.start)
        {
            VMARegion* newRegion = cast(VMARegion*) physRequestPages(1, true);
            assert(newRegion, "Failed to allocate memory for new VMA region");
            memset(newRegion, 0, VMARegion.sizeof);
            newRegion.size = pages;
            newRegion.flags = flags;
            newRegion.start = region.start + (region.size * PAGE_SIZE);
            newRegion.prev = region;
            newRegion.next = region.next;

            region.next = newRegion;
            if (newRegion.next != null)
                newRegion.next.prev = newRegion;

            foreach (i; 0 .. pages)
            {
                ulong page = cast(ulong) physRequestPages(1, false);
                assert(page != 0, "Failed to allocate physical memory for VMA region");
                memset(cast(void*)(page + hhdmOffset), 0, PAGE_SIZE);
                ctx.pagemap.map(newRegion.start + (i * PAGE_SIZE), page, newRegion
                        .flags);
            }

            return cast(void*) newRegion.start;
        }

        prevRegion = region;
        region = region.next;
    }

    VMARegion* newEndRegion = cast(VMARegion*) physRequestPages(1, true);
    assert(newEndRegion, "Failed to allocate memory for new VMA region");
    memset(newEndRegion, 0, VMARegion.sizeof);

    prevRegion.next = newEndRegion;
    newEndRegion.prev = prevRegion;
    newEndRegion.start = prevRegion.start + (prevRegion.size * PAGE_SIZE);
    newEndRegion.size = pages;
    newEndRegion.flags = flags;
    newEndRegion.next = null;

    foreach (i; 0 .. pages)
    {
        ulong page = cast(ulong) physRequestPages(1, false);
        assert(page != 0, "Failed to allocate physical memory for VMA region");
        memset(cast(void*)(page + hhdmOffset), 0, PAGE_SIZE);
        ctx.pagemap.map(newEndRegion.start + (i * PAGE_SIZE), page, newEndRegion.flags);
    }
    return cast(void*) newEndRegion.start;
}

void vmaFreePages(VMAContext* ctx, void* ptr)
{
    assert(ctx, "Invalid VMA context passed");
    assert(ctx.root, "Invalid VMA context passed");
    assert(ctx.pagemap.table, "Invalid VMA context passed");
    assert(ptr, "Invalid pointer passed");

    VMARegion* region = ctx.root;
    while (region != null)
    {
        if (region.start == cast(ulong) ptr)
        {
            break;
        }
        region = region.next;
    }

    if (region == null)
    {
        kprintf("Unable to find region to free");
        return;
    }

    VMARegion* prev = region.prev;
    VMARegion* next = region.next;
    foreach (i; 0 .. region.size)
    {
        ulong virt = region.start + i * PAGE_SIZE;
        ulong phys = ctx.pagemap.virtToPhys(virt);

        if (phys != 0)
        {
            physReleasePages(cast(void*) phys, 1);
            ctx.pagemap.unmap(virt);
        }
    }

    if (prev != null)
    {
        prev.next = next;
    }

    if (next != null)
    {
        next.prev = prev;
    }

    if (region == ctx.root)
    {
        ctx.root = next;
    }

    physReleasePages(region - hhdmOffset, 1);
}
