# Copyright (C) 2019 Digi International.

pkg_postinst_ontarget_${PN}_ccimx6() {
	RESIZE2FS="$(which resize2fs)"
	if [ -x "${RESIZE2FS}" ]; then
		PARTITIONS="$(blkid /dev/mmcblk*p* | sed -ne "{s,\(^/dev/mmcblk*[^:]\+\):.*TYPE=\"ext.\".*,\1,g;T;p}" | sort -u)"
		for i in ${PARTITIONS}; do
			if ! ${RESIZE2FS} ${i} 2>/dev/null; then
				echo "ERROR: resize2fs ${i}"
			fi
		done
	fi
}
