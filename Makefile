.SILENT:

define HEADER
 _____ _____  _____ ___  ___      _
/  ___/  __ \/ __  \|  \/  |     | |
\ `--.| /  \/`' / /'| .  . | __ _| | _____ _ __
 `--. \ |      / /  | |\/| |/ _` | |/ / _ \ '__|
/\__/ / \__/\./ /___| |  | | (_| |   <  __/ |
\____/ \____/\_____/\_|  |_/\__,_|_|\_\___|_|


                    SoulCalibur2 Conquest Card Maker

endef
export HEADER

MAJOR=1
MINOR=0
PATCH=0
PROGVER=$(MAJOR).$(MINOR).$(PATCH)
PACKNAME=SC2Maker_v$(PROGVER)
GITHASH=$(shell git rev-parse --short HEAD)
#------------------------------------------------------------------#
#----------------------- Configuration flags ----------------------#
#------------------------------------------------------------------#
#-------------------------- Reset the IOP -------------------------#
RESET_IOP = 1
#---------------------- enable DEBUGGING MODE ---------------------#
DEBUG = 0
#----------------------- Set IP for PS2Client ---------------------#
PS2LINK_IP = 192.168.1.10
#------------------------------------------------------------------#
F_KEYBOARD ?= 1

BINDIR = bin/
EE_BIN = $(BINDIR)sc2maker.elf
EE_BIN_PKD = $(BINDIR)sc2maker_pkd.elf

EE_LIBS = -L$(PS2SDK)/ports/lib -L$(PS2DEV)/gsKit/lib/ -Lmodules/ds34bt/ee/ -Lmodules/ds34usb/ee/ \
	-lpatches -lfileXio -lpad -ldebug -llua -lmath3d -ljpeg -lfreetype -lgskit_toolkit -lgskit -ldmakit \
	-lpng -lz -lmc -laudsrv -lelf-loader -lds34bt -lds34usb -liopreboot

EE_INCS += -I$(PS2DEV)/gsKit/include -I$(PS2SDK)/ports/include -I$(PS2SDK)/ports/include/freetype2 -I$(PS2SDK)/ports/include/zlib

EE_INCS += -Imodules/ds34bt/ee -Imodules/ds34usb/ee

EE_CFLAGS   += -Wno-sign-compare -fno-strict-aliasing -fno-exceptions -DLUA_USE_PS2 -DPROGVER=\"$(PROGVER)\" -DGITHASH=\"$(GITHASH)\"
EE_CXXFLAGS += -Wno-sign-compare -fno-strict-aliasing -fno-exceptions -DLUA_USE_PS2 -DPROGVER=\"$(PROGVER)\" -DGITHASH=\"$(GITHASH)\"

ifeq ($(RESET_IOP),1)
  EE_CXXFLAGS += -DRESET_IOP
endif

ifeq ($(MECHAEMU),1)
  EE_CXXFLAGS += -DMECHAEMU
endif

ifeq ($(DEBUG),1)
  EE_CXXFLAGS += -DDEBUG
endif

BIN2S = $(PS2SDK)/bin/bin2c
.PHONY: modules/dongleman_conquest/ modules/conquestserv/
#-------------------------- App Content ---------------------------#
EXT_LIBS = modules/ds34usb/ee/libds34usb.a modules/ds34bt/ee/libds34bt.a modules/dongleman_conquest/ modules/conquestserv/

APP_CORE = main.o system.o pad.o graphics.o render.o \
		   calc_3d.o gsKit3d_sup.o atlas.o fntsys.o md5.o \
		   sound.o

LUA_LIBS =	luaplayer.o luasound.o luacontrols.o \
			luatimer.o luaScreen.o luagraphics.o \
			luasystem.o luaRender.o

IOP_MODULES = iomanX.o fileXio.o \
			  sio2man.o dongleman_conquest.o dongleman_conquest_arcade.o conquest_server.o mcserv.o padman.o libsd.o \
			  usbd.o audsrv.o bdm.o bdmfs_fatfs.o \
			  usbmass_bd.o cdfs.o ds34bt.o ds34usb.o mmceman.o \
			  ioprp_arcade.o ioprp_mechaemu.o

EMBEDDED_RSC = boot.o

ifeq ($(F_KEYBOARD),1)
  EE_CXXFLAGS += -DPS2KBD
  EE_LIBS += -lkbd
  IOP_MODULES += ps2kbd.o
  LUA_LIBS +=  luaKeyboard.o
endif

EE_OBJS = $(APP_CORE) $(LUA_LIBS) $(IOP_MODULES) $(EMBEDDED_RSC)

EE_OBJS_DIR = obj/
EE_SRC_DIR = src/
EE_ASM_DIR = asm/
EE_OBJS := $(EE_OBJS:%=$(EE_OBJS_DIR)%) # remap all EE_OBJ to obj subdir

#------------------------------------------------------------------#
all: $(EXT_LIBS) $(EE_BIN)
	@echo "$$HEADER"

	$(EE_STRIP) $(EE_BIN)

	ps2-packer $(EE_BIN) $(EE_BIN_PKD) > /dev/null

#--------------------- Embedded ressources ------------------------#

pack: all
	rm -f $(PACKNAME).7z
	7z a -t7z $(PACKNAME).7z README.MD LICENSE $(EE_BIN_PKD) bin/cardmaterial.bin bin/font.ttf bin/*.lua bin/common/* bin/lang/*
	7z rn $(PACKNAME).7z bin $(PACKNAME)_$(shell date "+%d-%m-%Y")

$(EE_ASM_DIR)boot.c: etc/boot.lua | $(EE_ASM_DIR)
	$(BIN2S) $< $@ bootString

# Images
EMBED/%.s: EMBED/%.png
	$(BIN2S) $< $@ $(shell basename $< .png)
# Images
$(EE_ASM_DIR)%.c: embed/iop/%.img
	bin2c $< $@ $(shell basename $< .img)
#------------------------------------------------------------------#


#-------------------- Embedded IOP Modules ------------------------#
vpath %.irx embed/iop/
vpath %.irx modules/dongleman_conquest/
vpath %.irx modules/conquestserv/
vpath %.irx modules/ds34bt/iop/
vpath %.irx modules/ds34usb/iop/
vpath %.irx $(PS2SDK)/iop/irx/
IRXTAG = $(notdir $(addsuffix _irx, $(basename $<)))
$(EE_ASM_DIR)%.c: %.irx
	$(DIR_GUARD)
	$(BIN2S) $< $@ $(IRXTAG)

$(EE_ASM_DIR)ps2kbd.c: $(PS2SDK)/iop/irx/ps2kbd.irx | $(EE_ASM_DIR)
	$(BIN2S) $< $@ ps2kbd_irx

modules/ds34bt/ee/libds34bt.a: modules/ds34bt/ee
	$(MAKE) -C $<

modules/ds34bt/iop/ds34bt.irx: modules/ds34bt/iop
	$(MAKE) -C $<

modules/ds34usb/ee/libds34usb.a: modules/ds34usb/ee
	$(MAKE) -C $<

modules/ds34usb/iop/ds34usb.irx: modules/ds34usb/iop
	$(MAKE) -C $<

modules/dongleman_conquest/:
	$(MAKE) -C $@ clean all
	$(MAKE) -C $@ clean all MCMAN_BUILDING_DONGLEMAN=1

modules/conquestserv/:
	$(MAKE) -C $@
#------------------------------------------------------------------#

$(EE_OBJS_DIR):
	@mkdir -p $@

$(EE_ASM_DIR):
	@mkdir -p $@

debug: $(EE_BIN)
	echo "Building $(EE_BIN) with debug symbols..."

clean:
	@rm -rf $(EE_OBJS_DIR)
	@rm -rf $(EE_ASM_DIR)
	$(MAKE) -C modules/ds34usb clean
	$(MAKE) -C modules/ds34bt clean
	$(MAKE) -C modules/conquestserv/ clean
	$(MAKE) -C modules/dongleman_conquest/ clean
	rm -f $(BINDIR)$(EE_BIN)
	rm -f $(BINDIR)$(EE_BIN_PKD)
	rm -f $(EMBEDDED_RSC)

cleanmod:
	$(MAKE) -C modules/conquestserv/ clean
	$(MAKE) -C modules/dongleman_conquest/ clean
	rm -f $(EMBEDDED_RSC)
	rm -f $(BINDIR)$(EE_BIN)
	rm -f $(BINDIR)$(EE_BIN_PKD)

rebuild: clean all

run:
	cd bin; ps2client -h $(PS2LINK_IP) execee host:$(EE_BIN)

intellisense:
	etc/update_lua_globals.sh

reset:
	ps2client -h $(PS2LINK_IP) reset

$(EE_OBJS_DIR)%.o: $(EE_SRC_DIR)%.c | $(EE_OBJS_DIR)
	@echo "  - $@"
	@$(EE_CC) $(EE_CFLAGS) $(EE_INCS) -c $< -o $@

$(EE_OBJS_DIR)%.o: $(EE_ASM_DIR)%.c | $(EE_OBJS_DIR)
	@echo "  - $@"
	@$(EE_CC) $(EE_CFLAGS) $(EE_INCS) -c $< -o $@

$(EE_OBJS_DIR)%.o: $(EE_SRC_DIR)%.cpp | $(EE_OBJS_DIR)
	@echo "  - $@"
	$(EE_CXX) $(EE_CXXFLAGS) $(EE_INCS) -c $< -o $@

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal
