#!/bin/bash

##############################################################
#
# Program Information
# Name : 
# Author : Jon Zobrist <jzobrist@inthinc.com>
# Copyright : Inthinc Technology Solutions, Inc. 2011
# License : GPL 2.0 or higher
# Purpose : Create EBS Volumes, attach and set them up as a RAID array on an EC2 instance
#
##############################################################

##############################################################
# Configuration section :
#
SSH_CMD="/usr/bin/ssh -o StrictHostKeyChecking=no" #The path and options for your ssh program
SSH_USER="ubuntu" #The remote user who can sudo and run commands
#EBS_IOPS=1200
#
#The following variables should be set correctly in $ENV
#	EC2_REGION
#	EC2_ZONE
#	EC2_KEYS
#	EC2_CERT
#	EC2_PRIVATE_KEY
#	In addition to having your environment setup, you should have the ec2-tools installed and in your $PATH
#	Download and install EC2 API Tools from
#	http://aws.amazon.com/developertools/351
#
#
#These are generally passed as args, but you can force set them here
#	MOUNT_BASE="/usr/local/mysql"
#	RAID_DEVICE="/dev/md/0"
#	EBS_VOLUME_SIZE="250"
#
##############################################################


##############################################################
# Functions

function check_instance {
	echo "Verifying instance is running"
	while ! ec2-describe-instances ${INSTANCE_ID} | grep -q running; do echo -n "."; sleep 1; done
	echo "Instance running"
	INSTANCE_ADDRESS=$(ec2-describe-instances ${INSTANCE_ID} | egrep ^INSTANCE | awk '{ print $4 }')
	if [ ! -n "${INSTANCE_ADDRESS}" ]
	then
		echo "Missing instance address for instance ID ${INSTANCE_ID}, got ${INSTANCE_ADDRESS}"
		exit 1
	fi

	echo "Testing connectivity via SSH"
	while ! ${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "/bin/ls /" | grep -q "root"; do echo "."; sleep 1; done

	for (( x = 0 ; x <= 30 ; x++ ))
	do
		MY_RAID_LIST=$( ${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "/bin/ls /dev/md${x}* 2>/dev/null " )
		if [ ! -n "${MY_RAID_LIST}" ]
		then
			RAID_DEVICE="/dev/md/${x}"
			echo "Using ${RAID_DEVICE}"
			break
		fi
		##	echo "not using ${DISK}"
		echo -n "."
	done


	#Check mount point doesn't exist and create it
	MY_MOUNT_BASE=$( ${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "if [ -d ${MOUNT_BASE} ]; then echo "Directory exists"; else sudo mkdir -p ${MOUNT_BASE}; fi" )
	if [ -n "${MY_MOUNT_BASE}" ]
	then
		echo "Mount base ${MOUNT_BASE} exists on ${INSTANCE_ADDRESS}, exiting at `date`"
		echo "Returned was ${MY_MOUNT_BASE}"
		exit 1
	fi

	#Make sure mdadm is installed! if not offer to install it?
	echo "Checking mdadm.."
	MDADM_CMD=$(${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "which mdadm")
	if [ -z "${MDADM_CMD}" ]
	then
		${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo apt-get -y install mdadm"
	else
		echo "mdadm exists as ${MDADM_CMD}"
	fi

	#Make sure xfs is installed
	MKXFS_CMD=$(${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "which mkfs.xfs")
	if [ -z "${MKXFS_CMD}" ]
	then
		${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo apt-get -y install xfsprogs"
	else
		echo "mkfs.xfs exists as ${MKXFS_CMD}"
	fi
}

function setup_raid {
#Create EBS Volumes
echo "entered setup_raid"
	RAID_DEVICES=""
	DRIVES=15
	MAX_DRIVES=14
	for (( i = 1 ; i <= ${EBS_VOLUMES} ; i++ ))
	do
		if [ ${DRIVES} -gt ${MAX_DRIVES} ]
		then
			DRIVES=1
			#Connect and check for available disk locations /dev/sdX
			echo "Checking for available disks"
			#USED_DISKS=$(${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} '/bin/ls -1 /dev/sd* | sort | tail -n 1')
			CHECK_DISKS="/dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt"
			for DISK in ${CHECK_DISKS}
			do
				MY_DISK_LIST=$( ${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "/bin/ls ${DISK}* 2>/dev/null " )
				if [ ! -n "${MY_DISK_LIST}" ]
				then
					DEVICE_BASE="${DISK}"
					echo "Using ${DEVICE_BASE}"
					break
				fi
				##	echo "not using ${DISK}"
				echo -n "."
			done
		fi
		DISK_DEVICE="${DEVICE_BASE}${DRIVES}"
		((DRIVES++))
		if $( ${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "/bin/ls ${DISK_DEVICE}" )
		then
			echo "Volume ${DISK_DEVICE} exists, exiting at `date`"
			exit 1
		fi
		RAID_DEVICES="${RAID_DEVICES} ${DISK_DEVICE}"
                if [ "${EBS_IOPS}" ]
                then
                    echo "Creating volume for ${INSTANCE_ID} as ${DISK_DEVICE} at `date` with ${EBS_IOPS} IOPS"
                    EBS_VOLUME=$(ec2-create-volume -z ${EC2_ZONE} --region ${EC2_REGION} -t io1 -i ${EBS_IOPS} --size ${EBS_VOLUME_SIZE} | cut -f2)
                else
                    echo "Creating volume for ${INSTANCE_ID} as ${DISK_DEVICE} at `date`"
                    EBS_VOLUME=$(ec2-create-volume -z ${EC2_ZONE} --region ${EC2_REGION} --size ${EBS_VOLUME_SIZE} | cut -f2)
                fi
		echo "DEBUG: echo \"Attaching volume ${EBS_VOLUME} to ${INSTANCE_ID} as ${DISK_DEVICE} at `date`\""
#Attach volumes to instance
		ec2-attach-volume ${EBS_VOLUME} -i ${INSTANCE_ID} -d ${DISK_DEVICE}
		echo "DEBUG: ec2-attach-volume ${EBS_VOLUME} -i ${INSTANCE_ID} -d ${DISK_DEVICE}"
		echo "Waiting for volume to attach at `date`"
		while ! ec2-describe-volumes ${EBS_VOLUME} | grep -q attached; do sleep 1; done
	done
	sleep 60
echo "Create and start RAID device"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo mdadm --create ${RAID_DEVICE} --level 0 --chunk 256 --metadata 1.1 --raid-devices ${EBS_VOLUMES} ${RAID_DEVICES}"

echo "Format RAID device"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo mkfs.xfs -q ${RAID_DEVICE}"

echo "Configure /etc/fstab and /etc/mdadm"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo mkdir -p /etc/mdadm"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo echo DEVICE partitions | sudo tee /etc/mdadm/mdadm.conf"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo echo MAILADDR root@inthinc.com | sudo tee -a /etc/mdadm/mdadm.conf"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo mdadm --examine --scan | sudo tee -a /etc/mdadm/mdadm.conf"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo echo ${RAID_DEVICE} ${MOUNT_BASE} xfs noauto,noatime,logbsize=256k,nobarrier 0 0 | sudo tee -a /etc/fstab"
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo blockdev --setra 65536 ${RAID_DEVICE}"
#Mount RAID device
	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo mount ${MOUNT_BASE}"
#Zero out disks - uncomment out these 2 lines to force zero'ing of all disks created
#Note : This will take a very very very much longer time
#	It's safer to zero out your disks after you have the RAID done, locally
#	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo time dd if=/dev/zero of=${MOUNT_BASE}/cleanup.img"
#	${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS} "sudo time /bin/rm ${MOUNT_BASE}/cleanup.img"

	echo "connect with :"
	echo "${SSH_CMD} -i ${EC2_KEYS} ${SSH_USER}@${INSTANCE_ADDRESS}"

}

##############################################################

##############################################################
# Startup checks

if ( [ -n "${EC2_REGION}" ] && [ -n "${EC2_ZONE}" ] && [ -n "${EC2_KEYS}" ]  && [ -n "${1}" ] && [ -n "${2}" ] && [ -n "${3}" ] && [ -n "${4}" ] )
then
	if [ ${2} -gt 15 ]
	then
		echo "Max Volumes per node is 14, ${2} is more, RAID will span devices" 
	fi
	echo "Proceeding with :"
	echo "EBS volume size=${1}"
	EBS_VOLUME_SIZE="${1}"
	echo "Number EBS volumes=${2}"
	EBS_VOLUMES="${2}"
       	echo "EC2 instance ID=${3}"
	INSTANCE_ID="${3}"
	echo "Mount point=${4}"
	MOUNT_BASE="${4}"
        if [ "${5}" ]
        then
            EBS_IOPS="${5}"
        fi
        if [ "${EBS_IOPS}" ]
        then
            echo "Using dedicated IOPS, there will be ${EBS_IOPS} IOPS _per_ device"
        else
            echo "Not using dedicated IOPS"
        fi

	check_instance
	setup_raid
else
	echo "Usage ${0} <EBS volume size> <number EBS volumes> <EC2 instance ID> <Mount point> [IOPS]"
	exit 1
fi


