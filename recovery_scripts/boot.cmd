# set autostart
env set autostart yes

# originally it searches for boot.scr first, so we are always sourced before
# extlinux.conf. We override it here and retry a bootflow scan. A better idea
# is welcomed.
env set bootmenu_0 'Continue sysboot=bootmeth order "distro script"; bootflow scan -lb'
env set bootmenu_1 'Load l-loader.bin from USB and flash it to eMMC=mmc dev 1; usb reset; fatload usb 0:1 $loadaddr l-loader.bin && mmc write $loadaddr 0 800; reset'

bootmenu 30
