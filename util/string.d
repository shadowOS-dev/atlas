module util.string;

/*
 * Atlas Kernel - ShadowOS
 *
 * License: Apache 2.0
 * Author: Kevin Alavik <kevin@alavik.se>
 * Date: March 31, 2025
 */

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
