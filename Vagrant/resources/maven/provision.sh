#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

do_install https://archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz

log "Configurant Maven ..."

cd /opt/apache-maven-* || die 1

export MAVEN_HOME=$PWD
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

_RESOURCES=/vagrant/resources/maven

cp -vfr $_RESOURCES/settings.xml ./conf/

# su - canigo -c "$MAVEN_HOME/bin/mvn help:help clean:help war:help site:help deploy:help install:help compiler:help surefire:help failsafe:help eclipse:help"

cd $(mktemp -d) ; pwd
TEMPO_DIR=$PWD

cat<<EOF>$TEMPO_DIR/mvn-run.sh
export MAVEN_OPTS="-Djava.net.preferIPv4Stack=true -Dsun.net.client.defaultConnectTimeout=60000 -Dsun.net.client.defaultReadTimeout=30000"

cd $TEMPO_DIR;

$MAVEN_HOME/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DartifactId=AppCanigo -DgroupId=cat.gencat.ctti -Dversion=1.0
$MAVEN_HOME/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DarchetypeVersion=1.6.2 -DartifactId=AppCanigo162 -DgroupId=cat.gencat.ctti -Dversion=1.0

cd $TEMPO_DIR/AppCanigo;
$MAVEN_HOME/bin/mvn -B clean package failsafe:integration-test
EOF

chown -R canigo:canigo $TEMPO_DIR

su - canigo -c "bash $TEMPO_DIR/mvn-run.sh"

# su - canigo -c "cd $TEMPO_DIR; $MAVEN_HOME/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DartifactId=AppCanigo -DgroupId=cat.gencat.ctti -Dversion=1.0"
# su - canigo -c "cd $TEMPO_DIR; $MAVEN_HOME/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DarchetypeVersion=1.6.2 -DartifactId=AppCanigo162 -DgroupId=cat.gencat.ctti -Dversion=1.0"
# su - canigo -c "cd $TEMPO_DIR/AppCanigo; $MAVEN_HOME/bin/mvn -B clean package failsafe:integration-test"
