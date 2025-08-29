#!/usr/bin/env bash
. ./lib/common.sh

if [[ $1 == "user_part" ]]; then
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
git config --global credential.https://github.com.username x-access-token
git config --global user.name 'mc-sh'
git config --global user.email '228965348+mc-sh@users.noreply.github.com'

echo 'user_part done'; exit 0
fi

need_privilege

sudo apt update
sudo apt install -y git gnome-keyring libsecret-1-0 libsecret-1-dev libsecret-common

HELPER="/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret"
if [ ! -x "$HELPER" ]; then
    echo "Compilation du helper libsecret..."
    cd /usr/share/doc/git/contrib/credential/libsecret
    sudo make
else
    echo "Helper libsecret déjà compilé."
fi

exec_sudo_as_user

