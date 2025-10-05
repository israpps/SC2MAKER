#include "irx_imports.h"
#include "conquest_service.h"
#define MODNAME "SC2mcserv"
#define MAJOR 1
#define MINOR 0

IRX_ID(MODNAME, MAJOR, MINOR);

static SifRpcDataQueue_t sc2serv_queue;
static SifRpcServerData_t sc2serv_server;
static u8 sc2serv_rpc_buffer[0x300] __attribute__((__aligned__(4)));
static int RPCThreadID;

#ifdef DEBUG
#define DPRINTF(format, args...) printf(MODNAME ": " format, ##args)
#else
#define DPRINTF(x...)
#endif

void erasepage(conquest_packet_t *pkt) {
    pkt->ret = nmConquestPageErase(pkt->port, pkt->slot, pkt->pagenum);
    DPRINTF("nmConquestPageErase(%d, %d, 0x%04x): %d\n", pkt->port, pkt->slot, pkt->pagenum, pkt->ret);
}

void readpage(conquest_packet_t *pkt) {
    pkt->ret = nmConquestPageRead(pkt->port, pkt->slot, pkt->pagenum, 0x210, pkt->page.full);
    DPRINTF("nmConquestPageRead(%d, %d, 0x%04x, 0x210, pkt->page.full): %d\n", pkt->port, pkt->slot, pkt->pagenum, pkt->ret);
}

void writepage(conquest_packet_t *pkt) {
    pkt->ret = nmConquestPageWrite(pkt->port, pkt->slot, pkt->pagenum, 0x210, pkt->page.full);
    DPRINTF("nmConquestPageWrite(%d, %d, 0x%04x, 0x210, pkt->page.full): %d\n", pkt->port, pkt->slot, pkt->pagenum, pkt->ret);
}

void authcard(conquest_packet_t *pkt) {
    DPRINTF("nmConquestAuthCard(%d, %d)\n", pkt->port, pkt->slot);
    pkt->ret = nmConquestAuthCard(pkt->port, pkt->slot);
    DPRINTF("nmConquestAuthCard(%d, %d): %d\n", pkt->port, pkt->slot, pkt->ret);
}

void getcardspecs(cardspecs_packet_t *mcdi) {
    mcdi->ret = McGetCardSpec(mcdi->port, mcdi->slot, &mcdi->pagesize, &mcdi->blocksize, &mcdi->cardsize, &mcdi->cardflags);
    DPRINTF("McGetCardSpec(%d, %d): %d\n", mcdi->port, mcdi->slot, mcdi->ret);
}

void eraseblock(eraseblock_packet_t *pkt) {
    pkt->ret = McEraseBlock2(pkt->port, pkt->slot, pkt->blocknum, NULL, NULL);
    DPRINTF("McEraseBlock2(%d, %d, 0x%x): %d\n", pkt->port, pkt->slot, pkt->blocknum, pkt->ret);
}

static void *sc2serv_rpc_handler(unsigned int CMD, void *rpcBuffer, int size)
{
    switch(CMD)
	{

        case SC2_ERASEPAGE:
            erasepage(rpcBuffer);
            break;
        case SC2_READPAGE:
            readpage(rpcBuffer);
            break;
        case SC2_WRITEPAGE:
            writepage(rpcBuffer);
            break;
        case SC2_AUTHCARD:
            authcard(rpcBuffer);
            break;
        case GENERIC_GET_CARDSPECS:
            getcardspecs(rpcBuffer);
            break;
        case GENERIC_ERASEBLOCK:
            eraseblock(rpcBuffer);
            break;
        default:
            printf(MODNAME ": Unknown CMD (%d) called!\n", CMD);
    }

    return rpcBuffer;
}

static void threadRpcFunction(void *arg)
{
	(void)arg;

	DPRINTF("RPC Thread Started\n");

	SifSetRpcQueue( &sc2serv_queue , GetThreadId() );
	SifRegisterRpc( &sc2serv_server, SC2MCSERV_IRX, (void *)sc2serv_rpc_handler,(u8 *)&sc2serv_rpc_buffer,NULL,NULL, &sc2serv_queue );
	SifRpcLoop( &sc2serv_queue );
}


int _start(int argc, char *argv[])
{
    printf("Conquest card RPC manager v%d.%d by El_isra\n", MAJOR, MINOR);

	iop_thread_t T;
	T.attr = TH_C;
	T.option = 0;
	T.thread = &threadRpcFunction;
	T.stacksize = 0x800;
	T.priority = 0x1e;

	DPRINTF("Creating RPC thread.\n");
	RPCThreadID = CreateThread(&T);
	if (RPCThreadID < 0)
	{
		DPRINTF("CreateThread failed. (%i)\n", RPCThreadID);
        goto quit;
	}
	else
	{
#ifdef DEBUG
		int TSTAT =
#endif
        StartThread(RPCThreadID, NULL);
        DPRINTF("Thread started (%d)\n", TSTAT);
	}

    return MODULE_RESIDENT_END;
    quit_and_stop_thread:
    DeleteThread(RPCThreadID);
    quit:
    return MODULE_NO_RESIDENT_END;
}
