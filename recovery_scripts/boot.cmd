# set autostart
env set autostart yes
env set bootmenu_0 Continue sysboot=sysboot usb 0:1
env set bootmenu_1 Load l-loader.bin from USB and flash it to eMMC=usb reset; fatload usb 0:1 $loadaddr l-loader.bin && mmc write $loadaddr 0 800; reset

bootmenu 30
