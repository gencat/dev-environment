#!/usr/bin/env bash

# shellcheck disable=SC1091
source /vagrant/resources/provision-common.sh || exit 127

# do_install https://archive.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
do_install https://sic.ctti.extranet.gencat.cat/nexus/content/groups/canigo-public-raw/archive.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz || die 1

log "Configurant Maven ..."

cd /opt/apache-maven-* || die 2

update-alternatives --install /usr/bin/mvn mvn /opt/apache-maven-3.8.3/bin/mvn 100

declare -r _RESOURCES=/vagrant/resources/maven

cp -vfr "${_RESOURCES}/settings.xml" ./conf/

# To get mvn plugin help and check settings
#su - canigo -c "mvn help:help clean:help war:help site:help deploy:help install:help compiler:help surefire:help failsafe:help eclipse:help"

cd "$(mktemp -d)" || exit ; pwd
declare -r TEMPO_DIR=$PWD

cat<<EOF > "${TEMPO_DIR}"/mvn-run.sh

# https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/net/doc-files/net-properties.html
export MAVEN_OPTS="-Djava.net.preferIPv4Stack=true -Dsun.net.client.defaultConnectTimeout=60000 -Dsun.net.client.defaultReadTimeout=30000"

cd ${TEMPO_DIR};

mvn -B archetype:generate \
  -DarchetypeGroupId=cat.gencat.ctti \
  -DarchetypeArtifactId=plugin-canigo-archetype-rest \
  -DarchetypeVersion=LATEST \
  -DartifactId=AppCanigo \
  -DgroupId=cat.gencat.ctti \
  -Dversion=1.0

cd AppCanigo

mvn -B clean package failsafe:integration-test
mvn -B dependency:resolve -Dclassifier=sources
mvn -B dependency:resolve -Dclassifier=javadoc
EOF

chown -R canigo:canigo "${TEMPO_DIR}"

su - canigo -c "bash ${TEMPO_DIR}/mvn-run.sh || true"
