#!/bin/sh

# update the system
apt-get update
apt-get upgrade

export LANGUAGE='ca_ES.UTF-8'
export LANG='ca_ES.UTF-8'
export LC_ALL='ca_ES.UTF-8'
locale-gen ca_ES.UTF-8
dpkg-reconfigure locales

#####################################################################################
# Set hostname, create canigo user and install utilities
#####################################################################################

hostname "CanigoDev"

#Create canigo user
useradd -m canigo
echo canigo:canigo | /usr/sbin/chpasswd
usermod -s /bin/bash canigo
adduser canigo sudo

# install utilities
apt-get install -y vim git zip bzip2 fontconfig curl language-pack-ca

################################################################################
# Install the graphical environment
################################################################################

timedatectl set-timezone Europe/Madrid

# force encoding
echo 'LANG=ca_ES.UTF-8' >> /etc/environment
echo 'LANGUAGE=ca_ES.UTF-8' >> /etc/environment
echo 'LC_ALL=ca_ES.UTF-8' >> /etc/environment
echo 'LC_CTYPE=ca_ES.UTF-8' >> /etc/environment

# run GUI as non-privileged user
echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config

# install Ubuntu desktop (XUbuntu) and VirtualBox guest tools
apt-get install -y xubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11

# remove light-locker
apt-get remove -y light-locker --purge

#Gencat customization
mkdir /home/canigo/Desktop
mkdir /home/canigo/Pictures

cp /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop_bck.xml
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/images/fonspantalla_1280.png -O /usr/share/xfce4/backdrops/canigo-wallpaper.png
sed -i -e 's/xubuntu-wallpaper.png/canigo-wallpaper.png/' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
#TODO: Change image-style to streched
#sed -i -e 's/<property name="image-style" type="int" value="5"/>/<property name="image-style" type="int" value="3"/>/' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/images/favicon.ico -O /home/canigo/Pictures/favicon.ico
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/documentacio-framework.desktop -O /home/canigo/Desktop/documentacio-framework.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/web-canigo.desktop -O /home/canigo/Desktop/web-canigo.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/jira.desktop -O /home/canigo/Desktop/jira.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/svn.desktop -O /home/canigo/Desktop/svn.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/jenkins.desktop -O /home/canigo/Desktop/jenkins.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/eclipse.desktop -O /home/canigo/Desktop/eclipse.desktop
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/launchers/LLEGEIX-ME.desktop -O /home/canigo/Desktop/LLEGEIX-ME.desktop

chmod +x /home/canigo/Desktop/*.desktop

chown canigo:canigo -R /home/canigo/Desktop
chown canigo:canigo -R /home/canigo/Pictures

################################################################################
# Install the development tools
################################################################################

# install Ubuntu Make - see https://wiki.ubuntu.com/ubuntu-make

add-apt-repository -y ppa:ubuntu-desktop/ubuntu-make

apt-get update
apt-get upgrade

apt install -y ubuntu-make

# install Chromium Browser
apt-get install -y chromium-browser

# install MySQL Workbench
apt-get install -y mysql-workbench

# install Guake
apt-get install -y guake
cp /usr/share/applications/guake.desktop /etc/xdg/autostart/

# install Java 8
echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list
echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886

apt-get update

echo oracle-java-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get install -y --force-yes oracle-java8-installer
update-java-alternatives -s java-8-oracle

# install Docker
curl -sL https://get.docker.io/ | sh
systemctl start docker
systemctl enable docker

# install docker compose
curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure docker group (docker commands can be launched without sudo)
usermod -aG docker canigo

#Install vpnc
apt-get -y install vpnc

#Eclipse
wget http://download.springsource.com/release/STS/3.8.3.RELEASE/dist/e4.6/spring-tool-suite-3.8.3.RELEASE-e4.6.2-linux-gtk-x86_64.tar.gz
tar -zxvf spring-tool-suite*.tar.gz
rm spring-tool-suite*.tar.gz
mv sts-bundle /opt/

#Splash image
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/images/splash.bmp -O /opt/sts-bundle/sts-3.8.3.RELEASE/plugins/org.eclipse.platform_4.6.2.v20161124-1400/splash.bmp
#Eclipse icon
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/images/icon.xpm -O /opt/sts-bundle/sts-3.8.3.RELEASE/icon.xpm
	
#Maven - Instal·lem Maven tot i que l'Eclipse utilitza la versió embedded. Si cal executar per linia de comandes es fara servir aquesta. Cal tenir en compte que no coincidiran exactament les versions.
apt-get -y install maven
#Settings de Maven
mkdir /home/canigo/.m2
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/maven/settings.xml -O /home/canigo/.m2/settings.xml
chown canigo:canigo -R /home/canigo/.m2

#Canigo 3.1.1 Plug-ins Feature 1.3.1
#TODO: New plugin version for Canigo 3.2
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://repos.canigo.ctti.gencat.cat/repository/maven2/cat/gencat/ctti/canigo.plugin/update-site/ -installIU cat.gencat.ctti.canigo.feature.feature.group

#JavaHL Library
apt-get -y install libsvn-java

#STS.ini
cp /opt/sts-bundle/sts-3.8.3.RELEASE/STS.ini /opt/sts-bundle/sts-3.8.3.RELEASE/STS.ini.bck
wget https://raw.githubusercontent.com/asamo7/dev-environment/master/resources/eclipse/STS.ini -O /opt/sts-bundle/sts-3.8.3.RELEASE/STS.ini

#Subversion plugin
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository https://dl.bintray.com/subclipse/releases/subclipse/4.2.x/ -installIU org.tigris.subversion.subclipse.feature.group
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository https://dl.bintray.com/subclipse/releases/subclipse/4.2.x/ -installIU org.tigris.subversion.clientadapter.javahl.feature.feature.group

#Docker Eclipse Plugin
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/linuxtools/update-docker -installIU org.eclipse.linuxtools.docker.feature.feature.group
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://download.eclipse.org/linuxtools/update-docker -installIU org.eclipse.linuxtools.docker.ui

#SonarQube Eclipse Plugin (Ref: http://docs.sonarqube.org/display/SONAR/Features+details#Featuresdetails-SonarQubeJavaConfigurationHelper)
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.feature.feature.group
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.jdt.feature.feature.group
/opt/sts-bundle/sts-3.8.3.RELEASE/STS -nosplash -application org.eclipse.equinox.p2.director -repository http://downloads.sonarsource.com/eclipse/eclipse/ -installIU org.sonar.ide.eclipse.m2e.feature.feature.group

# clean the box
apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove
dd if=/dev/zero of=/EMPTY bs=1M > /dev/null 2>&1
rm -f /EMPTY

#TODO: Keyboard & IBus preferences
# Menu -> Settings -> Xfce4 Settings Manager -> Keyboard -> Layout tab