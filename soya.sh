#!/bin/sh
# vim: set ts=2 sw=2 sts=2 si ai: 

# soya.sh - SOI Platform Applications Container
# =-=
# (c) 2008, 2009 Nextel de Mexico
# Andres Aquino Morales <andres.aquino@gmail.com>
# 

#
# default enviroment
APNAME="soya"
APLINK=`basename ${0%.*}`
APPATH="${HOME}/${APNAME}"
APLOGD="${HOME}/logs"
APLEVL="DEBUG"
APTYPE="AP"
VIEWLOG=false
VIEWMLOG=false
APDEBUG=false

SCRPRCS=0
VERSION="`cat ${APPATH}/VERSION | sed -e 's/-rev/ Rev./g'`"
RELEASE=`openssl dgst -md5 ${APPATH}/${APNAME}.sh | rev | cut -c-4 | rev`

# user enviroment
. ${HOME}/.${APNAME}rc

# load user functions
. ${APPATH}/libutils.sh
set_environment

# load application parameter
. ${APPATH}/setup/${APLINK}.conf

# virtual terminal name
APACTION=`basename ${0#*.} | tr "[:lower:]" "[:upper:]"`
log_action "DEBUG" "Using ${APACTION} with soya"

SCRPRCS=`echo ${APLINK} | sed -e "s/[a-zA-Z\.-]/0/g;s/.*\([0-9][0-9]\)$/\1/g"`
SCRNAME=`echo ${APHOST} | sed -e "s/m.*hp//g;s/$/_______/g" | cut -c 1-4`
SCRNAME=`echo ${SCRNAME}${APTYPE}${SCRPRCS} | tr "[:lower:]" "[:upper:]"`

#
set_proc "${SCRNAME}"
get_process_id "${SCRNAME},SCREEN"


##
executeCmd () {
	local STRCOMMAND=${1}

	# eliminar referencias nulas del screen
	${SCREEN} -wipe > /dev/null 2&>1

	# verificar si ya existe una terminal
	process_running
	[ ! -s ${APLOGT}.pid ] && report_status "i" "Wops, another ${SCRNAME} virtual terminal process exist!"
	[ ! -s ${APLOGT}.pid ] && log_action "DEBUG" "Wops, another ${SCRNAME} virtual terminal process exist!"
	[ ! -s ${APLOGT}.pid ] && exit 1

	# ejecutar el comando
	log_action "DEBUG" "Executing ${STRCOMMAND} in screen ${SCRNAME}"
	${SCREEN} -x ${SCRNAME} -p 0 -X stuff "$(printf '%b' "${STRCOMMAND}\015")"
	wait_for "Executing command ${STRCOMMAND} on ${SCRNAME} " 2

	# reportar el estado de la ejecucion
	log_action "DEBUG" "${STRCOMMAND} on ${SCRNAME} cooked, go home baby! "
 
}

