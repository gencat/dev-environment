#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

cd /opt

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

#
# @param 1 URL
# @see https://stackoverflow.com/a/52887282/97799
#
marketplace_install_cli () {

    URL=$1
    MID=$(echo $URL | egrep -o '=[0-9]+$' | cut -f2 -d=)

    rm p 2>/dev/null
    wget -nv https://marketplace.eclipse.org/node/$MID/api/p

    UPDATE_URL=$(egrep -i '<updateurl.*</updateurl>' p | egrep -o '>[^<]+' | cut -c2-)
    PARAMS="-repository $UPDATE_URL"

    IUS=$(egrep '<iu.*</iu>' p | egrep -o '>[^<]+' | cut -c2-)
    rm p
    for iu in $IUS ; do
        PARAMS="$PARAMS -installIU $iu"
    done

    log "marketplace_install_cli $URL :: [$PARAMS]"

    ./SpringToolSuite4 -nosplash -application org.eclipse.equinox.p2.director $PARAMS
}

_RESOURCES=/vagrant/resources/eclipse

multi_cp $_RESOURCES/splash.bmp ./plugins/org.eclipse.platform_*/splash.bmp ./plugins/org.springframework.boot.ide.branding_*/splash.bmp

cp -vfr $_RESOURCES/icon.xpm .

./SpringToolSuite4 -nosplash -application org.eclipse.equinox.p2.director -repository 'http://repos.canigo.ctti.gencat.cat/repository/maven2/cat/gencat/ctti/canigo.plugin/update-site/' -installIU cat.gencat.ctti.canigo.feature.feature.group

# Sonarlint
marketplace_install_cli 'http://marketplace.eclipse.org/marketplace-client-intro?mpc_install=2568658'

# Per crear patch entre vanilla STS i pre-configurat
# diff -qr sts-4.1.2.RELEASE/ sts-4.1.2.RELEASE.new/ | grep -v 'Only in sts-4.1.2.RELEASE.new/' | sed -e 's: and.*::' -e 's:^.* sts-:sts-:' -e 's@: @/@' > sts-diff.lst
# tar -cvJf eclipse-conf-patch.tar.xz -T sts-diff.lst

tar -xvJf $_RESOURCES/eclipse-conf-patch.tar.xz -C /opt
tar -xvJf $_RESOURCES/workspaces.tar.xz -C /opt
