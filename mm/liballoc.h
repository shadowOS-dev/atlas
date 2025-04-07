// Copyright: Durand Miller <clutter@djm.co.za>
#ifndef LIBALLOC_H
#define LIBALLOC_H

#define _DEBUG 1

#include <stddef.h>
#include <stdint.h>

extern void la_trace(const char *, ...);
extern void la_error(const char *, ...);
extern void la_info(const char *, ...);

#define PREFIX(func) k##func

#ifdef _DEBUG
void liballoc_dump();
#endif // _DEBUG

extern int liballoc_lock();
extern int liballoc_unlock();
extern void *liballoc_alloc(size_t);
extern int liballoc_free(void *, size_t);

extern void *PREFIX(malloc)(size_t);
extern void *PREFIX(realloc)(void *, size_t);
extern void *PREFIX(calloc)(size_t, size_t);
extern void PREFIX(free)(void *);

#endif // LIBALLOC_H