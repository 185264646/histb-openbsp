# SPDX-License-Identifier: GPL-2.0+

# Global Variables
CROSS_COMPILE?=aarch64-linux-gnu-
ARCH?=arm
# debug mode
DEBUG?=0
# build recovery image
REC?=0
PLAT?=hi3798mv2x
PWD:=$(shell pwd)

# U-boot variables
UBOOT_DIR=u-boot
UBOOT_PATH=$(PWD)/$(UBOOT_DIR)
UBOOT_DEFCONF:=hc2910_2aghd05_defconfig
UBOOT_BIN:=$(UBOOT_PATH)/u-boot.bin

# U-Boot flags
UBOOT_FLAGS_BASE:=-C$(UBOOT_DIR)
UBOOT_FLAGS_BASE+=CROSS_COMPILE=$(CROSS_COMPILE)
UBOOT_FLAGS_BASE+=ARCH=arm

UBOOT_CONF_FLAGS:=$(UBOOT_FLAGS_BASE) $(UBOOT_DEFCONF)
UBOOT_BUILD_FLAGS:=$(UBOOT_FLAGS_BASE)
ifeq ($(DEBUG), 1)
	UBOOT_BUILD_FLAGS+=DEBUG=1
endif
ifeq ($(REC), 1)
	UBOOT_BUILD_FLAGS+=LOCALVERSION=-recovery
endif

# Arm Trusted Firmware(ATF) variables

# ATF flags
ATF_DIR=arm-trusted-firmware
ATF_PATH=$(PWD)/$(ATF_DIR)
ATF_FLAGS:=-C$(ATF_DIR)
ATF_FLAGS+=PLAT=hi3798mv2x
ATF_FLAGS+=SPD=none
ATF_FLAGS+=USE_COHERENT_MEM=1
# ATF_FLAGS+=TF_LDFLAGS:=--no-warn-rwx-segment
ifeq ($(DEBUG), 1)
	ATF_FLAGS+=DEBUG=1 LOG_LEVEL=50
endif
ATF_FLAGS+=CROSS_COMPILE=$(CROSS_COMPILE)
ifeq ($(DEBUG), 1)
	BL1_BIN=$(ATF_PATH)/build/hi3798mv2x/debug/bl1.bin
	FIP_BIN=$(ATF_PATH)/build/hi3798mv2x/debug/fip.bin
else
	BL1_BIN=$(ATF_PATH)/build/hi3798mv2x/release/bl1.bin
	FIP_BIN=$(ATF_PATH)/build/hi3798mv2x/release/fip.bin
endif
ifeq ($(REC), 1)
	ATF_FLAGS+=POPLAR_RECOVERY=1
endif
ATF_FLAGS+=BL33=$(UBOOT_BIN) all fip

# l-loader variables
L-LOADER_PATH:=l-loader
L-LOADER_FLAGS:=-C$(L-LOADER_PATH)
L-LOADER_FLAGS+=CROSS_COMPILE=arm-none-eabi-
ifeq ($(REC), 1)
	L-LOADER_FLAGS+=RECOVERY=1
	L-LOADER_BIN?=$(L-LOADER_PATH)/fastboot.bin
else
	L-LOADER_BIN?=$(L-LOADER_PATH)/l-loader.bin
endif

# Targets
.PHONY: all clean install u-boot atf l-loader recover

all: l-loader

recover:
	python.exe scripts/serial_boot.py -t $(L-LOADER_BIN)

clean:
	-rm -rf out
	-rm -rf $(ATF_PATH)/build
	$(MAKE) -C$(ATF_PATH) clean
	$(MAKE) -C$(L-LOADER_PATH) clean
	$(MAKE) -C$(UBOOT_PATH) clean

atf: u-boot
	$(MAKE) $(ATF_FLAGS)

l-loader: atf
	install $(BL1_BIN) $(FIP_BIN) $(L-LOADER_PATH)/atf
	# l-loader must be cleaned before recompiling
	$(MAKE) $(L-LOADER_FLAGS) clean all

u-boot:
	$(MAKE) $(UBOOT_CONF_FLAGS)
	$(MAKE) $(UBOOT_BUILD_FLAGS)

u-boot.uImage: u-boot
	mkimage -A arm64 -O u-boot -T standalone -C none -a 0x800000 -e 0x800000 -d u-boot/u-boot.bin $@

install: recovery_scripts/extlinux.conf u-boot.uImage l-loader recovery_scripts/boot.scr
	install -D -t out/extlinux recovery_scripts/extlinux.conf
	install -D -t out u-boot.uImage $(L-LOADER_BIN) recovery_scripts/boot.scr

recovery_scripts/boot.scr: recovery_scripts/boot.cmd
	mkimage -A arm -T script -C none -a 0x800000 -e 0x800000 -d $< $@
