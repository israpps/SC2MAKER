#include "conquest_card.h"
#include "mcman-internal.h"
#include <stdint.h>
#define _HAKAMA_SIGNALSEMA() SignalSema(sema_hakama_id)
#define _HAKAMA_WAITSEMA() WaitSema(sema_hakama_id)

#ifndef DEBUG
#define SCPRINTF(x...)
#else
#define SCPRINTF(format, args...) printf("sc2: " format, ##args)
#endif

void set_conquest_transfer_methods();
void conquest_set_terminator(int port, int slot, int term);
void conquest_eraseblock(int port, int slot, u8 page);
int conquest_get_terminator(int port, int slot);
int conquest_sio2_transf(void);

extern int mcman_calcEDC(void *buf, int size);
#define conquest_calcEDC mcman_calcEDC

/// @brief restores normal dongleman cnum method, restores access to the security dongle after the conquest card operation was done
#define RESTORE_NORMAL_PS2COM()                          \
    SecrSetMcCommandHandler((void *)secrman_mc_command); \
    SecrSetMcDevIDHandler((void *)mcman_getcnum)

/// @see set_conquest_transfer_methods
#define SETUP_CONQUEST_PS2COM() set_conquest_transfer_methods()

sio2_transfer_data_t conquest_sio2packet;
static u8 conquest_wdmabufs[0x0b * 0x90]; // buffer array for SIO2 DMA I/O (write)
static u8 conquest_rdmabufs[0x0b * 0x90]; // not sure here for size, buffer array for SIO2 DMA I/O (read)

/**
 * @brief alternative cnum handler.
 * @note ASSUMPTION: this implicitly takes advantage of the arcade mechacon quirks to ensure that any cmd
 *        meant to go into conquest card will NOT go to the security dongle. since arcade mechacon expects 0xF cnum to allow dongle access
 */
int conquest_getcnum(int port, int slot)
{
    return (port & 1) * 8 + slot;
}

void FUN_000110a0(int port, int slot, void *cmd_array, size_t cmd_array_size, int pos, u32 param_6)
{
    conquest_sio2packet.in_dma.count = pos;
    conquest_sio2packet.regdata[pos] =
        (port & 1) + 2 & 3 | 0x70 | (param_6 & 0x1ff) << 0x12 | (param_6 & 0x1ff) << 8;
    memcpy(conquest_wdmabufs + pos * 0x90, cmd_array, cmd_array_size);
    return;
}

void FUN_00011120(int p)
{
    conquest_sio2packet.in_dma.count = p;
    conquest_sio2packet.out_dma.count = p;
    conquest_sio2packet.regdata[p] = 0;
    return;
}

int conquest_McCommandHandler(int port, int slot, sio2_transfer_data_t *packet)
{
    int r;
    sio2_mc_transfer_init();
    r = sio2_transfer(packet);
    sio2_transfer_reset();
    return r;
}

int conquest_setup_rdwrend(int port, int slot, int param_3)
{
    u8 p[2] = {0x81, 0x81};
    FUN_000110a0(port, slot, p, 2, param_3, 4);
    return 1;
}

int conquest_setup_erase(int port, int slot, u8 *page, int param_4)
{
    u8 p[7];

    p[0] = 0x81;
    p[1] = 0x21;
    p[2] = page[0];
    p[3] = page[1];
    p[4] = page[2];
    p[5] = page[3];
    p[6] = conquest_calcEDC(&p[2], 4);
    FUN_000110a0(port, slot, p, 7, param_4, 9);
    return 1;
}

static int mcman_56_internal(int port, int slot, int page)
{
    conquest_setup_erase(port, slot, (u8 *)&page, 0);
    conquest_setup_rdwrend(port, slot, 1);
    FUN_00011120(2);
    return conquest_sio2_transf();
}

int nmConquestPageErase(int port, int slot, int page)
{
    int r;
    SCPRINTF("%s: pag 0x%x\n", __func__, (page << 4));
    _HAKAMA_WAITSEMA();
    SETUP_CONQUEST_PS2COM();
    r = mcman_56_internal(port, slot, page << 4);
    RESTORE_NORMAL_PS2COM();
    _HAKAMA_SIGNALSEMA();
    return r;
}

int conquest_setup_readpage(int port, int slot, int readsize, int param_4)
{
    u8 p[3];

    p[0] = 0x81;
    p[1] = 0x43;
    p[2] = (u8)readsize;
    FUN_000110a0(port, slot, p, 3, param_4, readsize + 6);
    return 1;
}

int conquest_setup_startread(int port, int slot, u8 *page, int regpos)
{
    u8 p[7];
    p[0] = 0x81;
    p[1] = 0x23;
    p[2] = page[0];
    p[3] = page[1];
    p[4] = page[2];
    p[5] = page[3];
    p[6] = mcman_calcEDC(&p[2], 4);
    FUN_000110a0(port, slot, p, 7, regpos, 9);
    return 1;
}

