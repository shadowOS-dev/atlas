/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

#include <stdint.h>
#include <stddef.h>
#include <mm/liballoc.h>

void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *pdest = (uint8_t *)dest;
    const uint8_t *psrc = (const uint8_t *)src;

    for (size_t i = 0; i < n; i++)
    {
        pdest[i] = psrc[i];
    }

    return dest;
}

void *memset(void *s, int c, size_t n)
{
    uint8_t *p = (uint8_t *)s;

    for (size_t i = 0; i < n; i++)
    {
        p[i] = (uint8_t)c;
    }

    return s;
}

void *memmove(void *dest, const void *src, size_t n)
{
    uint8_t *pdest = (uint8_t *)dest;
    const uint8_t *psrc = (const uint8_t *)src;

    if (src > dest)
    {
        for (size_t i = 0; i < n; i++)
        {
            pdest[i] = psrc[i];
        }
    }
    else if (src < dest)
    {
        for (size_t i = n; i > 0; i--)
        {
            pdest[i - 1] = psrc[i - 1];
        }
    }

    return dest;
}

int memcmp(const void *s1, const void *s2, size_t n)
{
    const uint8_t *p1 = (const uint8_t *)s1;
    const uint8_t *p2 = (const uint8_t *)s2;

    for (size_t i = 0; i < n; i++)
    {
        if (p1[i] != p2[i])
        {
            return p1[i] < p2[i] ? -1 : 1;
        }
    }

    return 0;
}

char *strdup(const char *s)
{
    size_t len = 0;

    while (s[len] != '\0')
    {
        len++;
    }

    char *copy = (char *)kmalloc(len + 1);
    if (!copy)
    {
        return NULL;
    }

    for (size_t i = 0; i < len; i++)
    {
        copy[i] = s[i];
    }

    copy[len] = '\0';
    return copy;
}

char *strstr(const char *haystack, const char *needle)
{
    if (*needle == '\0')
    {
        return (char *)haystack;
    }

    for (const char *h = haystack; *h != '\0'; h++)
    {
        const char *h_iter = h;
        const char *n_iter = needle;

        while (*h_iter == *n_iter && *n_iter != '\0')
        {
            h_iter++;
            n_iter++;
        }

        if (*n_iter == '\0')
        {
            return (char *)h;
        }
    }

    return NULL;
}

char *strncpy(char *dest, const char *src, size_t n)
{
    size_t i = 0;
    while (i < n && src[i] != '\0')
    {
        dest[i] = src[i];
        i++;
    }

    while (i < n)
    {
        dest[i] = '\0';
        i++;
    }

    return dest;
}

int strcmp(const char *str1, const char *str2)
{
    while (*str1 != '\0' && *str2 != '\0')
    {
        if (*str1 != *str2)
        {
            return (unsigned char)*str1 - (unsigned char)*str2;
        }
        str1++;
        str2++;
    }

    return (unsigned char)*str1 - (unsigned char)*str2;
}

size_t strlen(const char *s)
{
    size_t length = 0;
    while (s[length] != '\0')
    {
        length++;
    }
    return length;
}

long strtol(const char *nptr, char **endptr, int base)
{
    const char *s = nptr;
    long result = 0;
    int sign = 1;

    while (*s == ' ' || *s == '\t' || *s == '\n' ||
           *s == '\r' || *s == '\v' || *s == '\f')
    {
        s++;
    }

    if (*s == '-')
    {
        sign = -1;
        s++;
    }
    else if (*s == '+')
    {
        s++;
    }

    if ((base == 0 || base == 16) && s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
    {
        base = 16;
        s += 2;
    }
    else if (base == 0 && s[0] == '0')
    {
        base = 8;
        s++;
    }
    else if (base == 0)
    {
        base = 10;
    }

    while (1)
    {
        int digit;

        if (*s >= '0' && *s <= '9')
        {
            digit = *s - '0';
        }
        else if (*s >= 'a' && *s <= 'z')
        {
            digit = *s - 'a' + 10;
        }
        else if (*s >= 'A' && *s <= 'Z')
        {
            digit = *s - 'A' + 10;
        }
        else
        {
            break;
        }

        if (digit >= base)
        {
            break;
        }

        result = result * base + digit;
        s++;
    }

    if (endptr != NULL)
    {
        *endptr = (char *)(*s ? s : nptr);
    }

    return sign * result;
}

int strncmp(const char *s1, const char *s2, size_t n)
{
    for (size_t i = 0; i < n; i++)
    {
        if (s1[i] != s2[i])
        {
            return (unsigned char)s1[i] - (unsigned char)s2[i];
        }

        if (s1[i] == '\0')
        {
            return 0;
        }
    }

    return 0;
}
