#include <stdint.h>

typedef struct Spinlock
{
    volatile int locked;
} Spinlock;

void spinlockInit(Spinlock *lock)
{
    lock->locked = 0;
}

void spinlockAcquire(Spinlock *lock)
{
    while (__sync_lock_test_and_set(&lock->locked, 1))
    {
        while (lock->locked)
        {
            __asm__ volatile("pause");
        }
    }
}

void spinlockRelease(Spinlock *lock)
{
    __sync_lock_release(&lock->locked);
}