typedef unsigned int uint;
typedef int undefined4;
typedef u8 byte;
// typedef unsigned int u32;

int mcman_57_internal(int port, int slot, int page, int readsize, u8 *buf)
{
    byte *pbVar1;
    u8 *puVar2;
    byte *pbVar3;
    uint uVar4;
    uint uVar8;
    uint uVar5;
    uint uVar6;
    uint uVar7;
    uint uVar9;
    int iVar4;
    int iVar5;
    int iVar6;

    iVar4 = 1;
    conquest_setup_startread(port, slot, (u8*)&page, 0);
    iVar5 = iVar4;
    if (0 < readsize)
    {
        do
        {
            iVar5 = iVar4 + 1;
            conquest_setup_readpage(port, slot, 0x80, iVar4);
            readsize = readsize + -0x80;
            iVar4 = iVar5;
        } while (0 < readsize);
    }
    iVar6 = iVar5 + 1;
    conquest_setup_rdwrend(port, slot, iVar5);
    FUN_00011120(iVar6);
    iVar4 = conquest_sio2_transf();
    iVar5 = -1;
    if (iVar4 == 1)
    {
        iVar4 = 1;
        iVar5 = 1;
        if (1 < iVar6)
        {
            pbVar3 = &conquest_rdmabufs[0x94];

            for (int i = 1; i < iVar6-2; i++) { // here we copy just the DMA blocks holding card data
                memcpy(buf, pbVar3, 0x80);
                buf += 0x80;
                pbVar3 += 0x90;
            }
            memcpy(buf, pbVar3, 0x10); //the last one... here we copy just the ECC
            iVar5 = 1;
        }
    }
    return iVar5;
}

int nmConquestPageRead(int port, int slot, int page, int size, void *buf)
{
    int r;

    _HAKAMA_WAITSEMA();
    SETUP_CONQUEST_PS2COM();
    r = mcman_57_internal(port, slot, page, size, buf);
    RESTORE_NORMAL_PS2COM();
    _HAKAMA_SIGNALSEMA();
    return r;
}

int conquest_setup_write(int port, int slot, void *pagebuf, int pagesize, int param_5)
{
    u8 p[136];

    p[0] = 0x81;
    p[1] = 0x42;
    p[2] = (u8)pagesize;
    memcpy(p + 3, pagebuf, pagesize);
    FUN_000110a0(port, slot, p, pagesize + 4, param_5, pagesize + 6);
    return 1;
}

int conquest_setup_startwrite(int port, int slot, u8 *page, int param_4)
{
    u8 p[7];

    p[0] = 0x81;
    p[1] = 0x22;
    p[2] = page[0];
    p[3] = page[1];
    p[4] = page[2];
    p[5] = page[3];
    p[6] = conquest_calcEDC(&p[2], 4);
    FUN_000110a0(port, slot, p, 7, param_4, 9);
    return 1;
}

int mcman_58_internal(int port, int slot, int page, int size, void *buf)
{
    int iVar1;
    int iVar2;

    iVar2 = 1;
    conquest_setup_startwrite(port, slot, (u8 *)&page, 0);
    iVar1 = iVar2;
    if (0 < size)
    {
        do
        {
            iVar2 = iVar1 + 1;
            conquest_setup_write(port, slot, buf, 0x80, iVar1);
            size -= 0x80;
            buf += 0x80; //(void *)((int)buf + 0x80);
            iVar1 = iVar2;
        } while (0 < size);
    }
    conquest_setup_rdwrend(port, slot, iVar2);
    FUN_00011120(iVar2 + 1);
    iVar1 = conquest_sio2_transf();
    return iVar1;
}

int nmConquestPageWrite(int port, int slot, int page, int size, void *buf)
{
    int r;

    _HAKAMA_WAITSEMA();
    SETUP_CONQUEST_PS2COM();
    r = mcman_58_internal(port, slot, page, size, buf);
    RESTORE_NORMAL_PS2COM();
    _HAKAMA_SIGNALSEMA();
    return r;
}

int conquest_setup_resetauth(int port, int slot, int regpos)
{
    u8 p[2] = {0x81, 0xf3};
    FUN_000110a0(port, slot, p, 2, regpos, 5);
    return 1;
}

void conquest_resetauth(int port, int slot)
{
    conquest_setup_resetauth(port, slot, 0);
    FUN_00011120(1);
    conquest_sio2_transf();
    return;
}

int conquest_setup_authcard(int port, int slot)
{
    conquest_resetauth(port, slot);
    return SecrAuthCard(port + 2, slot, conquest_getcnum(port, slot));
}

