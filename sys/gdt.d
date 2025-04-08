module sys.gdt;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 2, 2025
 */

import lib.log;

// GDT Access Flags
enum GDT_ACCESS_PRESENT = 0x80; // Segment is present
enum GDT_ACCESS_RING0 = 0x00; // Privilege Level 0 (Kernel)
enum GDT_ACCESS_RING3 = 0x60; // Privilege Level 3 (User)
enum GDT_ACCESS_SYSTEM = 0x00; // System segment (e.g., TSS)
enum GDT_ACCESS_CODE = 0x18; // Code segment (Executable)
enum GDT_ACCESS_DATA = 0x10; // Data segment (Readable/Writable)
enum GDT_ACCESS_DIRECTION = 0x04; // Direction bit (0 = Grows up, 1 = Grows down)
enum GDT_ACCESS_EXECUTABLE = 0x08; // Executable segment
enum GDT_ACCESS_RW = 0x02; // Readable for code, Writable for data
enum GDT_ACCESS_ACCESSED = 0x01; // CPU sets this when accessed

// Common Access Flags
enum GDT_KERNEL_CODE = GDT_ACCESS_PRESENT | GDT_ACCESS_RING0 | GDT_ACCESS_CODE | GDT_ACCESS_EXECUTABLE | GDT_ACCESS_RW;
enum GDT_KERNEL_DATA = GDT_ACCESS_PRESENT | GDT_ACCESS_RING0 | GDT_ACCESS_DATA | GDT_ACCESS_RW;
enum GDT_USER_CODE = GDT_ACCESS_PRESENT | GDT_ACCESS_RING3 | GDT_ACCESS_CODE | GDT_ACCESS_EXECUTABLE | GDT_ACCESS_RW;
enum GDT_USER_DATA = GDT_ACCESS_PRESENT | GDT_ACCESS_RING3 | GDT_ACCESS_DATA | GDT_ACCESS_RW;
enum GDT_TSS = 0xE9;

// Granularity Flags
enum GDT_GRANULARITY_4K = 0x80;
enum GDT_GRANULARITY_32B = 0x40;
enum GDT_GRANULARITY_LONG_MODE = 0x20;
enum GDT_GRANULARITY_FLAT = GDT_GRANULARITY_4K | GDT_GRANULARITY_LONG_MODE;

// GDT Structs
struct GDTEntry
{
align(1):
    ushort limitLow;
    ushort baseLow;
    ubyte baseMiddle;
    ubyte access;
    ubyte granularity;
    ubyte baseHigh;
}

struct GDTPointer
{
align(1):
    ushort limit;
    ulong base;
}

// Globals
__gshared GDTEntry[5] gdt = GDTEntry(0);
__gshared GDTPointer gdtPtr = GDTPointer(0);

extern (C) void flushGDT(GDTPointer* ptr);
void gdtInit()
{
    gdt[0] = GDTEntry(0, 0, 0, 0x00, 0x00, 0); // Null segment
    gdt[1] = GDTEntry(0, 0, 0, GDT_KERNEL_CODE, GDT_GRANULARITY_FLAT, 0); // Kernel code segment
    gdt[2] = GDTEntry(0, 0, 0, GDT_KERNEL_DATA, GDT_GRANULARITY_FLAT, 0); // Kernel data segment
    gdt[3] = GDTEntry(0, 0, 0, GDT_USER_CODE, GDT_GRANULARITY_FLAT, 0); // User code segment
    gdt[4] = GDTEntry(0, 0, 0, GDT_USER_DATA, 0x00, 0); // User data segment

    gdtPtr.limit = cast(ushort)((gdt.length * GDTEntry.sizeof) - 1);
    gdtPtr.base = cast(ulong)(&gdt);

    flushGDT(&gdtPtr);
}
