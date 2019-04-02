#!/bin/bash

# DISABLE_VBOX_GUEST_ADD=1
# DISABLE_INSTALL_SOFTWARE=1
REBOOT_SLEEP=10
LOG_FILE=/tmp/vagrant/provision.sh.log

. ./resources/provision-common.sh || exit 127

#
# Fase 1 de l'aprovisionament
#
fase1 () {

    log 'Inicialitzant swap ...'

cat<<EOF|fdisk /dev/sdc
n
p



t
82
p
w
EOF

    mkswap /dev/sdc1
    swapon /dev/sdc1
    echo '/dev/sdc1   none    swap sw,discard=once    0 0' >> /etc/fstab

    if [ ! "$DISC_DADES_INIT_SKIP" = '1' ]; then

        log 'Inicialitzant disc de dades ...'

cat<<-EOF|fdisk /dev/sdd
n
p



p
w
EOF

        #yes | mkfs.ext4 -T small -m0 /dev/sdd1
        yes | mkfs.ext4 -m0 /dev/sdd1

        egrep '/opt|/dev/sdd1' /etc/fstab || echo '/dev/sdd1   /opt    ext4  rw,defaults,noatime,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500   0 0' >> /etc/fstab

        log 'Optimitzant FS ...'

        for feat in ^acl ^user_xattr  ; do
            tune2fs -o $feat /dev/sda1
            tune2fs -o $feat /dev/sdd1
        done
        tune2fs -o journal_data_writeback /dev/sdd1

        # /etc/fstab
        sed -ie 's/ext4\tdefaults/ext4\trw,defaults,noatime,nouser_xattr,commit=3600,delalloc/' /etc/fstab

        # optimització de SDA1 durant la instal·lació
        mount -o remount,rw,defaults,noatime,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500 /dev/sda1 /

        mount /opt

        log 'Inicialitzat disc de dades'
    fi

    log 'Optimitzant seguretat ...'

    systemctl stop apparmor
    systemctl disable apparmor

    aa-status

    echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT apparmor=0"'  | tee /etc/default/grub.d/apparmor.cfg
    # https://wiki.tizen.org/Security:Smack#How_to_disable_SMACK.3F
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT security=none"' | tee /etc/default/grub.d/security.cfg

    update-grub

    ufw disable

    if [ ! "$DISABLE_VBOX_GUEST_ADD" = '1' ]; then

        # https://www.vagrantup.com/docs/virtualbox/boxes.html
        log 'Instal·lant de VirtualBox Guest Additions ...'

        _apt_get install linux-headers-$(uname -r) build-essential dkms

        VBOX_VERSION=$(VBoxService | head -1 | cut -f2 -d" " | cut -f1 -d_)

        log "Reported VirtualBox version : $VBOX_VERSION"

        wget -nv http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
        mkdir /media/VBoxGuestAdditions
        mount -o loop,ro VBoxGuestAdditions_$VBOX_VERSION.iso /media/VBoxGuestAdditions
        echo yes | sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run --nox11
        rm VBoxGuestAdditions_$VBOX_VERSION.iso
        umount /media/VBoxGuestAdditions
        rmdir /media/VBoxGuestAdditions

        log 'Instal·lat VirtualBox Guest Additions'
    fi

    log 'Creant user canigo ...'

    #Create canigo user
    useradd -m canigo
    echo canigo:canigo | /usr/sbin/chpasswd
    usermod -s /bin/bash canigo

    adduser canigo sudo

    # Clonar grups de l'usuari ubuntu
    for f in `grep ubuntu /etc/group | grep -v canigo | cut -f1 -d: | grep -v ubuntu` ; do
        adduser canigo $f
    done

    log 'Creat user canigo'
}

#
# Fase 2 de l'aprovisionament
#
fase2 () {

    log 'Afegint nous repositoris ...'

    _apt_get install software-properties-common
    #add-apt-repository -y ppa:webupd8team/java

    if [ ! -e /etc/apt/sources.list.d/google.list ]; then
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
    fi

    apt update

    log 'Preparant instal·lació ...'

    PACKAGE_INSTALL_LIST="visualvm"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST openjdk-8-jdk openjdk-8-source"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST libsvn-java"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST mysql-client-5.7 postgresql-client-10 mongodb-clients redis-tools"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST lubuntu-desktop xinit"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST language-pack-ca language-pack-gnome-ca language-pack-ca-base language-pack-gnome-ca-base"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vpnc subversion"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST curl lynx links w3m"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vim vim-syntax-docker"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST gimp"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST geany"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST google-chrome-stable"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST docker.io"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST apache2 libapache2-mod-auth-openid libapache2-mod-auth-openidc"

    log "Software base: $PACKAGE_INSTALL_LIST"

    _apt_get install $PACKAGE_INSTALL_LIST && apt -y upgrade || die 5

    log 'Configurant "Timezone & Language"...'

    timedatectl set-timezone Europe/Madrid
    update-locale LANG=ca_ES.UTF-8 LC_MESSAGES=POSIX

    log 'Configurant aplicacions de sistema...'

    # Per defecte Firefox (en comptes de Chrome)
    update-alternatives --set x-www-browser /usr/bin/firefox

cat>/etc/lightdm/lightdm.conf.d/10-autologin.conf<<EOF
[Seat:*]
autologin-guest = false
autologin-user = canigo
autologin-user-timeout = 0

[SeatDefaults]
allow-guest = false
EOF

}