int nmConquestAuthCard(int port, int slot)
{
    int term;
    int r;

    _HAKAMA_WAITSEMA();
    SETUP_CONQUEST_PS2COM();
    if ((conquest_setup_authcard(port, slot) == 0) || (term = conquest_get_terminator(port, slot)) < 0)
    {
        /// ISRA: huh? why the restore comms is inside the 'else' only? did they want this to stay this way?
        /// not restoring the cnum handler makes DAEMON incapable of doing its job. that would trigger a console reset after some minutes
        _HAKAMA_SIGNALSEMA();
        r = 0;
    }
    else
    {
        r = 2;
        if (term == 0x57)
        {
            r = 1;
        }
        conquest_set_terminator(port, slot, 0x57);
        conquest_eraseblock(port, slot, 0x47);
        RESTORE_NORMAL_PS2COM();
        _HAKAMA_SIGNALSEMA();
    }
    return r;
}

int conquest_setup_set_terminator(int port, int slot, u8 term, int param_4)
{
    u8 local_10[3];

    local_10[0] = 0x81;
    local_10[1] = 0x27;
    local_10[2] = term;
    FUN_000110a0(port, slot, local_10, 3, param_4, 5);
    return 1;
}

void conquest_set_terminator(int port, int slot, int term)
{
    conquest_setup_set_terminator(port, slot, (u8)term, 0);
    FUN_00011120(1);
    conquest_sio2_transf();
    return;
}

int conquest_setup_eraseblock(int port, int slot, u8 page, int param_4)
{
    u8 cmdarray[3];

    cmdarray[0] = 0x81;
    cmdarray[1] = 0x12;
    cmdarray[2] = page;
    FUN_000110a0(port, slot, cmdarray, 3, param_4, 4);
    return 1;
}

void conquest_eraseblock(int port, int slot, u8 page)
{
    conquest_setup_eraseblock(port, slot, page, 0);
    FUN_00011120(1);
    conquest_sio2_transf();
    return;
}

int conquest_setup_get_terminator(int port, int slot, int param_3)
{
    u8 p[2];

    p[0] = 0x81;
    p[1] = 0x28;
    FUN_000110a0(port, slot, p, 2, param_3, 5);
    return 1;
}

int conquest_get_terminator(int port, int slot)
{
    int r;

    conquest_setup_get_terminator(port, slot, 0);
    FUN_00011120(1);
    r = conquest_sio2_transf();
    if (r == 1)
        r = (int)conquest_rdmabufs[4];
    return r;
}

void set_conquest_transfer_methods(void)
{
    int iVar2;

    memset(&conquest_sio2packet, 0, sizeof(conquest_sio2packet));
    /** TODO: Confirm is this is equivalent to what homebrew MCMAN already performs
    uint32_t *puVar1;
    uint32_t *puVar3;
    iVar2 = 2;
    puVar1 = conquest_sio2packet.port_ctrl2 + 2;
    puVar3 = conquest_sio2packet.port_ctrl1 + 2;
    do
    {
        *(undefined1 *)puVar3 = 5;
        *(undefined1 *)((int)puVar3 + 1) = 4;
        *(undefined1 *)((int)puVar3 + 2) = 2;
        *(undefined1 *)((int)puVar3 + 3) = 0xff;
        puVar3 = puVar3 + 1;
        *(undefined1 *)((int)puVar1 + 2) = 5;
        *(undefined2 *)puVar1 = 0xffff;
        iVar2 = iVar2 + 1;
        *puVar1 = *puVar1 & 0xfcffffff;
        puVar1 = puVar1 + 1;
    } while (iVar2 < 4);*/

    conquest_sio2packet.port_ctrl1[2] = 0xff020405;
    conquest_sio2packet.port_ctrl1[3] = 0xff020405;
    conquest_sio2packet.port_ctrl2[2] = 0x0005ffff & ~0x03000000;
    conquest_sio2packet.port_ctrl2[3] = 0x0005ffff & ~0x03000000;

    conquest_sio2packet.in_dma.addr = conquest_wdmabufs;
    conquest_sio2packet.out_dma.addr = conquest_rdmabufs;
    conquest_sio2packet.out_dma.size = 0x24;
    conquest_sio2packet.in_dma.size = 0x24;
    SecrSetMcCommandHandler(conquest_McCommandHandler);
    SecrSetMcDevIDHandler(conquest_getcnum);
    return;
}

int conquest_sio2_transf(void)
{
    int retry = 0;
    do
    {
        sio2_mc_transfer_init();
        sio2_transfer(&conquest_sio2packet);
        sio2_transfer_reset();
        retry++;
        if ((conquest_sio2packet.stat6c & 0xf000) == 0x1000)
        {
            return 1;
        }
    } while (retry < 5);
    return -1;
}
