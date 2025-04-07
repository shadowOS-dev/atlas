module lib.lock;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: April 6, 2025
 */

extern (C) extern void spinlockAcquire(Spinlock* lock);
extern (C) extern void spinlockRelease(Spinlock* lock);
extern (C) extern void spinlockInit(Spinlock* lock);

struct Spinlock
{
    shared int locked = 0;

    void lock()
    {
        spinlockAcquire(&this);
    }

    void unlock()
    {
        spinlockRelease(&this);
    }
}
