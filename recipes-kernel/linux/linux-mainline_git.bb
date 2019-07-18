DESCRIPTION = "Linux Kernel"
SECTION = "kernel"
LICENSE = "GPLv2"

require recipes-kernel/linux/linux-imx.inc
LIC_FILES_CHKSUM = "file://COPYING;md5=bbea815ee2795b2f4230826c0c6b8814"

DEPENDS += "lzop-native bc-native"

BRANCH = "agonzal/mainline/cc6/v5.1"
SRCREV = "${AUTOREV}"

SRC_URI = " \
            git://log-sln-git.digi.com/linux-2.6.git;branch=${BRANCH} \
            file://defconfig \
      "

PV = "+git${SRCPV}"
