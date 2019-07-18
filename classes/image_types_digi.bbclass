inherit image_types

do_image_boot_ubifs[depends] += " \
    mtd-utils-native:do_populate_sysroot \
    u-boot:do_deploy \
    virtual/kernel:do_deploy \
"

IMAGE_CMD_boot.ubifs() {
	BOOTIMG_FILES_SYMLINK="${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin"
	if [ -n "${KERNEL_DEVICETREE}" ]; then
		for DTB in ${KERNEL_DEVICETREE}; do
			# Remove potential sub-folders
			DTB="$(basename ${DTB})"
			if [ -e "${DEPLOY_DIR_IMAGE}/${DTB}" ]; then
				BOOTIMG_FILES_SYMLINK="${BOOTIMG_FILES_SYMLINK} ${DEPLOY_DIR_IMAGE}/${DTB}"
			fi
		done
	fi

	# Create temporary folder
	TMP_BOOTDIR="$(mktemp -d ${IMGDEPLOYDIR}/boot.XXXXXX)"

	# Hard-link BOOTIMG_FILES into the temporary folder with the symlink filename
	for item in ${BOOTIMG_FILES_SYMLINK}; do
		orig="$(readlink -e ${item})"
		ln "${orig}" "${TMP_BOOTDIR}/$(basename ${item})"
	done

	# Hard-link extlinux.conf file if available
	if [ "${UBOOT_EXTLINUX}" = "1" ]; then
		mkdir -p ${TMP_BOOTDIR}/${UBOOT_EXTLINUX_INSTALL_DIR}
		orig="$(readlink -e ${DEPLOY_DIR_IMAGE}/${UBOOT_EXTLINUX_CONF_NAME})"
		ln "${orig}" "${TMP_BOOTDIR}${UBOOT_EXTLINUX_INSTALL_DIR}/${UBOOT_EXTLINUX_CONF_NAME}"
	fi

	# Hard-link boot script if available
	if [ -n "${UBOOT_BOOTSCRIPT}" ]; then
		orig="$(readlink -e ${DEPLOY_DIR_IMAGE}/${UBOOT_BOOTSCRIPT})"
		ln "${orig}" "${TMP_BOOTDIR}/${UBOOT_BOOTSCRIPT}"
	fi

	# Build UBIFS boot image out of temp folder
	mkfs.ubifs -r "${TMP_BOOTDIR}" -o "${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.ubifs" ${MKUBIFS_BOOT_ARGS}

	# Remove the temporary folder
	rm -rf ${TMP_BOOTDIR}
}

# Remove the default ".rootfs." suffix for 'boot.ubifs' images
do_image_boot_ubifs[imgsuffix] = "."

do_image_boot_vfat[depends] += " \
    coreutils-native:do_populate_sysroot \
    dosfstools-native:do_populate_sysroot \
    mtools-native:do_populate_sysroot \
    u-boot:do_deploy \
    virtual/kernel:do_deploy \
"

IMAGE_CMD_boot.vfat() {
	BOOTIMG_FILES="$(readlink -e ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin)"
	BOOTIMG_FILES_SYMLINK="${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin"
	if [ -n "${KERNEL_DEVICETREE}" ]; then
		for DTB in ${KERNEL_DEVICETREE}; do
			# Remove potential sub-folders
			DTB="$(basename ${DTB})"
			if [ -e "${DEPLOY_DIR_IMAGE}/${DTB}" ]; then
				BOOTIMG_FILES="${BOOTIMG_FILES} $(readlink -e ${DEPLOY_DIR_IMAGE}/${DTB})"
				BOOTIMG_FILES_SYMLINK="${BOOTIMG_FILES_SYMLINK} ${DEPLOY_DIR_IMAGE}/${DTB}"
			fi
		done
	fi

	# Size of kernel and device tree + 10% extra space (in bytes)
	BOOTIMG_FILES_SIZE="$(expr $(du -bc ${BOOTIMG_FILES} | tail -n1 | cut -f1) \* \( 100 + 10 \) / 100)"

	# 1KB blocks for mkfs.vfat
	BOOTIMG_BLOCKS="$(expr ${BOOTIMG_FILES_SIZE} / 1024)"
	if [ -n "${BOARD_BOOTIMAGE_PARTITION_SIZE}" ]; then
		BOOTIMG_BLOCKS="${BOARD_BOOTIMAGE_PARTITION_SIZE}"
	fi

	# POKY: Ensure total sectors is a multiple of sectors per track or mcopy will
	# complain. Blocks are 1024 bytes, sectors are 512 bytes, and we generate
	# images with 32 sectors per track. This calculation is done in blocks, thus
	# the use of 16 instead of 32.
	BOOTIMG_BLOCKS="$(expr \( \( ${BOOTIMG_BLOCKS} + 15 \) / 16 \) \* 16)"

	# Build VFAT boot image and copy files into it
	mkfs.vfat -n "Boot ${MACHINE}" -S 512 -C ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat ${BOOTIMG_BLOCKS}
	mcopy -i ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat ${BOOTIMG_FILES_SYMLINK} ::/

	# Copy boot scripts into the VFAT image
	mcopy -i ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat -s ${DEPLOY_DIR_IMAGE}/${UBOOT_BOOTSCRIPT} ::/${UBOOT_BOOTSCRIPT}

	# Truncate the image to speed up the downloading/writing to the EMMC
	if [ -n "${BOARD_BOOTIMAGE_PARTITION_SIZE}" ]; then
		# U-Boot writes 512 bytes sectors so truncate the image at a sector boundary
		truncate -s $(expr \( \( ${BOOTIMG_FILES_SIZE} + 511 \) / 512 \) \* 512) ${IMGDEPLOYDIR}/${IMAGE_NAME}.boot.vfat
	fi
}

# Remove the default ".rootfs." suffix for 'boot.vfat' images
do_image_boot_vfat[imgsuffix] = "."
