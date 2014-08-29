# Copyright (c) 1986 Regents of the University of California.
# All rights reserved.  The Berkeley software License Agreement
# specifies the terms and conditions for redistribution.
#
# This makefile is designed to be run as:
#	make
#
# The `make' will compile everything, including a kernel, utilities
# and a root filesystem image.

#
# Supported boards
#
MAX32           = sys/pic32/max32/MAX32
MAX32-ETH       = sys/pic32/max32-eth/MAX32-ETH
UBW32           = sys/pic32/ubw32/UBW32
UBW32UART       = sys/pic32/ubw32-uart/UBW32-UART
UBW32UARTSDRAM  = sys/pic32/ubw32-uart-sdram/UBW32-UART-SDRAM
MAXIMITE        = sys/pic32/maximite/MAXIMITE
MAXCOLOR        = sys/pic32/maximite-color/MAXCOLOR
EXPLORER16      = sys/pic32/explorer16/EXPLORER16
STARTERKIT      = sys/pic32/starter-kit/STARTER-KIT
DUINOMITE       = sys/pic32/duinomite/DUINOMITE
DUINOMITEUART   = sys/pic32/duinomite-uart/DUINOMITE-UART
DUINOMITEE      = sys/pic32/duinomite-e/DUINOMITE-E
DUINOMITEEUART  = sys/pic32/duinomite-e-uart/DUINOMITE-E-UART
PINGUINO        = sys/pic32/pinguino-micro/PINGUINO-MICRO
DIP             = sys/pic32/dip/DIP
BAREMETAL       = sys/pic32/baremetal/BAREMETAL
RETROONE        = sys/pic32/retroone/RETROONE
FUBARINO        = sys/pic32/fubarino/FUBARINO
FUBARINOBIG     = sys/pic32/fubarino/FUBARINO-UART2CONS-UART1-SRAMC
MMBMX7          = sys/pic32/mmb-mx7/MMB-MX7
ATOM32          = sys/pic32/atom32/ATOM32

# Select target board
TARGET          ?= $(ATOM32)

# Filesystem and swap sizes.
FS_KBYTES       = 102400
U_KBYTES        = 102400
SWAP_KBYTES     = 2048

# Set this to the device name for your SD card.  With this
# enabled you can use "make installfs" to copy the filesys.img
# to the SD card.

#SDCARD          = /dev/sdb

#
# C library options: passed to libc makefile.
# See lib/libc/Makefile for explanation.
#
DEFS		= 

FSUTIL		= tools/fsutil/fsutil

-include Makefile.user

TARGETDIR    = $(shell dirname $(TARGET))
TARGETNAME   = $(shell basename $(TARGET))
TOPSRC       = $(shell pwd)
CONFIG       = $(TOPSRC)/tools/configsys/config

all:            tools build kernel
		$(MAKE) fs

fs:             sdcard.rd

.PHONY: 	tools
tools:
		$(MAKE) -C tools

kernel: 	$(TARGETDIR)/Makefile
		$(MAKE) -C $(TARGETDIR)

$(TARGETDIR)/Makefile: $(CONFIG) $(TARGETDIR)/$(TARGETNAME)
		cd $(TARGETDIR) && ../../../tools/configsys/config $(TARGETNAME)

.PHONY: 	lib
lib:
		$(MAKE) -C lib

build: 		tools lib
		$(MAKE) -C src install

filesys.img:	$(FSUTIL) rootfs.manifest #$(ALLFILES)
		rm -f $@
		$(FSUTIL) -n$(FS_KBYTES) -Mrootfs.manifest $@ .

swap.img:
		dd if=/dev/zero of=$@ bs=1k count=$(SWAP_KBYTES)

user.img:	$(FSUTIL) userfs.manifest
ifneq ($(U_KBYTES), 0)
		rm -f $@
		$(FSUTIL) -n$(U_KBYTES) -Muserfs.manifest $@ u
endif

sdcard.rd:	filesys.img swap.img user.img
ifneq ($(U_KBYTES), 0)
		tools/mkrd/mkrd -out $@ -boot filesys.img -swap swap.img -fs user.img
else
		tools/mkrd/mkrd -out $@ -boot filesys.img -swap swap.img
endif

$(FSUTIL):
		cd tools/fsutil; $(MAKE)

$(CONFIG):
		make -C tools/configsys

clean:
		rm -f *~
		for dir in tools lib src sys/pic32; do $(MAKE) -C $$dir -k clean; done

cleanall:       clean
		$(MAKE) -C lib clean
		rm -f sys/pic32/*/unix.hex bin/* sbin/* games/[a-k]* games/[m-z]* libexec/* share/man/cat*/*
		rm -f games/lib/adventure.dat
		rm -f games/lib/cfscores
		rm -f share/re.help
		rm -f share/emg.keys
		rm -f share/misc/more.help
		rm -f etc/termcap etc/remote etc/phones
		rm -rf share/unixbench
		rm -f games/lib/adventure.dat games/lib/cfscores share/re.help share/misc/more.help etc/termcap
		rm -f tools/configsys/.depend
		rm -f var/log/aculog
		rm -rf var/lock

installfs:      filesys.img
ifdef SDCARD
		sudo dd bs=32k if=sdcard.rd of=$(SDCARD)
else
		@echo "Error: No SDCARD defined."
endif

# TODO: make it relative to Target
installflash:
		sudo pic32prog sys/pic32/fubarino/unix.hex

# TODO: make it relative to Target
installboot:
		sudo pic32prog sys/pic32/fubarino/bootloader.hex

.profile:       etc/root/dot.profile
		cp etc/root/dot.profile .profile
