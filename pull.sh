#!/usr/bin/env bash
. ../lib/common.sh
need_exec_as_user
# git fetch
# git merge --rebase (ecraser le repo distant)
git pull
