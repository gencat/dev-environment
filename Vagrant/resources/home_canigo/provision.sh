#!/usr/bin/env bash

# shellcheck disable=SC1091
source /vagrant/resources/provision-common.sh || exit 127

log "Configurant usuari canigo ..."

#if [ -d /home/canigo ]; then
#  rm -fr /home/canigo || die 1
#  mkdir -p /home/canigo || die 8
#fi

cd /home || die 2

# clean-up selectiu
# cd /home/canigo
# rm -fr [D-X]* .[c-l]* .mozilla/ .pki/ .[s-x]* .[X]*
# mkdir t1; cp -r [D-V]* .[c-l]* .mozilla/ .pki/ .[s-x]* .Xauthority .xsession-errors* t1
# cd ..

declare -r _RESOURCES=/vagrant/resources/home_canigo

tar -xvJf ${_RESOURCES}/init.tar.xz --overwrite -C /home || die 3
cp -vfr ${_RESOURCES}/resources/* /home/canigo || die 4
cp -vfr ${_RESOURCES}/resources/.[a-z]* /home/canigo || die 5
tar -xvJf ${_RESOURCES}/.jedit.tar.xz --overwrite -C /home/canigo || die 6

for folder in Documents Downloads Music Templates Videos .m2 ; do mkdir -p "/home/canigo/${folder}" ; done

# ADD Desktop icons
cp -vfr ${_RESOURCES}/resources/Desktop/* /home/canigo/.local/share/applications/ || die 7
chmod -R a+w /home/canigo/.local/share/applications/

# FIX INTCAN-1792 Problemes integració plugin de Canigó
ln -s /opt/apache-maven-*/conf/settings.xml /home/canigo/.m2/settings.xml || die 8

# FIX Keyboard xset rate https://askubuntu.com/a/1014269/507470
sed -i -E 's:r rate [0-9]+ [0-9]+:r rate 300 50:' /home/canigo/.config/autostart/LXinput-setup.desktop

# Històricament a Documents/ hi havia el workspace, i per aquest motiu es crea un enllaç
ln -s /opt/workspaces/workspace-canigo /home/canigo/Documents/workspace-canigo || die 9

# FIX Informació .desktop des-alineada amb la versió que es pot instal·lar via snap
ln -s /var/lib/snapd/desktop/applications/code_code.desktop /home/canigo/Desktop/code_code.desktop || die 10

chown -R canigo:canigo /home/canigo

# Mark trusted desktop's files
# https://askubuntu.com/questions/1056591/how-do-i-mark-a-desktop-file-as-trusted-in-ubuntu-18-04
chmod ug+wx /home/canigo/Desktop/*.desktop
for file in /home/canigo/Desktop/*.desktop; do su - canigo -c "dbus-launch gio set ${file} \"metadata::trusted\" true" ; done
