FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

COMPATIBLE_MACHINE_imx6sl-warp = "(.)"
COMPATIBLE_MACHINE_imx6dl-riotboard = "(.)"

SRC_URI_append_imx6qdl-variscite-som_use-mainline-bsp = " \
    file://imx6qdl-var-som.dtsi \
    file://imx6q-var-som-vsc.dts \
"

SRC_URI_append_ccimx6ul = " \
    file://0001-MLK-11719-4-mtd-gpmi-change-the-BCH-layout-setting-f.patch \
    ${@bb.utils.contains('MACHINE_FEATURES', 'wifi', 'file://0002-ARM-dts-imx6ul-ccimx6ulsom-Add-empty-wireless-and-bl.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'wifi', 'file://0003-net-wireless-Export-regulatory_hint_user.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'wifi', 'file://0004-net-wireless-Allow-for-firmware-to-handle-DFS.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'wifi', 'file://0005-net-wireless-Add-cfg80211_is_gratuitous_arp_unsolici.patch', '', d)} \
    file://0006-linux-crypto-caam-set-hwrng-quality.patch \
"

SRC_URI_append_ccimx6ul = " \
    file://0001-ARM-Add-support-for-the-ConnectCore-6UL-System-On-Mo.patch \
    file://0002-mach-imx-pm-imx6-Add-hooks-for-board-specific-implem.patch \
    file://0003-imx6ul-Add-MCA-core-I2C-driver-support.patch \
    file://0004-imx6ul-Add-MCA-GPIO-support-for-the-ConnectCore-6UL-.patch \
    file://0005-imx6ul-Add-MCA-IOMUX-support-to-the-ConnectCore-6UL-.patch \
    file://0006-imx6ul-Add-MCA-watchdog-support-for-the-ConnectCore-.patch \
    file://0007-imx6ul-Add-MCA-ADC-support-for-ConnectCore-6UL-SOM-a.patch \
    file://0008-imx6ul-Add-MCA-tamper-support-for-ConnectCore-6UL-SO.patch \
    file://0009-imx6ul-Add-MCA-UART-support-for-ConnectCore-6UL-SOM-.patch \
    file://0010-imx6ul-Add-RTC-MCA-support-for-ConnectCore-6UL-SOM.patch \
    file://0011-imx6ul-Add-MCA-power-key-support-for-ConnectCore-6UL.patch \
"

SRC_URI_append_ccimx6ulsbcpro = " \
    file://0001-ccimx6ulsbcpro-Add-IOEXP-core-I2C-support.patch \
    file://0002-ccimx6ulsbcpro-Add-IOEXP-GPIO-support.patch \
    file://0003-ccimx6ulsbcpro-Add-IOEXP-ADC-support.patch \
    file://0004-ARM-dts-ccimx6ulsbcpro-Configure-touch-GPIO-reset-li.patch \
"

SRC_URI_append_ccimx6ulsbcpro = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'alsa', 'file://0001-ARM-dts-i.MX6UL-Add-ASRC-support.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'alsa', 'file://0002-dt-bindings-ASoC-fsl-add-binding-for-imx-max98088-ma.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'alsa', 'file://0003-ASoC-fsl-Add-imx-max98088-machine-driver.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'alsa', 'file://0004-ARCH-arm-imx_v6_v7_defconfig-Support-MAX98088-codecs.patch', '', d)} \
    ${@bb.utils.contains('MACHINE_FEATURES', 'alsa', 'file://0005-ARM-imx6ul-ccimx6ulsbcpro-Configure-audio-support.patch', '', d)} \
"

do_configure_prepend_ccimx6ul() {
    if ${@bb.utils.contains('MACHINE_FEATURES', 'wifi', 'true', 'false', d)}; then
        kernel_conf_variable HOSTAP m
        kernel_conf_variable PROVE_LOCKING n
        sed -e "${CONF_SED_SCRIPT}" < '${WORKDIR}/defconfig' >> '${B}/.config'
    fi
    if ${@bb.utils.contains('MACHINE_FEATURES', 'bluetooth', 'true', 'false', d)}; then
        kernel_conf_variable BT_RFCOMM y
        sed -e "${CONF_SED_SCRIPT}" < '${WORKDIR}/defconfig' >> '${B}/.config'
    fi
}

do_configure_prepend_imx6qdl-variscite-som() {
    cp ${WORKDIR}/imx6*-var*.dts* ${S}/arch/arm/boot/dts
}
