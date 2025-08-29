#!/usr/bin/env bash
. ../lib/common.sh
need_privilege
error_handler
sudo systemctl restart lightdm
