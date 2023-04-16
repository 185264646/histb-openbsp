# set autostart
env set autostart yes
# overwrite default bootmeth seq and try bootflow again
env set bootmenu_0 'Continue sysboot=bootmeth order "distro script"; bootflow scan -lb'
env set bootmenu_1 'Load l-loader.bin from USB and flash it to eMMC=mmc dev 1; usb reset; fatload usb 0:1 $loadaddr l-loader.bin && mmc write $loadaddr 0 800; reset'

bootmenu 30
