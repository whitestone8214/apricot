#!/bin/bash

# Copyright (C) 2026 Minho Jo <whitestone8214@gmail.com> <goguma200@protonmail.com>

# SPDX-License-Identifier: GPL-2.0

# prepare: Prepare to build U-Boot
# build: Build U-Boot (clean: Clean build)
# install: Install U-Boot

# In my case: ./x.sh prepare -> ./x.sh build clean -> sudo ./x.sh install /dev/sdb


_here=$(pwd)
_whereSourceUBoot="R36S-u-boot-5e988dc03e1ed112c7b34148f249b5180d5054d7"


function announce {
	echo -e "\033[1;32m::\033[0m \033[1;37m${1}\033[0m"
}


if (test "$1" = "prepare"); then
	announce "Prepare"
	
	if (!(test -e "gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz")); then # GCC
		curl -L -O https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz || exit -1
	fi
	if (!(test -e "5e988dc03e1ed112c7b34148f249b5180d5054d7.tar.gz")); then # U-Boot
		curl -L -O https://github.com/R36S-Stuff/R36S-u-boot/archive/5e988dc03e1ed112c7b34148f249b5180d5054d7.tar.gz || exit -1
	fi
	if (!(test -e "21802319a77c04b368adee9ef399d0d1d707644b.tar.gz")); then # Multi-panel support package
		curl -L -O https://github.com/R36S-Stuff/R36S-U-Boot-PanelSupport/archive/21802319a77c04b368adee9ef399d0d1d707644b.tar.gz || exit -1
	fi
	
	if (!(test -e "gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu")); then
		tar -xf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz || exit -1
	fi
	if (!(test -e "${_whereSourceUBoot}")); then
		tar -xf 5e988dc03e1ed112c7b34148f249b5180d5054d7.tar.gz || exit -1
	fi
	if (!(test -e "R36S-U-Boot-PanelSupport-21802319a77c04b368adee9ef399d0d1d707644b")); then
		tar -xf 21802319a77c04b368adee9ef399d0d1d707644b.tar.gz || exit -1
	fi
elif (test "$1" = "build"); then
	announce "Build"
	
	if (test "$2" = "clean"); then
		rm -rf ${_whereSourceUBoot} || exit -1
		tar -xf 5e988dc03e1ed112c7b34148f249b5180d5054d7.tar.gz || exit -1
		
		cp -f modifications/make.sh ${_whereSourceUBoot}/ || exit -1
		sed -i 's|@HERE@|'$(pwd)'|g;' ${_whereSourceUBoot}/make.sh || exit -1
		
		sed -i 's|YYLTYPE yylloc|extern YYLTYPE yylloc|g;' ${_whereSourceUBoot}/scripts/dtc/dtc-lexer.lex.c_shipped || exit -1
		
		cp -f modifications/booti.c ${_whereSourceUBoot}/cmd/ || exit -1
		
		rm -f helper || exit -1
		gcc -o helper -O3 -fPIC helper.c || exit -1
	fi
	
	cd ${_whereSourceUBoot} || exit -1
	./make.sh || exit -1
elif (test "$1" = "install"); then
	echo "WARNING:"
	echo "This will erase everything on ${2}."
	printf "Are you sure? [Yes, do as I say!] "
	read _answer
	if (test "${_answer}" != "Yes, do as I say!"); then
		echo "Bailed out."
		exit -1
	fi
	
	announce "Install"
	
	if (test -e "external"); then
		umount external
		rm -rf external || exit -1
	fi
	mkdir -p external || exit -1
	
	parted ${2} mktable msdos || exit -1
	parted ${2} mkpart primary 18M 100% || exit -1
	mkfs.vfat ${2}1 || exit -1
	
	mount ${2}1 external || exit -1
	cp -rf R36S-U-Boot-PanelSupport-21802319a77c04b368adee9ef399d0d1d707644b/* external/ || exit -1
	umount external || exit -1
	
	dd if=${_whereSourceUBoot}/00.idbloader.img of=${2} conv=fsync bs=512 seek=64
	dd if=${_whereSourceUBoot}/01.uboot.img of=${2} conv=fsync bs=512 seek=16384
	dd if=${_whereSourceUBoot}/02.trust.img of=${2} conv=fsync bs=512 seek=24576
	
	sync
fi

announce "Done"
