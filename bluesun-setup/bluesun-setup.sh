#!/bin/bash

### BEGIN INIT INFO
# Provides:		bluesun-setup
# Short-Description:	S3 file and DB checkout and deploy script
### END INIT INFO
#
# Author : Jon Zobrist <jon@jonzobrist.com>
# Homepage : http://www.jonzobrist.com
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2012, Jon Zobrist
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Purpose : This script backs up directories & MySQL to a bucket in S3, and restores them
# Usage : bluesun-setup.sh [start|stop|updateS3]
# WARNING : Running this script with start will DELETE your local versions of whatever you have it set to backup
# WARNING : Running this script with start will DELETE your local versions of whatever you have it set to backup
# WARNING : Running this script with start will DELETE your local versions of whatever you have it set to backup

if [ -f /etc/bluesun-setup/server.conf ]
 then
	source /etc/bluesun-setup/server.conf
 else
	echo "No config file found, exiting at `date`"
	exit 1
fi

if [ ${DEBUG} -eq 1 ]; then echo "Starting ${0} at `date` using tmp dir ${TMPDIR}"; fi

#Functions

function check_mysql_ready {
	if [ ${DEBUG} -eq 1 ]; then echo "Waiting for MySQLD to be running."; fi
	COUNT=0
	#This did not work...
	#while ! mysql -e "show databases;" 2>&1 | grep -q information_schema
	while ! pgrep mysqld | grep -q [0-9]
	 do 
		if [ ${COUNT} -lt ${MAX_WAIT_FOR_MYSQL} ]
		 then
			((COUNT++))
			sleep 1
			if [ ${DEBUG} -eq 1 ]; then echo -n "."; fi 
		else
			echo "Waiting for MySQL Failed on timeout, waited longer than ${MAX_WAIT_FOR_MYSQL} seconds, exiting";
			exit 1
		fi
	sleep 1 #We sleep for fun!!!
	done
	MYSQL_IS_READY=1
}