#
# Fase 3 de l'aprovisionament
#
fase3 () {

    log "Configuració de docker ..."

    #Add canigo user to docker group
    sudo gpasswd -a canigo docker || die 6
    sudo service docker restart

    log "Instal·lant docker-compose ..."

    # https://docs.docker.com/compose/install/
    curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version || die 7
    curl -L https://raw.githubusercontent.com/docker/compose/1.23.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

    do_install https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
    do_install https://dbeaver.io/files/6.0.1/dbeaver-ce-6.0.1-linux.gtk.x86_64.tar.gz
    do_install https://s3.amazonaws.com/downloads.eviware/soapuios/5.5.0/SoapUI-5.5.0-linux-bin.tar.gz
    do_install https://www-eu.apache.org/dist//jmeter/binaries/apache-jmeter-5.1.1.tgz
    do_install https://www-eu.apache.org/dist/groovy/2.5.6/distribution/apache-groovy-binary-2.5.6.zip

    log 'Installing Node 8.x & 10.x versions ...'

    do_install https://nodejs.org/dist/v8.15.1/node-v8.15.1-linux-x64.tar.gz
    do_install https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.gz

    # Postman no instal·lat per no tenir llicència aplicable

    # log 'Instal.lant Postman ...'

    # cd /opt
    # wget -nv https://dl.pstmn.io/download/latest/linux64
    # tar -xzf linux64
    # rm linux64

    log 'Instal·lant VS Studio ...'

    # page scrapping "d'anar per casa"

    cd $(mktemp -d) ; pwd
    lynx -dump https://code.visualstudio.com/docs/setup/linux | fgrep '/go.microsoft.com/fwlink/?LinkID=' | cut -f3- -d' ' | for f in `cat`; do
        wget -nv $f
    done

    for f in `file * | fgrep 'Debian binary package' | cut -f1 -d:` ; do
        mv $f vs-code.deb && apt install ./vs-code.deb
    done

    log 'Instal·lant software aprovisionat per script propi ...'

    for f in maven eclipse jedit ; do
        cd `dirname $0`
        sh resources/$f/provision.sh
    done

}

#
# Fase 4 de l'aprovisionament
#
fase4 () {

    cd `dirname $0`
    sh resources/home_canigo/provision.sh

    log 'Actualizant permisos ...'

    chown -R canigo:canigo /opt
}

