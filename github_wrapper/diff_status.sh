#!/usr/bin/env bash
. ../lib/common.sh
need_exec_as_user
#git status (modif en attente, plus globale, toujours à regarder)
#git diff (ce qui est different entre ma branche locale (live) et ce qui n'est pas encore ajouter à add (excluant les nouveau fichier (voir git status))
#git diff --staged (ce qui est different entre mon add locale et ma branche distante, qui est dans le pipeline du prochain commit)
#git diff origin/main (diff entre ma branche locale et ma branche distante incluant ce qui est dans le add)
