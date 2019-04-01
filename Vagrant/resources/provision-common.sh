### sourced

log () {
    echo "$(date "+%d-%m-%Y %H:%M:%S") $0 [provision] $*"
}

die () {
    log "[ERROR] $*. Exiting..."
    exit $1
}

_apt_get () {
    apt-get -q -y $*
}

_wget () {
    wget -q -O $*
}

_prepare_and_reboot () {

    log "Preparant següent fase ($1) ..."

cat > /provision.sh.crontab<<EOF
@reboot /provision.sh $1 | tee /dev/tty0 | tee -a /provision.sh.log
EOF

    crontab /provision.sh.crontab

    log 'Rebooting...'

    # Petita pausa per poder veure els missatges
    sleep $REBOOT_SLEEP

    reboot
}

do_install () {

    _BN=$(basename $1)

    log "Instal.lant $_BN ..."

    cd /opt
    wget -nv $1

    echo $_BN | egrep '\.tar\.gz$' && tar -xzvf $_BN
    echo $_BN | egrep '\.tar\.xz$' && tar -xJvf $_BN
    echo $_BN | egrep '\.tgz$' && tar -xzvf $_BN
    echo $_BN | egrep '\.zip$' && unzip $_BN

    rm $_BN

    log "Instal.lat $_BN"
}
