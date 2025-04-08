module util.string;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

import mm.kmalloc;

extern (C) void* memcpy(void* dest, const(void)* src, size_t n);
extern (C) void* memset(void* s, int c, size_t n);
extern (C) void* memmove(void* dest, const(void)* src, size_t n);
extern (C) int memcmp(const(void)* s1, const(void)* s2, size_t n);
extern (C) char* strdup(const(char)* s);
extern (C) char* strstr(const(char)* haystack, const(char)* needle);
extern (C) char* strncpy(char* dest, const(char)* src, size_t n);
extern (C) int strcmp(const(char)* str1, const(char)* str2);
extern (C) size_t strlen(const(char)* s);
extern (C) long strtol(const(char)* nptr, char** endptr, int base);
extern (C) int strncmp(const(char)* s1, const(char)* s2, size_t n);

bool isInString(const(char)* haystack, const(char)* needle)
{
    if (needle is null || haystack is null || needle[0] == '\0')
    {
        return true;
    }

    int needleLength = 0;
    while (needle[needleLength] != '\0')
    {
        needleLength++;
    }

    int i = 0;
    while (haystack[i] != '\0')
    {
        bool match = true;

        for (int j = 0; j < needleLength; j++)
        {
            if (haystack[i + j] != needle[j])
            {
                match = false;
                break;
            }
        }

        if (match)
        {
            if (haystack[i + needleLength] == ' ' || haystack[i + needleLength] == '\0')
            {
                return true;
            }
        }

        i++;
    }

    return false;
}

char** stringSplit(const(char)* str, char delimiter)
{
    if (str is null)
        return null;

    size_t count = 1;
    for (size_t i = 0; str[i] != '\0'; i++)
    {
        if (str[i] == delimiter)
            count++;
    }

    auto result = cast(char**) kmalloc((count + 1) * (char*).sizeof);
    if (!result)
        return null;

    size_t tokenStart = 0;
    size_t tokenIndex = 0;
    size_t length = strlen(str);

    for (size_t i = 0; i <= length; i++)
    {
        if (str[i] == delimiter || str[i] == '\0')
        {
            size_t tokenLen = i - tokenStart;
            auto token = cast(char*) kmalloc(tokenLen + 1);
            if (!token)
                return null;

            for (size_t j = 0; j < tokenLen; j++)
                token[j] = str[tokenStart + j];

            token[tokenLen] = '\0';
            result[tokenIndex++] = token;
            tokenStart = i + 1;
        }
    }

    result[tokenIndex] = null;
    return result;
}

void freeStringSplit(char** tokens)
{
    if (!tokens)
        return;

    for (size_t i = 0; tokens[i]!is null; i++)
    {
        kfree(tokens[i]);
    }

    kfree(tokens);
}

size_t tokensLength(char** tokens)
{
    size_t len = 0;
    while (tokens[len]!is null)
        len++;
    return len;
}
