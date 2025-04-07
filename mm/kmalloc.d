module mm.kmalloc;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 6, 2025
 */

extern (C):
extern void* kmalloc(size_t size);
extern void* krealloc(void* ptr, size_t size);
extern void* kcalloc(size_t num, size_t size);
extern void kfree(void* ptr);
