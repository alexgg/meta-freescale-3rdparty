#!/bin/bash
#===============================================================================
#
#  build.sh
#
#  Copyright (C) 2018 by Digi International Inc.
#  All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2 as published by
#  the Free Software Foundation.
#
#
#  !Description: Yocto autobuild script from Jenkins.
#
#  Parameters set by Jenkins:
#     DY_PLATFORMS: Platforms to build
#     DY_REVISION:  Revision of the manifest repository (for 'repo init')
#     DY_TARGET:    Target image (the default is 'core-image-base')
#
#===============================================================================

set -e

AVAILABLE_PLATFORMS="ccimx6ulsbcexpress"

DISTRO="poky"

MANIFEST_URL="https://github.com/Freescale/fsl-community-bsp-platform"

RM_WORK_CFG="
INHERIT += \"rm_work\"
"

REPO="$(which repo)"

error() {
	printf "${1}"
	exit 1
}

#
# Copy buildresults (images, licenses, packages)
#
#  $1: destination directoy
#
copy_images() {
	# Copy individual packages only for 'release' builds, not for 'daily'.
	# For 'daily' builds just copy the firmware images (the buildserver
	# cannot afford such amount of disk space)
	if echo ${JOB_NAME} | grep -qs 'dey.*release'; then
		cp -r ${platform}/tmp/deploy/* ${1}/
	else
		cp -r ${platform}/tmp/deploy/images ${1}/
	fi

	# Images directory post-processing
	#  - Jenkins artifact archiver does not copy symlinks, so remove them
	#    beforehand to avoid ending up with several duplicates of the same
	#    files.
	#  - Remove 'README_-_DO_NOT_DELETE_FILES_IN_THIS_DIRECTORY.txt' files
	#  - Create MD5SUMS file
	find ${1} -type l -delete
	find ${1} -type f -name 'README_-_DO_NOT_DELETE*' -delete
	find ${1} -type f -not -name MD5SUMS -print0 | xargs -r -0 md5sum | sed -e "s,${1}/,,g" | sort -k2,2 > ${1}/MD5SUMS
}

# Sanity checks (Jenkins environment)
[ -z "${DY_REVISION}" ] && error "DY_REVISION not specified"
[ -z "${WORKSPACE}" ] && error "WORKSPACE not specified"

# Set default values if not provided by Jenkins
[ -z "${DY_PLATFORMS}" ] && DY_PLATFORMS="$(echo ${AVAILABLE_PLATFORMS})"
[ -z "${DY_TARGET}" ] && DY_TARGET="core-image-base"

YOCTO_IMGS_DIR="${WORKSPACE}/images"
YOCTO_INST_DIR="${WORKSPACE}/fsl-community-bsp.$(echo ${DY_REVISION} | tr '/' '_')"
YOCTO_PROJ_DIR="${WORKSPACE}/projects"

CPUS="$(grep -c processor /proc/cpuinfo)"
[ ${CPUS} -gt 1 ] && MAKE_JOBS="-j${CPUS}"

printf "\n[INFO] Build Yocto \"${DY_REVISION}\" for \"${DY_PLATFORMS}\" (cpus=${CPUS})\n\n"

# Install FSL community BSP
rm -rf ${YOCTO_INST_DIR} && mkdir -p ${YOCTO_INST_DIR}
if pushd ${YOCTO_INST_DIR}; then
	# Use git ls-remote to check the revision type
	if [ "${DY_REVISION}" != "master" ]; then
		if git ls-remote --tags --exit-code "${MANIFEST_URL}" "${DY_REVISION}"; then
			printf "[INFO] Using tag \"${DY_REVISION}\"\n"
			repo_revision="-b refs/tags/${DY_REVISION}"
		elif git ls-remote --heads --exit-code "${MANIFEST_URL}" "${DY_REVISION}"; then
			printf "[INFO] Using branch \"${DY_REVISION}\"\n"
			repo_revision="-b ${DY_REVISION}"
		else
			error "Revision \"${DY_REVISION}\" not found"
		fi
	fi
	yes "" 2>/dev/null | ${REPO} init --no-repo-verify -u ${MANIFEST_URL} ${repo_revision}
	${REPO} forall -p -c 'git remote prune $(git remote)'
	time ${REPO} sync -d ${MAKE_JOBS}
	popd
fi

# Create projects and build
rm -rf ${YOCTO_IMGS_DIR} ${YOCTO_PROJ_DIR}
for platform in ${DY_PLATFORMS}; do
	if pushd ${YOCTO_INST_DIR}; then
		_this_img_dir="${YOCTO_IMGS_DIR}/${platform}"
		mkdir -p ${_this_img_dir}
		# Configure and build the project in a sub-shell to avoid
		# mixing environments between different platform's projects
		(
			TEMPLATECONF=${WORKSPACE}/config/${platform}  MACHINE=${platform} DISTRO=${DISTRO} EULA=1 source setup-environment ${platform}
			printf "${RM_WORK_CFG}" >> conf/local.conf
			for target in ${DY_TARGET}; do
				printf "\n[INFO] Building the $target target.\n"
				time bitbake ${target}
			done
		)
		copy_images ${_this_img_dir}
		popd
	fi
done
