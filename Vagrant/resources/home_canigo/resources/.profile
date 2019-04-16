# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# afegir al PATH groovy i apache
for f in `/bin/ls -d /opt/groovy* /opt/apache*` ; do
    export PATH="$f/bin:$PATH"
done

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export GIT_SSH=/usr/bin/ssh
export GIT_EDITOR="vim"

export JAVA_HOME8=/usr/lib/jvm/java-8-openjdk-amd64
export JAVA_HOME11=/opt/jdk-11.0.2
export JAVA_HOME=$JAVA_HOME8

# export JAVA_OPTS="-verbose:gc"
export JAVA_OPTS="$JAVA_OPTS -Xms256m -Xmx1024m"

export NODE_V8=/opt/node-v8.15.1-linux-x64
export NODE_V10=/opt/node-v10.15.3-linux-x64

# MAVEN
export M2_HOME=/opt/apache-maven*
export MAVEN_HOME=$M2_HOME

