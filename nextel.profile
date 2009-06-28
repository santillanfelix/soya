#!/bin/sh 
# vim: set ts=2 sw=2 sts=2 et si ai: 

# nextel.profile -- profile unix de aplicaciones
# ----------------------------------------------------------------------------
# (c) 2009 Nextel de México S.A. de C.V.
# Andrés Aquino Morales <andres.aquino@gmail.com>
# All rights reserved.
# 

# input mode
set -o vi
umask 0007

# terminal line settings
stty 2> /dev/null > /dev/null 
if [ "$?" = "0" ]
then
   stty erase '^?'
   stty intr '^C' 
   stty kill '^U' 
   stty stop '^S'
   stty susp '^Z'
   stty werase '^W'
   
   # command line _eye candy_
   CCLEAR="\033[00m"; CWHITE="\033[01;37m"
   CRED="\033[01;31m"; CYELLOW="\033[01;33m"
   CBLUE="\033[01;34m"; CGRAY="\033[01;30m"
else
   # command line _eye candy_
   CCLEAR=""; CWHITE=""
   CRED=""; CYELLOW=""
   CBLUE=""; CGRAY=""
fi

# functions
java15 () {
   PATH=/opt/java1.5/bin:${LOCALPATH}
}

java14 () {
   PATH=/opt/java1.4/bin:${LOCALPATH}
}

java13 () {
   PATH=/opt/java1.3/bin:${LOCALPATH}
}

java12 () {
   PATH=/opt/java1.2/bin:${LOCALPATH}
}

localpaths () {
   LPATH=

   # for apache use
   [ -d /opt/hpws/apache/bin ] && LPATH=/opt/hpws/apache/bin:${LPATH}

   # for LHS applications
   [ -d /bscs/bscs_sys/shared_tools ] && LPATH=/bscs/bscs_sys/shared_tools:${LPATH}

   # binaries
   [ -d /usr/local/bin ] && LPATH=/usr/local/bin:${LPATH}

   # otros
   [ -d ${BSCS_WORK}/PABLITO/SCRIPTS ] && LPATH=${BSCS_WORK}/PABLITO/SCRIPTS:${LPATH}

   PATH=${LPATH}:${LOCALPATH}
}

newstyle () {
   export PS1="$(echo "${CBLUE}${USER}${CCLEAR}@[${CGRAY}${MYIP}(${HOST}${CCLEAR})]") \${PWD##*/} $> "
   export PS2=" > "
}

oldstyle () {
   export PS1="$(echo "${CCLEAR}\n[${CGRAY}${MYIP}(${HOST})${CCLEAR}]:${CWHITE}\${PWD}\n${CBLUE}${USER}${CCLEAR} $> ")"
   export PS2=" > "
}

search () {
   STRING=$1
   FORE=`tput smso`
   UNDR=`tput smul`
   NORM=`tput sgr0`
   
   grep ${STRING} | sed -e "s/${STRING}/${FORE}${STRING}${NORM}/g" | grep -v sed
}

# common alias
alias ls='ls -F'
alias ll='ls -l'
alias la='ll -a'
alias lt='la -t'
alias lr='lt -r'
alias pw='pwd'
alias domains='cd ~/bea/user_projects/domains'

# terminal type
export EDITOR=vi
export TERM="xterm"
export LANG=C

# history file
export HISTSIZE=500
export HISTCONTROL=ignoredups

# otros
export HOSTNAME=`hostname`
export HOST=`hostname | tr "[:upper:]" "[:lower:]" | sed -e "s/m.*hp//g"`
export MANPATH=$HOME/monopse:$MANPATH

unset USERNAME

# specific host enviroment
[ -e ~/${HOSTNAME}.profile ] && . ~/${HOSTNAME}.profile

# PATH
LOCALPATH=${HOME}/bin:/usr/sbin:${PATH}:.

export PATH=${LOCALPATH}

# get IP Address
MYIP=`/usr/sbin/ping $(hostname) -c1 2> /dev/null | awk '/bytes from/{gsub(":","",$4);print $4}' `
[ "x$MYIP" = "x" ] && MYIP=`echo $SSH_CONNECTION 2> /dev/null | awk '{print $3}' | sed -e "s/.*://g;s/ .*//g"`
[ "x$MYIP" = "x" ] && MYIP=`/usr/sbin/ifconfig lan0 2> /dev/null | grep "inet" | sed -e "s/.*inet //g;s/netmask.*//g"`
[ "x$MYIP" = "x" ] && MYIP=`/usr/sbin/ifconfig lan1 2> /dev/null | grep "inet" | sed -e "s/.*inet //g;s/netmask.*//g"`

# Cursor and profile
java14
oldstyle
localpaths