##
get_tree_of_applications () {
	process_running
	[ ! -s ${APLOGT}.pid ] && log_action "ERR" "${SCRNAME} process doesn't exist!" && exit 1 

	cat ${APLOGT}.pid | sort -n | head -n1 > ${APLOGT}.proc
	while true
	do
		APID=`tail -n1 ${APLOGT}.proc`
		APPID=`cat ${APLOGT}.allps | awk -v pid=${APID} -v pos=${PSPOS} '{if ($(4+pos) ~ pid){print $(3+pos)}}' 2> /dev/null | sed -e "s/ *//g"`
		[ ${#APPID} -eq 0 ] && break
		echo ${APPID} >> ${APLOGT}.proc
	done
  sort -n ${APLOGT}.proc > ${APLOGT}.list

}


# START
if [ ${APACTION} = "START" ]
then

	# eliminar referencias nulas del screen
	${SCREEN} -wipe > /dev/null 2>&1

	# determinar procesos a terminar
	process_running

	# verificar si ya existe una terminal
	[ -s ${APLOGT}.pid ] && report_status "i" "Wops, another ${SCRNAME} virtual terminal process exist!"
	[ -s ${APLOGT}.pid ] && log_action "DEBUG" "Wops, another ${SCRNAME} virtual terminal process exist!"
	[ -s ${APLOGT}.pid ] && exit 1

	# backup
	mkdir -p ${APTEMP}/${APDATE}
	mv ${APLOGP}.log ${APTEMP}/${APDATE}/${APPRCS}_${APHOUR}.log > /dev/null 2>&1
	log_action "DEBUG" "Backuping ${APLOGP}.log as ${APTEMP}/${APDATE}/${APPRCS}_${APHOUR}.log"

	#
	${SCREEN} -d -m -S ${SCRNAME}
	${SCREEN} -r ${SCRNAME} -p 0 -X log off
	${SCREEN} -r ${SCRNAME} -p 0 -X logfile ${APLOGP}.log
	${SCREEN} -r ${SCRNAME} -p 0 -X logfile flush 10
	${SCREEN} -r ${SCRNAME} -p 0 -X log ${APDEBUG}
	log_action "DEBUG" "Creating VirtualTerminal ${SCRNAME}, logfile as ${APLOGP}.log in mode ${APDEBUG}"
	wait_for "Starting ${SCRNAME} virtual terminal " 3
	
	#
	${SCREEN} -r ${SCRNAME} -p 0 -X stuff "$(printf '%b' "${APCOMMAND} || exit\015")"
	log_action "DEBUG" "Send the command [${APCOMMAND}] in ${SCRNAME}"
	wait_for "Starting process " 8

	# get the tree applications
	process_running
	[ -s ${APLOGT}.pid ] && report_status "*" "VirtualTermina process ${APPRCS} is running right now" ||
	                        report_status "?" "VirtualTermina process ${APPRCS} failed to initialize"

fi


# CHECK
if [ ${APACTION} = "CHECK" ]
then

	# determinar procesos a terminar
	get_tree_of_applications 

	#
	echo "Execution's tree"
	pos=" "
	for APID in $(cat ${APLOGT}.list)
	do
		PNAME=`cat ${APLOGT}.allps | awk -v pid=${APID} -v pos=${PSPOS} '{if ($(3+pos) ~ pid){print}}' | sed -e "s/.*[0-9]:[0-9][0-9]//g" 2> /dev/null`
		[ ${#pos} -gt 0 ] && pos="${pos} "
		[ ${#pos} -eq 1 ] && index="${pos}+" || index="${pos}'-"
		echo "[${APID}  ] ${index} ${PNAME}"
	done

fi

 
# STOP
if [ ${APACTION} = "STOP" ]
then

	# determinar procesos a terminar
	process_running

	# verificar si ya existe una terminal
	[ ! -s ${APLOGT}.pid ] && report_status "i" "Hey, VirtualTerminal ${SCRNAME} doesnt exists..."
	[ ! -s ${APLOGT}.pid ] && log_action "DEBUG" "Hey, VirtualTerminal ${SCRNAME} doesnt exists..."
	[ ! -s ${APLOGT}.pid ] && exit 1

	${SCREEN} -r ${SCRNAME} -p 0 -X log off
	${SCREEN} -r ${SCRNAME} -p 0 -X stuff "$(printf '%b' "exit\015")"
	log_action "DEBUG" "Sending the exit command"
	wait_for "Stopping process " 8

	for APID in $(cat ${APLOGT}.list | sort -r)
	do
		kill -0 ${APID} > /dev/null 2>&1
		LASTSTATUS=$?
		PNAME=`cat ${APLOGT}.allps | awk -v pid=${APID} -v pos=${PSPOS} '{if ($(3+pos) ~ pid){print}}' | sed -e "s/.*[0-9]:[0-9][0-9]//g" 2> /dev/null`
		[ $LASTSTATUS -eq 0 ] && $(kill -9 ${APID} > /dev/null 2>&1)
		[ $LASTSTATUS -eq 0 ] && log_action "DEBUG" "Process ${PNAME} finalized "
	done
	report_status "*" "VirtualTerminal process ${SCRNAME} and subprocesses finalized"

fi

# cualquier otro comando ...
# app.logsOn | app.logsOff | app.backUp | app.logsClear 
case ${APACTION}  in
	LOGSON)
		executeCmd "${APLOGsOn}"
		exit 0
		;;

	LOGSOFF)
		executeCmd "${APLOGsOff}"
		exit 0
		;;

	SYSLOGSON)
		executeCmd "${apSyslogsOn}"
		exit 0
		;;

	SYSLOGSOFF)
		executeCmd "${apSyslogsOff}"
		exit 0
		;;

	DBLOGSON)
		executeCmd "${apDBlogsOn}"
		exit 0
		;;

	DBLOGSOFF)
		executeCmd "${apDBlogsOff}"
		exit 0
		;;

	BACKUP)
		executeCmd "${apBackUp}"
		exit 0
		;;

	LOGSCLEAR)
		executeCmd "${APLOGsClear}"
		exit 0
		;;

	GETLEVEL)
		executeCmd "${apLevel}"
		tail -n100 ${APLOG}.log | grep "Level for this build" | tail -n1
		exit 0
		;;

	VERSION)
		#
		echo "${APNAME} ${VERSION} (${RELEASE})"
		echo "(c) 2008, 2009 Nextel de Mexico, S.A. de C.V.\n"

		if [ "${TTYTYPE}" = "CONSOLE" ]
		then 
			echo "Written by"
			echo "Andres Aquino <andres.aquino@gmail.com>"
		fi	
		exit 0
		;;

esac

#
