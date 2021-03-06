#!/bin/bash
#
# Zpool Raid-10 Configuration
#
# This script is used to test with the /dev/disk/by-vdev/[A-Z][1-n] devices.
# It assumes that you have already populated /dev/disk/by-vdev/ by creating
# an /etc/zfs/vdev_id.conf file based on your system design.
#
# You can then use either the zpool-create.sh or the zpios.sh test script to
# test various Raid-10 configurations by adjusting the following tunables.
# For example if you wanted to create and test a single 4-disk Raid-10
# configuration using disks [A-D]1 with dedicated ZIL and L2ARC devices
# you could run the following.
#
# ZIL="log A2" L2ARC="cache B2" RANKS=1 CHANNELS=4 \
# zpool-create.sh -c zpool-raid10
#
# zpool status tank
#   pool: tank
#  state: ONLINE
#  scan: none requested
# config:
# 
# 	NAME        STATE     READ WRITE CKSUM
# 	tank        ONLINE       0     0     0
# 	  mirror-0  ONLINE       0     0     0
# 	    A1      ONLINE       0     0     0
# 	    B1      ONLINE       0     0     0
# 	  mirror-1  ONLINE       0     0     0
# 	    C1      ONLINE       0     0     0
# 	    D1      ONLINE       0     0     0
# 	logs
# 	  A2        ONLINE       0     0     0
# 	cache
# 	  B2        ONLINE       0     0     0
#
# errors: No known data errors
#

# Number of interior vdevs to create using the following rank ids.
RANKS=${RANKS:-1}
RANK_LIST=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 )

# Number of devices per vdev using the following channel ids.
CHANNELS=${CHANNELS:-8}
CHANNEL_LIST=( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z )

# Create a ZIL vdev as follows.
ZIL=${ZIL:-}

# Create an L2ARC vdev as follows.
L2ARC=${L2ARC:-}


raid10_setup() {
	local RANKS=$1
	local CHANNELS=$2
	local IDX=0

	RAID10S=()
	for (( i=0, l=0 ; i<${RANKS}; i++ )); do
		RANK=${RANK_LIST[$i]}

		for (( j=0, k=1; j<${CHANNELS}; j+=2,k+=2,l++ )); do
			DISK1="${CHANNEL_LIST[$j]}${RANK}"
			DISK2="${CHANNEL_LIST[$k]}${RANK}"
			RAID10S[$l]="mirror ${DISK1} ${DISK2}"
		done
	done

	return 0
}

zpool_create() {
	raid10_setup ${RANKS} ${CHANNELS}

	ZPOOL_DEVICES="${RAID10S[*]} ${ZIL} ${L2ARC}"
	msg ${ZPOOL} create ${ZPOOL_FLAGS} ${ZPOOL_NAME} ${ZPOOL_DEVICES}
	${ZPOOL} create ${ZPOOL_FLAGS} ${ZPOOL_NAME} ${ZPOOL_DEVICES} || exit 1
}

zpool_destroy() {
	msg ${ZPOOL} destroy ${ZPOOL_NAME}
	${ZPOOL} destroy ${ZPOOL_NAME}
}
