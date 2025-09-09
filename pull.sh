#!/usr/bin/env bash
. lib/common.sh
need_exec_as_user
# git fetch
# git merge --rebase (écraser les historique en Y et les SHA sont réécrit)
# git config pull.rebase false  # merge a chaque fois dans ce repo
git pull
