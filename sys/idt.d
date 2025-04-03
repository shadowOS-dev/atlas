module sys.idt;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 2, 2025
 */

import lib.log;
import sys.gdt;
import util.cpu;

// Defines
enum IDT_INTERRUPT_GATE = 0x8E;
enum IDT_TRAP_GATE = 0x8F;
enum IDT_IRQ_BASE = 0x20;

// Structs
struct IDTEntry
{
align(1):
    ushort offLow;
    ushort sel;
    ubyte ist;
    ubyte attr;
    ushort offMid;
    uint offHigh;
    uint zero;
}

struct IDTPointer
{
align(1):
    ushort limit;
    ulong base;
}

struct RegisterCtx
{
align(1):
    ulong es, ds;
    ulong cr4, cr3, cr2, cr0;
    ulong r15, r14, r13, r12, r11, r10, r9, r8, rsi, rdi, rbp, rdx, rcx, rbx, rax;
    ulong vector, err;
    ulong rip, cs, rflags, rsp, ss;
}

// Main
__gshared align(16) IDTEntry[256] idt = IDTEntry(0);
extern (C) alias IDTIntrHandler = void function(RegisterCtx* refs);
extern (C) __gshared IDTIntrHandler[256] realHandlers = void;
extern (C) extern __gshared ulong[256] stubs;
__gshared IDTPointer idtPtr = IDTPointer(0);

void setGate(int interrupt, ulong base, ubyte flags)
{
    if (interrupt >= idt.length)
    {
        kprintf("Invalid interrupt number: %d", interrupt);
        return;
    }

    idt[interrupt].offLow = (base) & 0xFFFF;
    idt[interrupt].sel = 0x8;
    idt[interrupt].ist = 0;
    idt[interrupt].attr = flags;
    idt[interrupt].offMid = ((base) >> 16) & 0xFFFF;
    idt[interrupt].offHigh = ((base) >> 32) & 0xFFFFFFFF;
    idt[interrupt].zero = 0;
}

void handleInterrupt(RegisterCtx* ctx)
{
    assert(null, "kernel panic");
}

void initIDT()
{
    idtPtr.limit = cast(ushort)((idt.length * IDTEntry.sizeof) - 1);
    kprintf("IDTPointer.limit: %d", idtPtr.limit);
    idtPtr.base = cast(ulong)(&idt);
    kprintf("IDTPointer.base: 0x%.16llx", idtPtr.base);
    kprintf("stubs base address: 0x%.16llx", cast(ulong)&stubs);

    foreach (i; 0 .. 32)
    {
        realHandlers[i] = cast(IDTIntrHandler)&handleInterrupt;
        setGate(i, cast(ulong) stubs[i], IDT_TRAP_GATE);
    }

    foreach (i; 32 .. 256)
    {
        setGate(i, stubs[i], IDT_INTERRUPT_GATE);
    }

    asm
    {
        lidt idtPtr;
    }
}
