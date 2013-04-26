#!/bin/sh +x

SCRIPT_NAME=`basename "${0}"`
VERSION=2.18

unmount_device() {
  ATTEMPTS=0
  MAX_ATTEMPTS=12
  SUCCESS=
  while [ "_${SUCCESS}" = "_" ]
  do
    if [ ${ATTEMPTS} -le ${MAX_ATTEMPTS} ]
    then
      echo "-> unmounting device ${1}..."
      OUTPUT=`diskutil unmountDisk "${1}" 2>&1`
      if [ ${?} -eq 0 ] || [[ "${OUTPUT}" =~ "successful" ]]
    then
		echo "Unmount successful!"
        SUCCESS="YES"
      else
        echo "-> an error occured while trying to unmount the device ${1}, new attempt in 5 seconds..."
        sleep 5
        ATTEMPTS=`expr ${ATTEMPTS} + 1`
	  fi
    else
      echo "Failed to unmount device ${1}, script aborted."
      echo "RuntimeAbortScript"
      exit 1
    fi
  done
}

echo "Running ${SCRIPT_NAME} v${VERSION}"

TOOLS_FOLDER=`dirname "${0}"`

##DISK_ID=`basename "${2}" | sed s/disk// | awk -Fs '{ print $1 }'`
DISK_ID=0
##PARTITION_ID=`basename "${2}" | sed s/disk// | awk -Fs '{ print $2 }'`
PARTITION_ID=3

DEVICE=/dev/disk${DISK_ID}
if [ ! -e "${DEVICE}" ]
then
  echo "Unknown device ${DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi
RAW_DEVICE=/dev/rdisk${DISK_ID}

NTFS_DEVICE=${DEVICE}s${PARTITION_ID}
if [ ! -e "${NTFS_DEVICE}" ]
then
  echo "Unknown device ${NTFS_DEVICE}, script aborted."
  echo "RuntimeAbortScript"
  exit 1
fi

# unmount device
unmount_device "${DEVICE}"


SYSPREP_FILE=/windows/system32/sysprep/unattend.xml

"${TOOLS_FOLDER}"/ntfscp -f "${NTFS_DEVICE}" /tmp/DSNetworkRepository/Files/unattend.new.xml "${SYSPREP_FILE}"

# remount device
echo "-> mounting device ${DEVICE}..."
diskutil mountDisk "${DEVICE}"
if [ ${?} -ne 0 ]
then
  diskutil mount "${DEVICE}s2" &>/dev/null
  diskutil mount "${DEVICE}s3" &>/dev/null
  diskutil mount "${DEVICE}s4" &>/dev/null
fi

exit 0
