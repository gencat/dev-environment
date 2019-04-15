#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

log "Configurant usuari canigo ..."

# rm -fr /home/canigo || die 1
# mkdir -p /home/canigo && cd /home/canigo || die 2

cd /home || die 2

# clean-up selectiu
# cd /home/canigo
# rm -fr [D-X]* .[c-l]* .mozilla/ .pki/ .[s-x]* .[X]*
# mkdir t1; cp -r [D-V]* .[c-l]* .mozilla/ .pki/ .[s-x]* .Xauthority .xsession-errors* t1
# cd ..

_RESOURCES=/tmp/resources/home_canigo

tar -xvJf $_RESOURCES/init.tar.xz --overwrite -C /home || die 3

cp -vfr $_RESOURCES/resources/* /home/canigo || die 4
cp -vfr $_RESOURCES/resources/.[a-z]* /home/canigo || die 5

tar -xvJf $_RESOURCES/.jedit.tar.xz --overwrite -C /home/canigo || die 6

# FIX INTCAN-1792 Problemes integració plugin de Canigó
ln -s /opt/apache-maven-*/conf/settings.xml /home/canigo/.m2/settings.xml || die 7

chown -R canigo:canigo /home/canigo
