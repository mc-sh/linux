#!/usr/bin/env bash

#Avant toute chose connecte toi à github et va dans setting/dev/tokens/fine-grained. Donne les droits juste à un repo puis ajoute le droit "CONTENT" en READ/WRITE

#Si le system réagie bizarrement, sudo apt install -y seahorse pour valider l'entré de la clef

#pi OS demande de mettre un master password tandis que parrot utilise celui de la session par défaut

. ./lib/common.sh
error_handler

HELPER="/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret"

if [[ ${1:-} == "user_part" ]]; then
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
git config --global credential.https://github.com.username x-access-token
git config --global user.name 'mc-sh'
git config --global user.email '228965348+mc-sh@users.noreply.github.com'

echo 'user_part done'; exit 0
fi

need_privilege

sudo apt update
sudo apt install -y git gnome-keyring libsecret-1-0 libsecret-common

sudo apt-mark manual git gnome-keyring libsecret-1-0 libsecret-common || true

if [ ! -x "$HELPER" ]; then
    sudo apt install -y libsecret-1-dev
    echo "Compilation du helper libsecret..."
    pushd /usr/share/doc/git/contrib/credential/libsecret > /dev/null
    sudo make
    popd > /dev/null
    sudo apt autoremove -y libsecret-1-dev || true
else
    echo "Helper libsecret déjà compilé."
fi

exec_sudo_as_user

