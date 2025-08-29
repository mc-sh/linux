#!/usr/bin/env bash
. ./lib/common.sh
need_exec_as_user

remote(){
	read -p "entre le nom du repo" repo
	git remote add origin https://github.com/mc-sh/$repo.git
}

[[ $1 == 'create' ]] && git init && remote && git branch -M main
git add . 2> /dev/null || { echo "Try create as argument"; exit 1; }
read -p 'commit commentaire' commit
git commit -m "$commit"
git push -u origin main
