#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

do_install https://archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz

log "Configurant Maven ..."

cd /opt/apache-maven-* || die 1

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

_RESOURCES=/tmp/resources/maven
MVN_DIR=$PWD

cp -vfr $_RESOURCES/settings.xml ./conf/

su - canigo -c "$MVN_DIR/bin/mvn help:help clean:help war:help site:help deploy:help install:help compiler:help surefire:help failsafe:help eclipse:help"

cd $(mktemp -d) ; pwd
TEMPO_DIR=$PWD

chown canigo:canigo .

su - canigo -c "cd $TEMPO_DIR; $MVN_DIR/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DartifactId=AppCanigo -DgroupId=cat.gencat.ctti -Dversion=1.0"
