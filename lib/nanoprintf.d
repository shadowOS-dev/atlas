module lib.nanoprintf;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import core.stdc.stdarg;
import util.string;

extern (C):
int npf_snprintf(char* buffer, size_t bufsz, const(char)* format, ...);
int npf_vsnprintf(char* buffer, size_t bufsz, const(char)* format, va_list vlist);
alias npf_putc = void function(int c, void* ctx);
int npf_pprintf(npf_putc pc, void* pc_ctx, const(char)* format, ...);
int npf_vpprintf(npf_putc pc, void* pc_ctx, const(char)* format, va_list vlist);