#
# main
#
main () {

    # file version
	log "main :: $0 $(/bin/ls --full-time $0 | egrep -o ' [0-9]{4}[-0-9 :]+')  ($(md5sum $0|cut -f1 -d' '))"

    echo "" > /dev/tty1

    log "FASE 1/4 :: Configuració inicial del sistema"

    fase1 |& tee /dev/tty1 >> $LOG_FILE || die 1

    log "FASE 2/4 :: Instal·lació i configuració de software base"

    fase2 |& tee /dev/tty1 >> $LOG_FILE || die 2

    log "FASE 3/4 :: Instal·lació i configuració de software addicional"

    fase3 |& tee /dev/tty1 >> $LOG_FILE || die 3

    log "FASE 4/4 :: Configuració final del sistema"

    fase4 |& tee /dev/tty1 >> $LOG_FILE || die 4

    sync

    log "Entorn de desenvolupament configurat. Reiniciant en 5 segons..."

    sleep 5

    #reboot

    exit 0
#
#
#
    crontab -r
    touch /provision.sh.log

    [ -z "$1" -o "$1" = "fase1" ] && fase1 | tee -a /provision.sh.log
    [ "$1" = "fase2" ] && fase2

_exit 0

    $1



    #Wallpaper
    sudo cp /usr/share/lubuntu/wallpapers/1604-lubuntu-default-wallpaper.png /usr/share/lubuntu/wallpapers/1604-lubuntu-default-wallpaper_bck.png
    sudo yes | cp -rf /tmp/resources/fonspantalla_1280.png /usr/share/lubuntu/wallpapers/1604-lubuntu-default-wallpaper.png
    sudo cp /usr/share/lubuntu/wallpapers/1604-lubuntu-default-wallpaper.png /usr/share/lubuntu/wallpapers/lubuntu-default-wallpaper.png

    #Desktop shortcuts
    sudo yes | cp -rf /tmp/resources/favicon.ico /home/canigo/Pictures/favicon.ico
    sudo yes | cp -rf /tmp/resources/documentacio-framework.desktop /home/canigo/Desktop/documentacio-framework.desktop
    sudo yes | cp -rf /tmp/resources/web-canigo.desktop /home/canigo/Desktop/web-canigo.desktop
    sudo yes | cp -rf /tmp/resources/jira.desktop /home/canigo/Desktop/jira.desktop
    sudo yes | cp -rf /tmp/resources/git.desktop /home/canigo/Desktop/git.desktop
    sudo yes | cp -rf /tmp/resources/jenkins.desktop /home/canigo/Desktop/jenkins.desktop
    sudo yes | cp -rf /tmp/resources/eclipse.desktop /home/canigo/Desktop/eclipse.desktop
    sudo yes | cp -rf /tmp/resources/LLEGEIX-ME.desktop /home/canigo/Desktop/LLEGEIX-ME.desktop
    sudo chown canigo:canigo -R /home/canigo/Desktop
    sudo chown canigo:canigo -R /home/canigo/Pictures

    #
    #Eclipse
    #

    echo "Installing Eclipse..."
    sudo rm -fr /opt/sts-bundle spring-tool-suite*.tar.gz 2> /dev/null
    sudo _wget http://dist.springsource.com/release/STS/3.7.1.RELEASE/dist/e4.5/spring-tool-suite-3.7.1.RELEASE-e4.5.1-linux-gtk-x86_64.tar.gz
    sudo tar -zxvf spring-tool-suite*.tar.gz
    sudo rm spring-tool-suite*.tar.gz
    sudo mv sts-bundle /opt/

    #Splash image
    sudo yes | cp -rf /tmp/resources/splash.bmp /opt/sts-bundle/sts-3.7.1.RELEASE/plugins/org.eclipse.platform_4.5.1.v20150904-0015/splash.bmp

    #Eclipse icon
    sudo yes | cp -rf /tmp/resources/icon.xpm /opt/sts-bundle/sts-3.7.1.RELEASE/icon.xpm

    #Maven - Instal·lem Maven tot i que l'Eclipse utilitza la versió embedded. Si cal executar per linia de comandes es fara servir aquesta. Cal tenir en compte que no coincidiran exactament les versions.
    sudo _apt_get -y install maven

    #Settings de Maven
    echo "Configuring Maven..."
    sudo mkdir /home/canigo/.m2
    sudo yes | cp -rf /tmp/resources/maven_settings/settings.xml /home/canigo/.m2/settings.xml
    sudo chown canigo:canigo -R /home/canigo/.m2

    #Canigo 3.1.1 Plug-ins Feature 1.3.1
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://repos.canigo.ctti.gencat.cat/repository/maven2/cat/gencat/ctti/canigo.plugin/update-site/ -installIU cat.gencat.ctti.canigo.feature.feature.group

    #Patch Maven Embedder Plugin
    sudo yes | cp -rf /tmp/resources/patch_plugin_canigo/maven-embedder-3.3.3.jar /opt/sts-bundle/sts-3.7.1.RELEASE/plugins/org.eclipse.m2e.maven.runtime_1.6.2.20150902-0001/jars/maven-embedder-3.3.3.jar

    #JavaHL Library
    sudo _apt_get -y install libsvn-java

    #STS.ini
    sudo yes | cp -rf /tmp/resources/STS.ini /opt/sts-bundle/sts-3.7.1.RELEASE/STS.ini

    #Subversion plugin (1.12.x)
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository https://dl.bintray.com/subclipse/archive/release/1.12.x/ -installIU org.tigris.subversion.subclipse.feature.group
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository https://dl.bintray.com/subclipse/archive/release/1.12.x/ -installIU org.tigris.subversion.clientadapter.feature.feature.group
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository https://dl.bintray.com/subclipse/archive/release/1.12.x/ -installIU org.tigris.subversion.clientadapter.javahl.feature.feature.group

    #TODO: Docker Eclipse Plugin (Desactivat. Cal actualitzar la versio d'Eclipse, no es resol la dependencia amb org.eclipse.e4.ui.workbench v1.4.0, Eclipse Mars incorpora la 1.3.0. Es tornara a activar a la v2.0.0 de l'entorn de DEV)
    #/opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/linuxtools/updates-docker-nightly/ -installIU org.eclipse.linuxtools.docker.feature.feature.group

    #SonarQube Eclipse Plugin (Ref: http://docs.sonarqube.org/display/SONAR/Features+details#Featuresdetails-SonarQubeJavaConfigurationHelper)
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.feature.feature.group
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.jdt.feature.feature.group
    /opt/sts-bundle/sts-3.7.1.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.m2e.feature.feature.group

    # p2.tar.gz inhabilita tots els "Update sites" excepte el del plugin de Canigó
    sudo rm -fr /opt/sts-bundle/sts-3.7.1.RELEASE/p2
    sudo tar -xzf /tmp/resources/eclipse/p2.tar.gz
    sudo mv p2 /opt/sts-bundle/sts-3.7.1.RELEASE/

    sudo chown canigo:canigo -R /opt/*

    #Install vpnc
    sudo _apt_get -y install vpnc

    #Remove light-locker
    sudo _apt_get -y remove light-locker

    echo "Provisioning completed. Please restart VM"
}

if [ $USER = "root" ] ; then
    main $*
else
    # sudo itself if not root
    sudo $0
fi
