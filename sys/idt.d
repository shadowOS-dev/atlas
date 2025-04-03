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

__gshared immutable string[32] exceptionMessages = [
    "Division by Zero",
    "Debug",
    "Non-Maskable-Interrupt",
    "Breakpoint",
    "Overflow",
    "Bound Range Exceeded",
    "Invalid opcode",
    "Device (FPU) not available",
    "Double Fault",
    "RESERVED VECTOR",
    "Invalid TSS",
    "Segment not present",
    "Stack Segment Fault",
    "General Protection Fault",
    "Page Fault",
    "RESERVED VECTOR",
    "x87 FP Exception",
    "Alignment Check",
    "Machine Check (Internal Error)",
    "SIMD FP Exception",
    "Virtualization Exception",
    "Control Protection Exception",
    "RESERVED VECTOR",
    "RESERVED VECTOR",
    "RESERVED VECTOR",
    "RESERVED VECTOR",
    "RESERVED VECTOR",
    "RESERVED VECTOR",
    "Hypervisor Injection Exception",
    "VMM Communication Exception",
    "Security Exception",
    "RESERVED VECTOR"
];

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

void _renderRegister(const char* label, ulong value)
{
    kprintf("\t%-8.3s: 0x%.16lx", label, value);
}

void handleInterrupt(RegisterCtx* ctx)
{
    kprintf("\x1b[31m%s at 0x%.16llx\x1b[0m", exceptionMessages[ctx.vector].ptr, ctx.rip);

    _renderRegister("rip", ctx.rip);
    _renderRegister("cs", ctx.cs);
    _renderRegister("rflags", ctx.rflags);
    _renderRegister("rsp", ctx.rsp);
    kprintf("--------------------------------");

    _renderRegister("ss", ctx.ss);
    _renderRegister("rax", ctx.rax);
    _renderRegister("rbx", ctx.rbx);
    _renderRegister("rcx", ctx.rcx);
    kprintf("--------------------------------");

    _renderRegister("rdx", ctx.rdx);
    _renderRegister("rbp", ctx.rbp);
    _renderRegister("rdi", ctx.rdi);
    _renderRegister("rsi", ctx.rsi);
    kprintf("--------------------------------");

    _renderRegister("r8", ctx.r8);
    _renderRegister("r9", ctx.r9);
    _renderRegister("r10", ctx.r10);
    _renderRegister("r11", ctx.r11);
    kprintf("--------------------------------");

    _renderRegister("r12", ctx.r12);
    _renderRegister("r13", ctx.r13);
    _renderRegister("r14", ctx.r14);
    _renderRegister("r15", ctx.r15);
    kprintf("--------------------------------");

    _renderRegister("cr0", ctx.cr0);
    _renderRegister("cr2", ctx.cr2);
    _renderRegister("cr3", ctx.cr3);
    _renderRegister("cr4", ctx.cr4);
    kprintf("--------------------------------");

    _renderRegister("es", ctx.es);
    _renderRegister("ds", ctx.ds);
    kprintf("--------------------------------");

    hcf();
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
