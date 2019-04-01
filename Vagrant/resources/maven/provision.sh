#!/bin/bash

. ../provision-common.sh || exit 127

do_install https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz

log "Configurant Maven ..."

cd /opt/apache-maven-* || die 1

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

_RESOURCES=/tmp/resources/maven

cp -vfr $_RESOURCES/settings.xml ./conf/

su - canigo -c "$PWD/bin/mvn help:help clean:help war:help site:help deploy:help install:help compiler:help surefire:help failsafe:help eclipse:help"
