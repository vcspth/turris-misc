#!/bin/bash
mkdir -p meta/1.0
rm -f meta/1.0/index-system*
mkdir -p images
rm -rf images/*

die() {
    echo "$1"
    exit 1
}

DATE="`date +%Y-%m-%d`"

add_image() {
    echo "$1;$2;$3;default;$DATE;/images/$1/$2/$3/$DATE" >> meta/1.0/index-system.2
    mkdir -p "images/$1/$2/$3/$DATE"
    pushd "images/$1/$2/$3/$DATE"
    if [ -f "$4" ]; then
        mv "$4" .
    else
        wget "$4" || die "Downloading $1 $2 for $3 from $4 failed"
    fi
    FILE="`ls -1`"
    if expr "$FILE" : .*\\.tbz || expr "$FILE" : .*\\.tar.bz2; then
        bzip2 -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tbz$|.tar|' -e 's|\.tar\.bz2$|.tar|'`"
    elif expr "$FILE" : .*\\.tgz || expr "$FILE" : .*\\.tar.gz; then
        gzip -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tgz$|.tar|' -e 's|\.tar\.gz$|.tar|'`"
    elif expr "$FILE" : .*\\.tar.xz; then
        mv "$FILE" rootfs.tar.xz
        FILE=rootfs.tar.xz
    fi
    if [ "$FILE" \!= rootfs.tar.xz ]; then
        mv "$FILE" rootfs.tar
        xz rootfs.tar
    fi
    echo "Distribution $1 version $2 was just installed as a container." > create-message
    echo "" >> create-message
    echo "Content of the tarballs is provided by third party, thus there is no warranty of any kind nor support from Turris team." >> create-message
    echo "" >> create-message
    echo "Do not use containers on internal flash, they can wear it down really fast!!!" >> create-message
    echo "lxc.arch = armv7l" > config
    expr `date +%s` + 1209600 > expiry
    tar -cJf meta.tar.xz create-message config expiry
    rm -f create-message config expiry
    popd
}

get_gentoo_url() {
    REL="`wget -O - http://distfiles.gentoo.org/releases/$1/autobuilds/latest-stage3-$2.txt | sed -n 's|\(.*\.tar.bz2\).*|\1|p'`"
    echo "http://distfiles.gentoo.org/releases/$1/autobuilds/$REL"
}

get_linaro_latest() {
    case "$1" in
        debian)
            echo https://releases.linaro.org/debian/images/developer-armhf/latest/
            ;;
        ubuntu)
            echo https://releases.linaro.org/ubuntu/images/developer/latest/
            ;;
    esac
}

get_linaro_release() {
    wget -O - `get_linaro_latest $1` | sed -n 's|.*href="/'"$1"'/images/.*/linaro-\([a-z]*\)-developer-[0-9]*-[0-9]*.tar.gz.*|\1|p'
}

get_linaro_url() {
    LIN_LATEST="`get_linaro_latest $1`"
    echo "https://releases.linaro.org`wget -O - $LIN_LATEST | sed -n 's|.*href="\(/'"$1"'/images/.*/latest/linaro-[a-z]*-developer-[0-9]*-[0-9]*.tar.gz\).*|\1|p'`"
}

get_lxc_url() {
    echo http://images.linuxcontainers.org/images/$1/default/`wget -O - http://images.linuxcontainers.org/images/$1/default | sed -n 's|.*href="\./\(20[^/]*\)/.*|\1|p' | sort | tail -n 1`/rootfs.tar.xz
}

get_arch() {
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-mirabox-latest.tar.gz && \
    gzip -d ArchLinuxARM-mirabox-latest.tar.gz && \
    sed -i 's|/dev/sda1[[:blank:]]\([[:blank:]]*\)/boot\([[:blank:]]*\)vfat|#/dev/sda1\1/boot\2vfat|' ArchLinuxARM-mirabox-latest.tar
}

add_image "Turris_OS" "stable" "armv7l" https://repo.turris.cz/omnia/medkit/omnia-medkit-latest.tar.gz
add_image "Turris_OS" "stable" "ppc" "https://repo.turris.cz/turris/medkit/medkit.tar.xz"
add_image "Alpine" "3.6" "armv7l" "http://dl-cdn.alpinelinux.org/alpine/v3.6/releases/armhf/alpine-minirootfs-3.6.2-armhf.tar.gz"
add_image "Alpine" "3.7" "armv7l" "http://dl-cdn.alpinelinux.org/alpine/v3.7/releases/armhf/alpine-minirootfs-3.7.0-armhf.tar.gz"
get_arch
add_image "ArchLinux" "latest" "armv7l" "`pwd`/ArchLinuxARM-mirabox-latest.tar"
add_image "Debian" "Jessie" "armv7l" "`get_lxc_url debian/jessie/armhf`"
add_image "Debian" "Stretch" "armv7l" "`get_lxc_url debian/stretch/armhf`"
add_image "Debian" "Buster" "armv7l" "`get_lxc_url debian/buster/armhf`"
add_image "Gentoo" "stable" "armv7l" "`get_gentoo_url arm armv7a_hardfp`"
add_image "openSUSE" "42.3" "armv7l" "http://download.opensuse.org/ports/armv7hl/distribution/leap/42.3/appliances/openSUSE-Leap42.3-ARM-JeOS.armv7-rootfs.armv7l.tbz"
add_image "openSUSE" "15.0" "armv7l" "http://download.opensuse.org/ports/armv7hl/distribution/leap/15.0/appliances/openSUSE-Leap15.0-ARM-JeOS.armv7-rootfs.armv7l-2018.07.02-Buildlp150.1.1.tar.xz"
add_image "openSUSE" "Tumbleweed" "armv7l" "http://download.opensuse.org/ports/armv7hl/tumbleweed/images/openSUSE-Tumbleweed-ARM-JeOS.armv7-rootfs.armv7l-Current.xz"
add_image "Sabayon" "16" "armv7l" "http://mirror.dkm.cz/sabayon/stable/Sabayon_Linux_16_armv7l.tar.bz2"
add_image "Ubuntu" "Xenial" "armv7l" "`get_lxc_url ubuntu/xenial/armhf`"
add_image "Ubuntu" "Artful" "armv7l" "`get_lxc_url ubuntu/artful/armhf`"
add_image "Ubuntu" "Bionic" "armv7l" "`get_lxc_url ubuntu/bionic/armhf`"

if [ "`gpg -K`" ]; then
if [ -f ~/gpg-pass ]; then
    find . -type f -exec echo cat ~/gpg-pass \| gpg  --batch --no-tty --yes --passphrase-fd 0 -a --detach-sign \{\} \; | sh
else
    find . -type f -exec gpg -a --detach-sign \{\} \;
fi
fi
