#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

cd /opt

# do_install https://download.springsource.com/release/STS4/4.2.0.RELEASE/dist/e4.11/spring-tool-suite-4-4.2.0.RELEASE-e4.11.0-linux.gtk.x86_64.tar.gz || die 1
do_install https://sic.ctti.extranet.gencat.cat/nexus/content/groups/canigo-public-raw/download.springsource.com/release/STS4/4.2.0.RELEASE/dist/e4.11/spring-tool-suite-4-4.2.0.RELEASE-e4.11.0-linux.gtk.x86_64.tar.gz || die 1

log "Configurant Eclipse ..."

cd sts-4.2* || die 2

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
    # wget -nv https://marketplace.eclipse.org/node/$MID/api/p || die 3
    wget -nv https://sic.ctti.extranet.gencat.cat/nexus/content/groups/canigo-public-raw/marketplace.eclipse.org/node/$MID/api/p || die 3

    UPDATE_URL=$(egrep -i '<updateurl.*</updateurl>' p | egrep -o '>[^<]+' | cut -c2-)
    PARAMS="-repository $UPDATE_URL"

    IUS=$(egrep '<iu.*</iu>' p | egrep -o '>[^<]+' | cut -c2-)
    rm p
    for iu in $IUS ; do
        PARAMS="$PARAMS -installIU $iu"
    done

    log "marketplace_install_cli $URL :: [$PARAMS]"

    ./SpringToolSuite4 -nosplash -application org.eclipse.equinox.p2.director $PARAMS || die 4
}

_RESOURCES=/vagrant/resources/eclipse

multi_cp $_RESOURCES/splash.bmp ./plugins/org.eclipse.platform_*/splash.bmp ./plugins/org.springframework.boot.ide.branding_*/splash.bmp

cp -vfr $_RESOURCES/icon.xpm .

./SpringToolSuite4 -nosplash -application org.eclipse.equinox.p2.director -repository 'http://repos.canigo.ctti.gencat.cat/repository/maven2/cat/gencat/ctti/canigo.plugin/update-site/' -installIU cat.gencat.ctti.canigo.feature.feature.group || die 5

# Sonarlint
marketplace_install_cli 'http://marketplace.eclipse.org/marketplace-client-intro?mpc_install=2568658' || die 6

# Per crear patch entre vanilla STS i pre-configurat
# diff -qr sts-4.2.0.RELEASE/ sts-4.2.0.RELEASE.new/ | grep -v 'Only in sts-4.2.0.RELEASE.new/' | sed -e 's: and.*::' -e 's:^.* sts-:sts-:' -e 's@: @/@' > sts-diff.lst
# tar -cvJf eclipse-conf-patch.tar.xz -T sts-diff.lst
# Segon patch
# rm -fr /tmp/t5 ; mkdir /tmp/t5 ; diff -qr sts-4.2.0.RELEASE/ sts-4.2.0.RELEASE.new/ | sed -Ene 's/Only in (.*): (.*)/\1\/\2/p' -e 's/.* (.*) differ/\1/p' | xargs cp --parents -rt /tmp/t5
# mv /tmp/t5/sts-4.2.0.RELEASE.new/ /tmp/t5/sts-4.2.0.RELEASE
# cd /tmp/t5 ; tar -cvJf eclipse-conf-patch2.tar.xz sts-4.2.0.RELEASE

for f in eclipse-conf-patch.tar.xz workspaces.tar.xz eclipse-conf-patch2.tar.xz ; do
    log "Treballant amb l'arxiu $f ..."
    tar -xJf $_RESOURCES/$f -C /opt
done

# WARNING :: Si hi ha canvis de la ruta del WORKSPACE s'ha de canviar també a /resources/home_canigo/provision.sh
