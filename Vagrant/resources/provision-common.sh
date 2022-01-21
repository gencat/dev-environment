#!/usr/bin/env bash

function log () {
  echo "$(date "+%d-%m-%Y %H:%M:%S") ${0} [provision] ${*}"
}

function die () {
  log "[ERROR] ${*}. Exiting..."
  exit "${1}"
}

function _apt_get () {
  apt-get -q -y $@
}

function _wget () {
  wget -q -O "$@"
}

function _prepare_and_reboot () {
  log "Preparant següent fase (${1}) ..."

  cat > /provision.sh.crontab<<EOF
@reboot /provision.sh ${1} | tee /dev/tty0 | tee -a /provision.sh.log
EOF

  crontab /provision.sh.crontab

  log 'Rebooting...'

  # Petita pausa per poder veure els missatges
  sleep "${REBOOT_SLEEP:-10}"

  reboot
}

function _decompress () {
  [ -f "${1}" ] || die 1 "Fitxer ${1} no trobat"

  if [ "$( echo "${1}" | grep -E -q '\.tar\.gz$' ; echo $? )" -eq 0 ] ; then
    tar -xzvf "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.tar\.xz$' ; echo $? )" -eq 0 ] ; then
    tar -xJvf "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.tgz$' ; echo $? )" -eq 0 ] ; then
    tar -xzvf "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.zip$' ; echo $? )" -eq 0 ] ; then
    unzip "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.xz$' ; echo $? )" -eq 0 ] ; then
    unxz "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.bz$' ; echo $? )" -eq 0 ] ; then
    bzip2 -d "${1}"
  elif [ "$( echo "${1}" | grep -E -q '\.deb$' ; echo $? )" -eq 0 ] ; then
    apt install -y "${1}"
  else
    die 4 "Fitxer ${1} no reconegut"
  fi
}

function do_install () {
  local -r _BN=$(basename "${1}")

  log "Instal.lant ${_BN} ..."

  cd /opt || exit

  if [ -f "${_BN}" ]; then
    log "S'utilitza el fitxer $_BN present prèviament"
    _decompress "${_BN}" || die 2
  else
    wget -nv "${1}" || die 1
    _decompress "${_BN}" || die 3
    rm "${_BN}"
  fi

  log "Instal.lat ${_BN}"
}

# Fa un "page scrapping" d'una pàgina (normalment una pàgina de descàrrega) i descarrega un arxiu per a la seva instal·lació.
# @param 1: URL on cercar l'enllaç de descàrrega
# @param 2: REGEXP que ha de tenir l'enllaç de descàrrega
function do_install2 () {
  log "Accedint a ${1} ..."

  local -r __TMP=/tmp/do_install2-$$.html.tmp

  lynx -dump "${1}" > "${__TMP}" || die 1

  _URL=$(grep -E -o "${2}" $__TMP | grep -E '\.(zip|gz|tgz|xz|bz|bz2)$' | head -1)
  [ -z "${_URL}" ] && die 2

  do_install "${_URL}"
}

wait4jobs () {
  while true; do
    jobs >/dev/null
    jobs -r | wc -l | grep -q ^0 && break
    sleep 3
  done
}
