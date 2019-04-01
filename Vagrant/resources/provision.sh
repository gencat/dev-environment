#!/bin/bash

# DISABLE_VBOX_GUEST_ADD=1
# DISABLE_INSTALL_SOFTWARE=1

log () {
    echo "$(date "+%d-%m-%Y %H:%M:%S") [provision] $*" | tee -a /provision.sh.log
}

_exit () {

    log '(Exit clean-up)'

    crontab -d
    rm /provision.sh

    exit $1
}

die () {
    log "[ERROR] $*. Exiting..."
    _exit 1
}

_apt_get () {
    apt-get -q -y $*
}

_wget () {
    wget -q -O $*
}

#
# Fase 1 de l'aprovisionament
#
fase1 () {

	log "FASE 1/4 :: Canvis de la configuració per defecte del sistema"

    log 'Optimitzant FS ...'

    for feat in ^acl ^user_xattr journal_data_writeback ; do
        tune2fs -o $feat /dev/sda1
    done

    # /etc/fstab
    sed -ie 's/ext4\tdefaults/ext4\tdefaults,rw,noatime,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500/' /etc/fstab
    # mount -o remount,defaults,rw,noatime,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500 /dev/sda1 /

    DO_UPDATE_GRUB=0
    aa-status
    if [ $? -eq 0 ] ; then

        log 'Disabling AppArmor ...'

        systemctl stop apparmor
        systemctl disable apparmor

        aa-status

        echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT apparmor=0"'  | tee /etc/default/grub.d/apparmor.cfg

        DO_UPDATE_GRUB=1
    fi

    log 'Disabled AppArmor'

    ufw disable | grep -q 'Status: inactive'
    if [ $? -eq 0 ] ; then

        log 'Disabling security ...'

        # https://wiki.tizen.org/Security:Smack#How_to_disable_SMACK.3F
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT security=none"' | tee /etc/default/grub.d/security.cfg

        DO_UPDATE_GRUB=1
    fi

    [ $DO_UPDATE_GRUB -eq 1 ] && update-grub

    log 'Disabled security'

    log 'Preparant següent fase ...'

    cp $0 /provision.sh

cat > /provision.sh.crontab<<EOF
@reboot /provision.sh fase2 > /dev/tty0
EOF

    crontab /provision.sh.crontab

    reboot
}

#
# Fase 2 de l'aprovisionament
#
fase2 () {

	log "FASE 2/4 :: Configuració "

    if [ ! "$DISABLE_VBOX_GUEST_ADD" = '1' ]; then

        # https://www.vagrantup.com/docs/virtualbox/boxes.html
        log 'Installing VirtualBox Guest Additions ...'

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

        log 'Installed VirtualBox Guest Additions'
    fi

    egrep -q '^sudo:.*canigo' /etc/group
    if [ $? -ne 0 ] ; then

        log 'Creating user canigo ...'

        #Create canigo user
        useradd -m canigo
        echo canigo:canigo | /usr/sbin/chpasswd
        usermod -s /bin/bash canigo
        adduser canigo sudo
    fi

    log 'Created user canigo'

    if [ -z $DISABLE_VBOX_GUEST_ADD ]; then

        log 'Installing new software ...'

    fi

    log 'Preparant següent fase ...'

cat > /provision.sh.crontab<<EOF
@reboot /provision.sh fase3 > /dev/tty0
EOF

    crontab /provision.sh.crontab

    reboot
}

main () {

    # file version
	log "main :: $0 $(/bin/ls --full-time $0 | egrep -o ' [0-9]{4}[-0-9 :]+')  ($(md5sum $0|cut -f1 -d' '))"

    crontab -r

    [ -z "$1" -o "$1" = "fase1" ] && fase1
    [ "$1" = "fase2" ] && fase2

exit 0

    pushd .

#    log 'Removing automatic start-up apps ...'
#
#    for app in apparmor ; do
#        find /etc -type d -name "rc*" -exec find '{}' -name "*$app*" ';' | xargs rm
#    done


    if [ ! -e /etc/apt/sources.list.d/google.list ]; then

        log "Adding new repositories..."

# die 100 'TODO /etc/apt/sources.list.d/*'

        _apt_get install software-properties-common
        add-apt-repository -y ppa:webupd8team/java
        _wget - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

        apt update
    fi

    log 'Preparing apt pakage install list ...'

    # 'Java 8 & 11 versions'

    PACKAGE_INSTALL_LIST="visualvm"
    for v in 8 11 ; do
        PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST openjdk-$v-jdk openjdk-$v-source"
    done

    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST "
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST mariadb-client-10.1 mysql-client-5.7 postgresql-client-10 mongodb-clients redis-tools"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST lubuntu-desktop xinit"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vpnc subversion"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST curl lynx links w3m"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vim vim-syntax-docker"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST gpaint gimp gimp-gap"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST google-chrome-stable"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST docker.io"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST apache2 libapache2-mod-auth-openid libapache2-mod-auth-openidc "

    log "Software to install: $PACKAGE_INSTALL_LIST"

exit 0

    _apt_get install $PACKAGE_INSTALL_LIST

    #export JAVA_HOME="/usr/lib/jvm/java-8-oracle/jre"

    #Docker and compose
    echo "Installing Docker..."
    _wget - https://get.docker.com/ | sh
    #_apt_get install -y docker.io
    systemctl start docker
    systemctl enable docker
    curl -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` > docker-compose && chmod +x docker-compose && mv docker-compose /usr/local/bin/
    curl -L https://raw.githubusercontent.com/docker/compose/1.17.1/contrib/completion/bash/docker-compose > docker-compose && mv docker-compose /etc/bash_completion.d

    #Add canigo user to docker group
    sudo gpasswd -a canigo docker
    sudo service docker restart

    #Timezone, Language
    echo "Configuring Timezone & Language..."
    sudo timedatectl set-timezone Europe/Madrid
    sudo _apt_get install -y language-pack-ca language-pack-gnome-ca language-pack-ca-base language-pack-gnome-ca-base xinit
    sudo update-locale LANG=ca_ES.UTF-8 LC_MESSAGES=POSIX

    #Gencat customization
    echo "Gencat customization..."
    sudo mkdir /home/canigo/Desktop
    sudo mkdir /home/canigo/Pictures

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
