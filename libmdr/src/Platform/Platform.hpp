#pragma once
#include <cstdint>
#include <cstdio>
#include <cstring>

/**
 * @brief Converts UUID string to byte array
 * @param szSrc Zero-terminated UUID string e.g. 956C7B26-D49A-4BA8-B03F-B17D393CB6E2
 * @param dst 16-byte buffer to store the UUID in bytes
 *            Expect 0x95, 0x6C, 0x7B, 0x26, 0xD4, 0x9A, 0x4B, 0xA8, 0xB0, 0x3F, 0xB1, 0x7D, 0x39, 0x3C, 0xB6, 0xE2 for the example.
 * @return 0 on success, -1 on failure.
 */
inline int serviceUUIDtoBytes(const char* szSrc, uint8_t* dst)
{
    if (strlen(szSrc) != 36)
        return -1;
    unsigned int u[5];
    unsigned long long u6;
    // Example: 956C7B26-D49A-4BA8-B03F-B17D393CB6E2
    //          01234567 8 9ABC D E FGH I JKLMN OPQRSTUV
    // Hyphens at 8, 13, 18, 23
    int ret = sscanf(szSrc, "%8x-%4x-%4x-%4x-%12llx", &u[0], &u[1], &u[2], &u[3], &u6);
    if (ret != 5) return -1;

    dst[0] = (u[0] >> 24) & 0xFF;
    dst[1] = (u[0] >> 16) & 0xFF;
    dst[2] = (u[0] >> 8) & 0xFF;
    dst[3] = (u[0] >> 0) & 0xFF;

    dst[4] = (u[1] >> 8) & 0xFF;
    dst[5] = (u[1] >> 0) & 0xFF;

    dst[6] = (u[2] >> 8) & 0xFF;
    dst[7] = (u[2] >> 0) & 0xFF;

    dst[8] = (u[3] >> 8) & 0xFF;
    dst[9] = (u[3] >> 0) & 0xFF;

    for (int i = 0; i < 6; i++) {
        dst[15 - i] = (u6 >> (i * 8)) & 0xFF;
    }

    return 0;
}

/**
* @breif Converts a column-seperated Mac address (00:01:02:03:04:05) into an 8-byte int,
*        in little-endian.
* @returns For the example, in LE: 0x0000000102030405
*/
inline unsigned long long macAddressToULL(const char* szMacAddress) {
    unsigned int buf[6];
    int ret = sscanf(szMacAddress, "%2x:%2x:%2x:%2x:%2x:%2x", &buf[0], &buf[1], &buf[2], &buf[3], &buf[4], &buf[5]);
    if (ret != 6)
        return ~0ULL;
    union
    {
        unsigned long long ull;
        unsigned char b[8];
    } u;
    u.ull = 0ULL;
    for (int i = 0; i < 6; i++)
        u.b[5 - i] = static_cast<unsigned char>(buf[i]);
    return u.ull;
}

