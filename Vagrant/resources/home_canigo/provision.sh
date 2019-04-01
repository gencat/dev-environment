#!/bin/bash

. ../provision-common.sh || exit 127

log "Configurant usuari canigo ..."

# rm -fr /home/canigo || die 1
# mkdir -p /home/canigo && cd /home/canigo || die 2

cd /home || die 2
tar -xvJf /vagrant/resources/home_canigo/init.tar.xz --overwrite || die 3

_RESOURCES=/tmp/resources/home_canigo/resources

cp -vfr $_RESOURCES/* /home/canigo

chown -R canigo:canigo /home/canigo
