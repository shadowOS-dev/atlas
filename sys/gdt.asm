;
; Atlas Kernel - ShadowOS
;
; License: Apache 2.0
; Author: Kevin Alavik <kevin@alavik.se>
; Date: April 2, 2025
;

section .text
global flushGDT
flushGDT:
    lgdt [rdi]
    push 0x08
    lea rax, [rel .r]
    push rax
    retfq
.r:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret