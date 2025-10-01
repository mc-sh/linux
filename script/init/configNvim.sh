#!/bin/bash
path="/etc/xdg/nvim/sysinit.vim"
sed -i 's/eol:$//g' $path
