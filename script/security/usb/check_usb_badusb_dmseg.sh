#!/usr/bin/env bash
. ../../../lib/common.sh
need_privilege

sudo dmesg -C
dmesg -w | egrep -i 'usb|idVendor|Product|Manufacturer|HID|Keyboard|Mouse|cdc|rndis|ether|ax88179|asix|smsc95xx' --line-buffered | sed \
 -e 's/.*\(usb-storage\|Mass Storage\|sd[a-z]\).*/\x1b[32mOK:\x1b[0m &/' \
 -e 's/.*\(HID\|Keyboard\|Mouse\|cdc\|rndis\|ether\|ax88179\|asix\|smsc95xx\).*/\x1b[31mSUSPECT:\x1b[0m &/'

