#ifndef CONQUESTSERV_H
#define CONQUESTSERV_H

#include <tamtypes.h>
#define MEMORYCARD_PAGESIZE 0x200
#define MEMORYCARD_ECCSIZE 0x10
#define MEMORYCARD_SC2CRCSIZE 0x4
#define MEMORYCARD_PAGESIZE_ECC (MEMORYCARD_PAGESIZE + MEMORYCARD_ECCSIZE)
#define CONQUESTCARD_PAGESIZE_CRC (MEMORYCARD_PAGESIZE + MEMORYCARD_SC2CRCSIZE)

#define SC2MCSERV_IRX 0x434F4E51 // 'CONQUESTSERV' -> 43 4F 4E 51 55 45 53 54 53 45 52 56
typedef struct conquest_packet_ {
    s32 port;
    s32 slot;
    u32 pagenum;
    s32 ret;
    union {
        //u8 full[0x300];
        u8 full[MEMORYCARD_PAGESIZE_ECC];
        struct split_
        {
            u8 data[MEMORYCARD_PAGESIZE];
            u8 ecc[MEMORYCARD_ECCSIZE];
            //u8 garbage[0x300-MEMORYCARD_PAGESIZE_ECC];
        }split;
    }page;
}conquest_packet_t;

typedef struct cardspecs_packet_ {
    s32 port; // Input
    s32 slot; // Input
    s32 ret; // Output, must be 0 to find valid data on the rest of the struct
    s16 pagesize; // Output
    u16 blocksize; // Output
    int cardsize; // Output
    u8 cardflags; // Output

}cardspecs_packet_t;

typedef struct eraseblock_packet_ {
    s32 port; // Input
    s32 slot; // Input
    s32 blocknum; // the memory card block to be erased
    s32 ret; // Output, must be 0 to find valid data on the rest of the struct

}eraseblock_packet_t;

enum RPCCMDS {
    SC2_ERASEPAGE = 0x50,
    SC2_READPAGE,
    SC2_WRITEPAGE,
    SC2_AUTHCARD,

    GENERIC_GET_CARDSPECS,
    GENERIC_ERASEBLOCK,
};

#endif
