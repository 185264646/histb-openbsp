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
	BL1_PATH=out/atf/hi3798mv2x/debug/bl1.bin
	FIP_PATH=out/atf/hi3798mv2x/debug/fip.bin
else
	BL1_PATH=out/atf/hi3798mv2x/release/bl1.bin
	FIP_PATH=out/atf/hi3798mv2x/release/fip.bin
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

# Linux kernel vars
KERNEL_PATH:=linux
KERNEL_BASE_FLAGS:=-C$(KERNEL_PATH) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm64
KERNEL_CONF_FLAGS:=$(KERNEL_BASE_FLAGS) hi3798mv2x_defconfig
ifeq ($(DEBUG), 1)
	KERNEL_CONF_FLAGS+=hi3798mv2x_debug.config
endif
ifeq ($(DTB), 1)
	DTB_FLAGS=dtbs
endif
KERNEL_BUILD_FLAGS:=$(KERNEL_BASE_FLAGS) $(DTB_FLAGS)
# Targets
.PHONY: all clean install u-boot atf l-loader linux recover

all: l-loader linux

recover:
	python.exe scripts/serial_boot.py -t $(L-LOADER_BIN)

clean:
	-rm -rf out
	-rm -rf $(ATF_PATH)/build
	$(MAKE) -C$(L-LOADER_PATH) clean
	$(MAKE) -C$(UBOOT_PATH) clean
	$(MAKE) -C$(KERNEL_PATH) clean

atf: u-boot
	$(MAKE) $(ATF_FLAGS)
	mkdir -p out/atf
	cp -rf $(ATF_PATH)/build/hi3798mv2x out/atf

l-loader: atf
	cp $(BL1_PATH) $(FIP_PATH) $(L-LOADER_PATH)/atf
	$(MAKE) $(L-LOADER_FLAGS) clean all

u-boot:
	$(MAKE) $(UBOOT_CONF_FLAGS)
	$(MAKE) $(UBOOT_BUILD_FLAGS)

linux:
	$(MAKE) $(KERNEL_CONF_FLAGS)
	$(MAKE) $(KERNEL_BUILD_FLAGS)
	mkdir -p out/linux
	install $(KERNEL_PATH)/arch/arm64/boot/Image.gz $(KERNEL_PATH)/arch/arm64/boot/dts/hisilicon/hi3798mv200-hc2910v7.dtb out/linux
