#include <posix/string.h>
#include <stdint.h>

void *memcpy(void *dest, const void *src, size_t n) {
    uint8_t *dest_ptr = (uint8_t *) dest;
    const uint8_t *src_ptr = (const uint8_t *) src;

    for (size_t i = 0; i < n; i++) {
        dest_ptr[i] = src_ptr[i];
    }

    return dest;
}

void *memset(void *s, int c, size_t n) {
    uint8_t *ptr = (uint8_t *) s;

    for (size_t i = 0; i < n; i++) {
        ptr[i] = (uint8_t) c;
    }

    return s;
}

void *memmove(void *dest, const void *src, size_t n) {
    uint8_t *dest_ptr = (uint8_t *) dest;
    const uint8_t *src_ptr = (const uint8_t *) src;

    if (src > dest) {
        for (size_t i = 0; i < n; i++) {
            dest_ptr[i] = src_ptr[i];
        }
    } else if (src < dest) {
        for (size_t i = n; i > 0; i--) {
            dest_ptr[i - 1] = src_ptr[i - 1];
        }
    }

    return dest;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const uint8_t *ptr1 = (const uint8_t *) s1;
    const uint8_t *ptr2 = (const uint8_t *) s2;

    for (size_t i = 0; i < n; i++) {
        if (ptr1[i] != ptr2[i]) {
            return ptr1[i] < ptr2[i] ? -1 : 1;
        }
    }

    return 0;
}
