#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <limine.h>

__attribute__((used, section(".limine_requests"))) static volatile LIMINE_BASE_REVISION(3);
__attribute__((used, section(".limine_requests"))) static volatile struct limine_framebuffer_request framebuffer_req = {
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0};
__attribute__((used, section(".limine_requests_start"))) static volatile LIMINE_REQUESTS_START_MARKER;
__attribute__((used, section(".limine_requests_end"))) static volatile LIMINE_REQUESTS_END_MARKER;

void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *dest_ptr = (uint8_t *)dest;
    const uint8_t *src_ptr = (const uint8_t *)src;

    for (size_t i = 0; i < n; i++)
    {
        dest_ptr[i] = src_ptr[i];
    }

    return dest;
}

void *memset(void *s, int c, size_t n)
{
    uint8_t *ptr = (uint8_t *)s;

    for (size_t i = 0; i < n; i++)
    {
        ptr[i] = (uint8_t)c;
    }

    return s;
}

void *memmove(void *dest, const void *src, size_t n)
{
    uint8_t *dest_ptr = (uint8_t *)dest;
    const uint8_t *src_ptr = (const uint8_t *)src;

    if (src > dest)
    {
        for (size_t i = 0; i < n; i++)
        {
            dest_ptr[i] = src_ptr[i];
        }
    }
    else if (src < dest)
    {
        for (size_t i = n; i > 0; i--)
        {
            dest_ptr[i - 1] = src_ptr[i - 1];
        }
    }

    return dest;
}

int memcmp(const void *s1, const void *s2, size_t n)
{
    const uint8_t *ptr1 = (const uint8_t *)s1;
    const uint8_t *ptr2 = (const uint8_t *)s2;

    for (size_t i = 0; i < n; i++)
    {
        if (ptr1[i] != ptr2[i])
        {
            return ptr1[i] < ptr2[i] ? -1 : 1;
        }
    }

    return 0;
}

static void system_halt(void)
{
    for (;;)
    {
        asm("hlt");
    }
}

void _start(void)
{
    if (LIMINE_BASE_REVISION_SUPPORTED == false)
    {
        system_halt();
    }

    if (framebuffer_req.response == NULL || framebuffer_req.response->framebuffer_count < 1)
    {
        system_halt();
    }

    struct limine_framebuffer *framebuffer = framebuffer_req.response->framebuffers[0];
    for (size_t i = 0; i < 100; i++)
    {
        ((uint32_t *)framebuffer->address)[i * (framebuffer->pitch / 4) + i] = 0xffffff;
    }

    system_halt();
}
