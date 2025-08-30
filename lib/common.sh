#!/usr/bin/env bash
need_privilege(){
	[[ "$EUID" != 0 ]] && echo "Doit etre demarrer avec Sudo" && exit 1 || true
}

need_exec_as_user(){
	[[ "$EUID" == 0 ]] && echo "Doit etre démarrer avec un User" && exit 1

}

error_handler(){
	set -euo pipefail
}

exec_sudo_as_user(){
	exec sudo -u "$SUDO_USER" bash "$0" user_part --as-user
}

