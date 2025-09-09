#!/bin/bash
up(){
apt full-upgrade -y && apt autoremove -y && apt clean && echo -e "\n la liste des programes qui a fail d'installer" && echo "" && apt list -u
}
[[ $1 == u ]] && apt update && up || up
