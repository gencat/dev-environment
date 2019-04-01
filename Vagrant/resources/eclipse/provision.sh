#!/bin/bash

. ../provision-common.sh || exit 127

do_install https://download.springsource.com/release/STS4/4.1.2.RELEASE/dist/e4.10/spring-tool-suite-4-4.1.2.RELEASE-e4.10.0-linux.gtk.x86_64.tar.gz

log "Configurant Eclipse ..."

cd sts-* || die 1

#
# cp to multiple targets
#
multi_cp () {
    local SRC=$1
    shift
    /bin/ls -d $* | xargs -L1 cp -vfr $SRC
}

_RESOURCES=/tmp/resources/eclipse

multi_cp $_RESOURCES/splash.bmp ./plugins/org.eclipse.platform_*/splash.bmp ./plugins/org.springframework.boot.ide.branding_*/splash.bmp

cp -vfr $_RESOURCES/icon.xpm .

./SpringToolSuite4 -nosplash -application org.eclipse.equinox.p2.director -repository http://repos.canigo.ctti.gencat.cat/repository/maven2/cat/gencat/ctti/canigo.plugin/update-site/ -installIU cat.gencat.ctti.canigo.feature.feature.group

# cp find . -type f | grep '^./plugins/org.eclipse.platform_.*/splash.bmp'

# find . -type f -name splash.bmp | grep /org.eclipse.platform |
