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
    wget -nv $1 || die 1

    [ -f $_BN ] && echo $_BN | egrep '\.tar\.gz$' && tar -xzvf $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.tar\.xz$' && tar -xJvf $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.tgz$' && tar -xzvf $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.zip$' && unzip $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.xz$' && unxz $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.bz$' && bzip2 -d $_BN && rm $_BN
    [ -f $_BN ] && echo $_BN | egrep '\.deb$' && apt install $_BN && rm $_BN

    [ -f $_BN ] && die 2 'Fitxer no reconegut'

    log "Instal.lat $_BN"
}

# Fa un "page scrapping" d'una pàgina (normalment una pàgina de descàrrega) i descarrega un arxiu per a la seva instal·lació.
#
# @param 1
#       URL on cercar l'enllaç de descàrrega
# @param 2
#       REGEXP que ha de tenir l'enllaç de descàrrega
do_install2 () {

    log "Accedint a $1 ..."

    local __TMP=/tmp/do_install2-$$.html.tmp

    lynx -dump $1 > $__TMP || die 1

    _URL=$(egrep -o $2 $__TMP | egrep '\.(zip|gz|tgz|xz|bz|bz2)$' | head -1)
    [ -z $_URL ] && die 2

    do_install $_URL
}
