#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

log "Instal.lant $0 ..."

cd $(mktemp -d) ; pwd

curl -L https://sourceforge.net/projects/jedit/files/jedit/5.5.0/jedit5.5.0install.jar/download -o jedit-install.jar

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

cat<<EOF|java -jar jedit-install.jar text
/opt/jedit-5.5.0


y
y
y
EOF

log "Instal.lant plugins jedit ..."

su - canigo -c "jedit -nogui -noserver" 2>/dev/null

for plugin in SideKick-1.8-bin.zip Highlight-2.2-bin.zip Console-5.1.4-bin.zip CommonControls-1.7.4-bin.zip ErrorList-2.3-bin.zip Code2HTML-0.7-bin.zip Navigator-2.7-bin.zip ; do
    # curl -s -S -L  http://prdownloads.sourceforge.net/jedit-plugins/$plugin -o $plugin
    wget -nv  http://prdownloads.sourceforge.net/jedit-plugins/$plugin
    unzip $plugin -d /home/canigo/.jedit/jars
done

log "Configurant jedit ..."

# TODO

log "Instal.lat $0"
