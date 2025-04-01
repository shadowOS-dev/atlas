module lib.flanterm;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 32, 2025
 */

// Flanterm copyright notice, at the bottom.
extern (C):

enum FLANTERM_H = 1;

enum FLANTERM_CB_DEC = 10;
enum FLANTERM_CB_BELL = 20;
enum FLANTERM_CB_PRIVATE_ID = 30;
enum FLANTERM_CB_STATUS_REPORT = 40;
enum FLANTERM_CB_POS_REPORT = 50;
enum FLANTERM_CB_KBD_LEDS = 60;
enum FLANTERM_CB_MODE = 70;
enum FLANTERM_CB_LINUX = 80;

enum FLANTERM_OOB_OUTPUT_OCRNL = 1 << 0;
enum FLANTERM_OOB_OUTPUT_OFDEL = 1 << 1;
enum FLANTERM_OOB_OUTPUT_OFILL = 1 << 2;
enum FLANTERM_OOB_OUTPUT_OLCUC = 1 << 3;
enum FLANTERM_OOB_OUTPUT_ONLCR = 1 << 4;
enum FLANTERM_OOB_OUTPUT_ONLRET = 1 << 5;
enum FLANTERM_OOB_OUTPUT_ONOCR = 1 << 6;
enum FLANTERM_OOB_OUTPUT_OPOST = 1 << 7;

struct flanterm_context;

flanterm_context* flanterm_fb_init(
    void* function(size_t size) _malloc,
    void function(void* ptr, size_t size) _free,
    uint* framebuffer,
    size_t width,
    size_t height,
    size_t pitch,
    ubyte redMaskSize,
    ubyte redMaskShift,
    ubyte greenMaskSize,
    ubyte greenMaskShift,
    ubyte blueMaskSize,
    ubyte blueMaskShift,
    uint* canvas,
    uint* ansiColours,
    uint* ansiBrightColours,
    uint* defaultBg,
    uint* defaultFg,
    uint* defaultBgBright,
    uint* defaultFgBright,
    void* font,
    size_t fontWidth,
    size_t fontHeight,
    size_t fontSpacing,
    size_t fontScaleX,
    size_t fontScaleY,
    size_t margin);

void flanterm_write(flanterm_context* ctx, const(char)* buf, size_t count);
void flanterm_flush(flanterm_context* ctx);
void flanterm_full_refresh(flanterm_context* ctx);
void flanterm_deinit(flanterm_context* ctx, void function(void* ptr, size_t size) _free);

void flanterm_get_dimensions(flanterm_context* ctx, size_t* cols, size_t* rows);
void flanterm_set_autoflush(flanterm_context* ctx, bool state);
void flanterm_set_callback(flanterm_context* ctx, void function(flanterm_context*, ulong, ulong, ulong, ulong) callback);
ulong flanterm_get_oob_output(flanterm_context* ctx);
void flanterm_set_oob_output(flanterm_context* ctx, ulong oob_output);

/* Copyright (C) 2022-2025 mintsuki and contributors.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
