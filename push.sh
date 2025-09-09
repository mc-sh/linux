#!/usr/bin/env bash
. lib/common.sh
need_exec_as_user

git add -A # git add .
read -p 'commit commentaire' commit
git commit -m "$commit"
git push