case "${1}" in
  start)
	mkdir -p ${TMPDIR}
	if [ "${DIRS}" ] && [ -d ${TMPDIR} ]
	 then
		for DIR in ${DIRS}
		 do
			/bin/rm "${PINGFILE}"
			if [ ${DEBUG} -eq 1 ]; then echo "${DIR}"; fi
			/bin/rm -Rf ${DIR}
			mkdir -p ${DIR}
			PREFIX=`basename ${DIR}`
			FILENAME="${PREFIX}-current.tar.gz"
			if [ ${DEBUG} -eq 1 ]; then echo "Updating files from S3 ${S3_BUCKET} at `date`"; fi
			if [ ${DEBUG} -eq 1 ]; then echo "s3get ${S3_BUCKET}/${FILENAME} ${TMPDIR}/${FILENAME}"; fi
			s3get ${S3_BUCKET}/${FILENAME} ${TMPDIR}/${FILENAME}
			if [ ${DEBUG} -eq 1 ]
			 then
				echo "tar -zxvf ${TMPDIR}/${FILENAME} -C ${DIR}"
				tar -zxvf ${TMPDIR}/${FILENAME} -C ${DIR}
			 else
				if [ ${DEBUG} -eq 1 ]; then echo "tar -zxf ${TMPDIR}/${FILENAME} -C ${DIR}"; fi
				tar -zxf ${TMPDIR}/${FILENAME} -C ${DIR}
			fi
		sleep 1 #We sleep for fun!!!
		echo "[ok]" > "${PINGFILE}"
		done
	fi

	#Check our MySQL Variables, if both MYSQL_FILENAME *AND* MYSQL_DATABASES are set then we have an error case...
	#MySQL Dump relies on having passwordless root/dumper acecss to mysql
	#MYSQL_FILENAME indicates the filename for a FULL MYSQLDUMP -A backup of an entire MYSQL server
	#I typically setup ~/.my.cnf for this
	if [ "${MYSQL_FILENAME}" ]
	 then
		if [ ${DEBUG} -eq 1 ]; then echo "Downloading ${MYSQL_FILENAME} to ${TMPDIR} at `date`"; fi
		if [ ${DEBUG} -eq 1 ]; then echo "s3get ${S3_BUCKET}/${MYSQL_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}"; fi
		s3get ${S3_BUCKET}/${MYSQL_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}
		if [ ${DEBUG} -eq 1 ]; then echo "Restoring MySQL full DB `date`"; fi
		check_mysql_ready
		if [ ${DEBUG} -eq 1 ]; then echo "zcat ${TMPDIR}/${MYSQL_FILENAME} | mysql"; fi
		zcat ${TMPDIR}/${MYSQL_FILENAME} | sudo mysql
	fi

	#MYSQL_DATABASES
	#
	for DB in ${MYSQL_DATABASES}
	 do
		if [ ${DEBUG} -eq 1 ]; then echo "Individual Database is ${DB}"; fi
		#DBNAME_TABLES check and processing
		if [ "`eval echo '$'${MYSQL_DATABASES}_TABLES`" ]
		 then
			if [ ${DEBUG} -eq 1 ]; then echo "we have tables, `eval echo '$'${MYSQL_DATABASES}_TABLES`"; fi
			for TABLE in `eval echo '$'${MYSQL_DATABASES}_TABLES`
			 do
				if [ ${DEBUG} -eq 1 ]; then echo "TABLE is ${TABLE}"; fi
				MYSQL_TABLE_FILENAME="${DB}-${TABLE}-${ENDFILENAME}"
				s3get ${S3_BUCKET}/${MYSQL_TABLE_FILENAME} ${TMPDIR}/${MYSQL_TABLE_FILENAME}
				if [ -f ${TMPDIR}/${MYSQL_TABLE_FILENAME} ]
				 then
					check_mysql_ready
					if [ ${DEBUG} -eq 1 ]; then echo "zcat ${TMPDIR}/${MYSQL_TABLE_FILENAME} | mysql"; fi
					zcat ${TMPDIR}/${MYSQL_TABLE_FILENAME} | mysql ${DB}
				fi
			sleep 1 #We sleep for fun!!!
			done
		 else
			if [ ${DEBUG} -eq 1 ]; then echo "We have no tables"; fi
			if [ ${DEBUG} -eq 1 ]; then echo "Restoring full Database ${DB}"; fi
			MYSQL_DB_FILENAME="${DB}-${ENDFILENAME}"
			s3get ${S3_BUCKET}/${MYSQL_DB_FILENAME} ${TMPDIR}/${MYSQL_DB_FILENAME}
			check_mysql_ready
			if [ ${DEBUG} -eq 1 ]; then echo "zcat ${TMPDIR}/${MYSQL_DB_FILENAME} | mysql"; fi
			zcat ${TMPDIR}/${MYSQL_DB_FILENAME} | mysql ${DB}
		fi
		for TABLE in `eval echo '$'${MYSQL_DATABASES}_TABLES`
		 do
			if [ ${DEBUG} -eq 1 ]; then echo "Specific TABLE for DB ${DB} is ${TABLE}"; fi
		sleep 1 #We sleep for fun!!!
		done
	sleep 1 #We sleep for fun!!!
	done

	if [ "${COMMANDS}" ]
	 then
		for COMMAND in ${COMMANDS}
		 do
			if [ ${DEBUG} -eq 1 ]; then echo "Running command ${COMMAND} from ${S3_BUCKET} at `date`"; fi
			if [ ${DEBUG} -eq 1 ]; then echo "s3get ${S3_BUCKET}/${COMMAND} ${TMPDIR}/${COMMAND}"; fi
			s3get ${S3_BUCKET}/${COMMAND} ${TMPDIR}/${COMMAND}
			chmod u+x ${TMPDIR}/${COMMAND}
			if [ -f ${TMPDIR}/${COMMAND} ]
			 then
				if [ ${DEBUG} -eq 1 ]; then echo "${TMPDIR}/${COMMAND}"; fi
				${TMPDIR}/${COMMAND}
			fi
		sleep 1 #We sleep for fun!!!
		done
	fi
	if [ ${DEBUG} -eq 1 ]; then echo "[ok] > ${PINGFILE}"; fi
	echo "[ok]" > "${PINGFILE}"
  ;;
  stop)
	/bin/rm "${PINGFILE}"
  ;;
  updateS3)
	if [ ${DEBUG} -eq 1 ]; then echo "Updating archive files to S3 started at `date`"; fi
	mkdir -p ${TMPDIR}
	for DIR in ${DIRS}
	 do
		if [ ${DEBUG} -eq 1 ]; then echo "${DIR}"; fi
		PREFIX=`basename ${DIR}`
		FILENAME="${PREFIX}-current.tar.gz"
		ARCHIVE_FILENAME="${PREFIX}-${HOSTNAME}-${TIMESTAMP}.tar.gz"
		if [ ${DEBUG} -eq 1 ]; then echo "Creating tar file ${FILENAME} at `date`"; fi
		cd ${DIR}
		if [ ${DEBUG} -eq 1 ]
		 then
			if [ ${DEBUG} -eq 1 ]; then echo "tar -zvcf ${TMPDIR}/${FILENAME} *"; fi
			tar -zvcf ${TMPDIR}/${FILENAME} *
		 else
			if [ ${DEBUG} -eq 1 ]; then echo "tar -zcf ${TMPDIR}/${FILENAME} *"; fi
			tar -zcf ${TMPDIR}/${FILENAME} *
		fi
		if [ ${DEBUG} -eq 1 ]; then echo "Uploading to S3 ${S3_BUCKET} at `date`"; fi
		if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${FILENAME} ${TMPDIR}/${FILENAME}"; fi
		s3put ${S3_BUCKET}/${FILENAME} ${TMPDIR}/${FILENAME}
		if [ ${ARCHIVE} -eq 1 ]
		 then
			if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${ARCHIVE_FILENAME} ${TMPDIR}/${FILENAME}"; fi
			s3put ${S3_BUCKET}/${ARCHIVE_FILENAME} ${TMPDIR}/${FILENAME}
		fi
	sleep 1 #We sleep for fun!!!
	done
	#MySQL Dump relies on having passwordless root/dumper acecss to mysql
	#I typically setup ~/.my.cnf for this
	if [ "${MYSQL_FILENAME}" ]
	 then
		if [ ${DEBUG} -eq 1 ]; then echo "Dumping MySQL full DB `date`"; fi
		if [ ${DEBUG} -eq 1 ]; then echo "mysqldump -A | gzip -c - > ${TMPDIR}/${MYSQL_FILENAME}"; fi
		mysqldump -A | gzip -c - > ${TMPDIR}/${MYSQL_FILENAME}
		if [ ${DEBUG} -eq 1 ]; then echo "Uploading ${MYSQL_FILENAME} to S3 at `date`"; fi
		if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${MYSQL_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}"; fi
		s3put ${S3_BUCKET}/${MYSQL_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}
		if [ ${ARCHIVE} -eq 1 ]
		 then
			MYSQL_ARCHIVE_FILENAME="mysqldump-${TIMESTAMP}-${ENDFILENAME}"
			if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${MYSQL_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}"; fi
			s3put ${S3_BUCKET}/${MYSQL_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_FILENAME}
		fi
	fi

	#Backup individual databases
	#MYSQL_DATABASES
	#
	for DB in ${MYSQL_DATABASES}
	 do
		if [ ${DEBUG} -eq 1 ]; then echo "Backing Up Individual Database ${DB}"; fi
		#DBNAME_TABLES check and processing
		if [ "`eval echo '$'${DB}_TABLES`" ]
		 then
			if [ ${DEBUG} -eq 1 ]; then echo "we have tables, `eval echo '$'${DB}_TABLES`"; fi
			for TABLE in `eval echo '$'${DB}_TABLES`
			 do
				if [ ${DEBUG} -eq 1 ]; then echo "TABLE is ${TABLE}"; fi
				MYSQL_TABLE_FILENAME="${DB}-${TABLE}-${ENDFILENAME}"
				if [ ${DEBUG} -eq 1 ]; then echo "Dumping table ${TABLE} on ${DB} `date`"; fi
				check_mysql_ready
				if [ ${DEBUG} -eq 1 ]; then echo "mysqldump ${MYSQLDUMP_ARGS} ${DB} --tables ${TABLE} | gzip -c - > ${TMPDIR}/${MYSQL_TABLE_FILENAME}"; fi
				mysqldump ${MYSQLDUMP_ARGS} ${DB} --tables ${TABLE} | gzip -c - > ${TMPDIR}/${MYSQL_TABLE_FILENAME}
				if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${MYSQL_TABLE_FILENAME} ${TMPDIR}/${MYSQL_TABLE_FILENAME}"; fi
				s3put ${S3_BUCKET}/${MYSQL_TABLE_FILENAME} ${TMPDIR}/${MYSQL_TABLE_FILENAME}
				#ARCHIVE TABLE
				if [ ${ARCHIVE} -eq 1 ]
				 then
					TABLE_ARCHIVE_FILENAME="table-${DB}-${TABLE}-${TIMESTAMP}.tar.gz"
					s3put ${S3_BUCKET}/${TABLE_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_TABLE_FILENAME}
					if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${TABLE_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_TABLE_FILENAME}"; fi
				fi
			sleep 1 #We sleep for fun!!!
			done
		 else
			if [ ${DEBUG} -eq 1 ]; then echo "We have no tables"; fi
			if [ ${DEBUG} -eq 1 ]; then echo "Backing up full Database ${DB}"; fi
			MYSQL_DB_FILENAME="${DB}-${ENDFILENAME}"
			check_mysql_ready
			if [ ${DEBUG} -eq 1 ]; then echo "mysqldump ${MYSQLDUMP_ARGS} ${DB} | gzip -c - > ${TMPDIR}/${MYSQL_DB_FILENAME}"; fi
			mysqldump ${MYSQLDUMP_ARGS} ${DB} | gzip -c - > ${TMPDIR}/${MYSQL_DB_FILENAME}
			if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${MYSQL_DB_FILENAME} ${TMPDIR}/${MYSQL_DB_FILENAME}"; fi
			s3put ${S3_BUCKET}/${MYSQL_DB_FILENAME} ${TMPDIR}/${MYSQL_DB_FILENAME}
			#ARCHIVE DATABASE
			if [ ${ARCHIVE} -eq 1 ]
			 then
				DB_ARCHIVE_FILENAME="DB-${DB}-${TIMESTAMP}.tar.gz"
				if [ ${DEBUG} -eq 1 ]; then echo "s3put ${S3_BUCKET}/${DB_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_DB_FILENAME}"; fi
				s3put ${S3_BUCKET}/${DB_ARCHIVE_FILENAME} ${TMPDIR}/${MYSQL_DB_FILENAME}
			fi
		fi
		for TABLE in `eval echo '$'${DB}_TABLES`
		 do
			if [ ${DEBUG} -eq 1 ]; then echo "Specific TABLE for DB ${DB} is ${TABLE}"; fi
		sleep 1 #We sleep for fun!!!
		done
	sleep 1 #We sleep for fun!!!
	done
  ;;
  *)
	echo "Usage ${0} [start|stop|updateS3]"
	exit 1
esac

if [ ${DEBUG} -eq 1 ]; then echo "Cleaning up ${TMPDIR}"; fi
/bin/rm -Rf ${TMPDIR}
