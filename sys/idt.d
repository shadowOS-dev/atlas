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
import lib.printf;
import core.vararg;
import dev.stdout;

/* Defines */
enum IDT_INTERRUPT_GATE = 0x8E;

enum IDT_TRAP_GATE = 0x8F;
enum IDT_IRQ_BASE = 0x20;

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

/* Globals */
__gshared align(16) IDTEntry[256] idt = IDTEntry(0);
extern (C) alias IDTIntrHandler = void function(RegisterCtx* refs);
extern (C) __gshared IDTIntrHandler[256] realHandlers = void;
extern (C) extern __gshared ulong[256] stubs;
__gshared IDTPointer idtPtr = IDTPointer(0);

__gshared immutable char*[32] exceptionMessages = [
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

__gshared bool panicking = false;

/* Generic */
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

extern (C) void __assert(const(char)* msg, const(char)* file, uint line)
{
    kpanic(null, "%s:%d: Assertion failed: \"%s\"\n", file, line, msg);
}

extern (C) void kpanic(RegisterCtx* ctx, const char* fmt, ...)
{
    if (panicking)
    {
        hcf(); // prevent panic during panic
    }

    panicking = true;
    printf("\x1b[48;5;33m\x1b[97m\x1b[1m");
    printf("\x1b[?25l\x1b[2J\x1b[H");

    printf("**** ATLAS KERNEL PANIC ****\n\n");

    if (fmt)
    {
        va_list args;
        va_start(args, fmt);
        vprintf(fmt, args);
        va_end(args);
        printf("\n");
    }
    printf(
        "\nA critical and unrecoverable error has occurred within the Atlas Kernel, which has caused the system to enter an unstable state.\n");
    printf(
        "This error is severe and has resulted in the inability of the system to continue functioning properly.\n");
    printf("As a result, the system is no longer able to operate safely, and a restart is required to recover from this failure.\n\n");

    printf(
        "If this issue persists after restarting, or if you require further assistance to diagnose or resolve the problem,\n");
    printf("please do not hesitate to reach out to the following contact for support:\n");
    printf("\n");
    printf("   Name: Kevin Alavik\n");
    printf("   Email: kevin@alavik.se\n");
    printf(
        "   Please provide any relevant details or error logs when contacting for quicker resolution.\n\n");

    if (ctx)
    {
        printf("Register dump (for debugging purposes):\n");
        printf("  RAX: %.16llx  RBX:    %.16llx  RCX: %.16llx  RDX: %.16llx\n", ctx.rax, ctx.rbx, ctx.rcx, ctx
                .rdx);
        printf("  RSI: %.16llx  RDI:    %.16llx  RBP: %.16llx  R8:  %.16llx\n", ctx.rsi, ctx.rdi, ctx.rbp, ctx
                .r8);
        printf("  R9:  %.16llx  R10:    %.16llx  R11: %.16llx  R12: %.16llx\n", ctx.r9, ctx.r10, ctx.r11, ctx
                .r12);
        printf("  R13: %.16llx  R14:    %.16llx  R15: %.16llx\n", ctx.r13, ctx.r14, ctx.r15);
        printf("  RIP: %.16llx  RFLAGS: %.16llx  RSP: %.16llx  SS:  %.16llx\n", ctx.rip, ctx.rflags, ctx.rsp, ctx
                .ss);
        printf("  CR0: %.16llx  CR2:    %.16llx  CR3: %.16llx  CR4: %.16llx\n", ctx.cr0, ctx.cr2, ctx.cr3, ctx
                .cr4);
        printf("  ES:  %.16llx  DS:     %.16llx\n", ctx.es, ctx.ds);
    }

    printf(
        "\nThe system has encountered a fatal error. Please restart your machine.\n");
    printf("If this issue persists, we request a detailed bug report for further investigation.\n");
    printf("\x1b[?25h");
    panicking = false;
    hcf();
}

void handleInterrupt(RegisterCtx* ctx)
{
    kpanic(ctx, "Exception caught: %s".ptr, exceptionMessages[ctx.vector]);
    hcf();
}

void idtInit()
{
    idtPtr.limit = cast(ushort)((idt.length * IDTEntry.sizeof) - 1);
    idtPtr.base = cast(ulong)(&idt);

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
