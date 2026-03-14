#!/bin/bash
#
# Copyright (c) 2019 Fuzhou Rockchip Electronics Co., Ltd
#
# SPDX-License-Identifier: GPL-2.0
#
# Script modified by Minho Jo <whitestone8214@gmail.com> <goguma200@protonmail.com>


_here1=$(pwd)


function announce {
	echo -e "\033[1;32m::\033[0m \033[1;37m${1}\033[0m"
}


# Default settings for R36S
rm -f .config || exit -1
cp -f ${_here1}/../modifications/config.uboot .config || exit -1

# Core firmware(s)
cd tools/rk_tools || exit -1
tools/boot_merger --replace tools/rk_tools/ ./ RKBOOT/RK3326MINIALL.ini || exit -1
cp -f *_loader_*.bin ${_here1}/ || exit -1
cd ${_here1} || exit -1
#cp -f tools/rk_tools/*_loader_*.bin ./ || exit -1

# U-Boot
announce "U-Boot"
make CROSS_COMPILE=$(pwd)/../gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- all > /dev/null || exit -1
_checkSize="$(${_here1}/../helper check-uboot-size u-boot.bin)"
if (test "${_checkSize}" != "ok"); then
	echo "ERROR: U-Boot image size is too big"
	exit -1
fi
tools/loaderimage --pack --uboot u-boot.bin ${_here1}/01.uboot.img 0x00200000 # 0x00200000 is the value of CONFIG_SYS_TEXT_BASE in include/autoconf.mk

# IDB loader
announce "IDB loader"
tools/mkimage -n px30 -T rksd -d tools/rk_tools/bin/rk33/rk3326_ddr_333MHz_v1.10.bin ${_here1}/00.idbloader.img || exit -1
cat tools/rk_tools/bin/rk33/rk3326_miniloader_v1.12.bin >> ${_here1}/00.idbloader.img

# Trusted firmware
announce "Trusted firmware"
cd tools/rk_tools || exit -1
tools/trust_merger --rsa 3 --replace tools/rk_tools/ ./  RKTRUST/RK3326TRUST.ini || exit -1
cp -f trust.img ${_here1}/02.trust.img || exit -1
cd ${_here1} || exit -1
