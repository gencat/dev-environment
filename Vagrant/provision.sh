#!/bin/bash

# DISABLE_VBOX_GUEST_ADD=1
# DISABLE_INSTALL_SOFTWARE=1
REBOOT_SLEEP=10
LOG_FILE=/vagrant/provision.sh.log

# https://unix.stackexchange.com/questions/146283/how-to-prevent-prompt-that-ask-to-restart-services-when-installing-libpq-dev
export DEBIAN_FRONTEND=noninteractive

pwd

. /vagrant/resources/provision-common.sh || exit 127

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

        mkdir -p /mnt/datadisk
        egrep '/mnt/datadisk|/dev/sdd1' /etc/fstab || echo '/dev/sdd1   /mnt/datadisk    ext4  rw,defaults,noatime,noacl,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500   0 0' >> /etc/fstab

        log 'Optimitzant FS ...'

        for feat in ^acl ^user_xattr  ; do
            tune2fs -o $feat /dev/sda1
            tune2fs -o $feat /dev/sdd1
        done
        tune2fs -o journal_data_writeback /dev/sdd1

        # /etc/fstab
        sed -ie 's/ext4\tdefaults/ext4\trw,defaults,noatime,noacl,nouser_xattr,commit=3600,delalloc/' /etc/fstab

        # optimització de SDA1 durant la instal·lació
        mount -o remount,rw,defaults,noatime,noacl,nouser_xattr,barrier=0,commit=3600,delalloc,max_batch_time=150000,min_batch_time=1500 /dev/sda1 /

        mount /mnt/datadisk
        mv /opt /opt.old
        mkdir -p /mnt/datadisk/opt
        ln -s /mnt/datadisk/opt /opt

        mv -t /opt /opt.old/*

        log 'Inicialitzat disc de dades'
    fi

    log 'Optimitzant sistema ...'

    systemctl stop apparmor
    systemctl disable apparmor

    apparmor_parser -R /etc/apparmor.d/* 2> /dev/null

    aa-status

    # FIX /tmp ha d'apuntar a /mnt/datadisk/tmp (principalment per temes d'espai)
    mkdir /mnt/datadisk/tmp
    chmod --reference /tmp /mnt/datadisk/tmp
    mv /tmp /tmp2 || die 1
    ln -s /mnt/datadisk/tmp /tmp || die 2

    echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT apparmor=0"'  | tee /etc/default/grub.d/apparmor.cfg
    # https://wiki.tizen.org/Security:Smack#How_to_disable_SMACK.3F
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT security=none"' | tee /etc/default/grub.d/security.cfg

    update-grub

    ufw disable

    apt update || die 3

    if [ ! "$DISABLE_VBOX_GUEST_ADD" = '1' ]; then

        # https://www.vagrantup.com/docs/virtualbox/boxes.html
        log 'Instal·lant de VirtualBox Guest Additions ...'

        _apt_get install linux-headers-$(uname -r) build-essential dkms || die 4

        VBOX_VERSION=$(VBoxService | head -1 | cut -f2 -d" " | cut -f1 -d_)

        log "Reported VirtualBox version : $VBOX_VERSION"

        wget -nv http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso || die 5
        mkdir /media/VBoxGuestAdditions
        mount -o loop,ro VBoxGuestAdditions_$VBOX_VERSION.iso /media/VBoxGuestAdditions
        echo yes | sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run --nox11
        rm VBoxGuestAdditions_$VBOX_VERSION.iso
        umount /media/VBoxGuestAdditions
        rmdir /media/VBoxGuestAdditions

        log 'Instal·lat VirtualBox Guest Additions'
    fi

    # https://www.techrepublic.com/article/how-to-disable-ipv6-on-linux/
    log 'Deshabilitant IPv6'

    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1

    log 'Creant user canigo ...'

    #Create canigo user
    useradd -m canigo
    echo canigo:canigo | /usr/sbin/chpasswd
    usermod -s /bin/bash canigo

    adduser canigo sudo
    adduser canigo vboxsf

    # Clonar grups de l'usuari ubuntu
    for f in `grep ubuntu /etc/group | grep -v canigo | cut -f1 -d: | grep -v ubuntu` ; do
        adduser canigo $f
    done

    # sudo sense password
    echo 'canigo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/canigo

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

    log 'Preparant instal·lació ...'

    apt update

    PACKAGE_INSTALL_LIST="visualvm"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST openjdk-8-jdk openjdk-8-source"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST libsvn-java"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST mysql-client-5.7 postgresql-client-10 mongodb-clients redis-tools"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST lubuntu-desktop xinit"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST language-pack-ca language-pack-gnome-ca language-pack-ca-base language-pack-gnome-ca-base"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST aspell-ca hunspell-ca firefox-locale-ca gnome-user-docs-ca wcatalan"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vpnc subversion"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST curl lynx links w3m"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST vim vim-syntax-docker"
    # PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST gimp gimp-help-ca"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST geany"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST google-chrome-stable"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST docker.io"
    PACKAGE_INSTALL_LIST="$PACKAGE_INSTALL_LIST apache2 libapache2-mod-auth-openid libapache2-mod-auth-openidc"

    log "Software base: $PACKAGE_INSTALL_LIST"

    # _apt_get install $PACKAGE_INSTALL_LIST && apt -y upgrade || die 1
    _apt_get install $PACKAGE_INSTALL_LIST || die 1

    # S'ha instal·lat com a dependència. S'elimina
    _apt_get remove openjdk-11-jre openjdk-11-jre-headless

    log 'Configurant "Timezone & Language"...'

    timedatectl set-timezone Europe/Madrid
    update-locale LANG=ca_ES.UTF-8 LC_MESSAGES=POSIX

    log 'Configurant aplicacions de sistema...'

    log 'Configurant Firefox...'

    # Per defecte Firefox (en comptes de Chrome)
    update-alternatives --set x-www-browser /usr/bin/firefox

    # Català per defecte per Firefox
    echo 'pref("intl.locale.requested", "ca,en-US-u-va-posix");' >> /etc/firefox/syspref.js

}

#
# Fase 3 de l'aprovisionament
#
fase3 () {

    log "Configuració de docker ..."

    #Add canigo user to docker group
    sudo gpasswd -a canigo docker || die 1
    sudo service docker restart

    log "Instal·lant docker-compose ..."

    # https://docs.docker.com/compose/install/
    curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version || die 2
    curl -L https://raw.githubusercontent.com/docker/compose/1.23.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

    # do_install https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || die 3
    do_install https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz || die 3
    do_install https://languagetool.org/download/LanguageTool-4.5.zip || die 3
    # do_install https://dbeaver.io/files/6.0.2/dbeaver-ce-6.0.2-linux.gtk.x86_64.tar.gz || die 3
    do_install https://sic.ctti.extranet.gencat.cat/nexus/content/groups/canigo-public-raw/dbeaver.io/files/6.0.2/dbeaver-ce-6.0.2-linux.gtk.x86_64.tar.gz || die 3
    do_install https://s3.amazonaws.com/downloads.eviware/soapuios/5.5.0/SoapUI-5.5.0-linux-bin.tar.gz || die 3
    do_install https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.1.1.tgz || die 3
    do_install https://archive.apache.org/dist/groovy/2.5.6/distribution/apache-groovy-binary-2.5.6.zip || die 3
    # do_install2 'http://groovy-lang.org/download.html' 'https://.*apache-groovy-binary-2.5.*' || die 3
    do_install https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.21/bin/apache-tomcat-9.0.21.tar.gz || die 3

    log 'Installing Node 8.x & 10.x versions ...'

    do_install https://nodejs.org/dist/v8.15.1/node-v8.15.1-linux-x64.tar.gz || die 3
    do_install https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.gz || die 3

    log 'Instal·lant VS Studio ...'

    snap install code --classic || die 4

    log 'Instal·lant software aprovisionat per script propi ...'

    for f in maven eclipse jedit ; do
        cd /tmp
        bash /vagrant/resources/$f/provision.sh || die 5 "$f"
    done

}

#
# Fase 4 de l'aprovisionament
#
fase4 () {

    # https://www.cyberciti.biz/faq/how-to-disable-ssh-motd-welcome-message-on-ubuntu-linux/
    /bin/ls -1 /etc/update-motd.d/* | grep -v 00-header | xargs chmod -x

cat>/etc/default/keyboard<<EOF
XKBMODEL="pc105"
XKBLAYOUT="es"
XKBVARIANT="cat"
XKBOPTIONS=""
BACKSPACE="guess"
EOF

    cd `dirname $0`
    sh /vagrant/resources/home_canigo/provision.sh || die 1

    log 'Actualizant permisos ...'

    chown -R canigo:canigo /mnt/datadisk/opt
    chmod o-rwx /mnt/datadisk/opt

    # autologin canigo
cat>/etc/lightdm/lightdm.conf.d/10-autologin.conf<<EOF
[Seat:*]
autologin-guest = false
autologin-user = canigo
autologin-user-timeout = 0

[SeatDefaults]
allow-guest = false
EOF

    log 'Deshabilitant actualitzacions automàtiques ...'

# https://linuxconfig.org/disable-automatic-updates-on-ubuntu-18-04-bionic-beaver-linux
cat>/etc/apt/apt.conf.d/20auto-upgrades<<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Disable (graphical) automatic updates
    for f in /usr/bin/update-manager /usr/bin/update-notifier ; do
        mv $f $f.bak
        ln -s /bin/true $f
    done

    log 'Auto-neteja...'

cat>/etc/cron.weekly/canigo.cleanup<<EOF
#!/bin/sh
#
# Auto-neteja setmanal

# Neteja de Snaps
snap list --all | grep desactivado | awk '{print \$1 "," \$3}' | for f in \`cat\` ; do __APP=\$(echo \$f | cut -f1 -d,); __REV=\$(echo \$f | cut -f2 -d,) ; echo \$__APP \$__REV ; snap remove \$__APP --revision \$__REV ; done

EOF
    chmod +x /etc/cron.weekly/canigo.cleanup

cat | crontab - <<EOF
# Neteja de /tmp (fitxers i directoris més antics de 10 minuts)
@reboot find -H /tmp -maxdepth 1 -cmin +10 -exec rm -fr '{}' ';'
EOF

    # Permisos més "amigables" per defecte
    printf '\numask 0002\n' >> /etc/bash.bashrc
}

#
# main
#
main () {

    # file version
	log "main :: $0 $(/bin/ls --full-time $0 | egrep -o ' [0-9]{4}[-0-9 :]+')  ($(md5sum $0|cut -f1 -d' '))" | tee -a $LOG_FILE

    echo "" > /dev/tty1

    log "FASE 1/4 :: Configuració inicial del sistema" | tee -a $LOG_FILE

    fase1 |& tee /dev/tty1 >> $LOG_FILE
    [ ${PIPESTATUS[0]} -eq 0 ] || die 1

    log "FASE 2/4 :: Instal·lació i configuració de software base" | tee -a $LOG_FILE

    fase2 |& tee /dev/tty1 >> $LOG_FILE
    [ ${PIPESTATUS[0]} -eq 0 ] || die 2

    log "FASE 3/4 :: Instal·lació i configuració de software addicional" | tee -a $LOG_FILE

    fase3 |& tee /dev/tty1 >> $LOG_FILE
    [ ${PIPESTATUS[0]} -eq 0 ] || die 3

    log "FASE 4/4 :: Configuració final del sistema" | tee -a $LOG_FILE

    fase4 |& tee /dev/tty1 >> $LOG_FILE
    [ ${PIPESTATUS[0]} -eq 0 ] || die 4

    sync

    log "Entorn de desenvolupament configurat. Aturant en 5 segons..." | tee -a $LOG_FILE

    uptime | tee -a $LOG_FILE

    sleep 5

    # exit 0

    poweroff
}

if [ $USER = "root" ] ; then
    main $*
else
    # sudo itself if not root
    sudo $0
fi
