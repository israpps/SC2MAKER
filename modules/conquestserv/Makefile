
IOP_BIN = conquest_server.irx


IOP_IMPORT_INCS += \
    system/intrman \
    system/ioman \
    system/iomanx \
    system/loadcore \
    system/modload \
    system/sio2man \
    system/stdio \
    system/sysclib \
    system/threadman \
    system/timrman \
	memorycard/mcman

IOP_OBJS = \
    main.o \
    imports.o

include $(PS2SDK)/Defs.make
include ../Rules.bin.make
IOP_SRC_DIR = ./
IOP_INC_DIR = ./
include $(PS2SDK)/samples/Makefile.iopglobal
