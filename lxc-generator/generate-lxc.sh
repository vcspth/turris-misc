#!/bin/bash
mkdir -p meta/1.0
rm -f meta/1.0/index-system*
mkdir -p images
rm -rf images/*

DATE="`date +%Y-%m-%d`"

add_image() {
    echo "$1;$2;$3;default;$DATE;/images/$1/$2/$3/$DATE" >> meta/1.0/index-system.2
    mkdir -p "images/$1/$2/$3/$DATE"
    pushd "images/$1/$2/$3/$DATE"
    wget "$4"
    FILE="`ls -1`"
    if expr "$FILE" : .*\\.tbz || expr "$FILE" : .*\\.tar.bz2; then
        bzip2 -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tbz$|.tar|' -e 's|\.tar\.bz2$|.tar|'`"
    elif expr "$FILE" : .*\\.tgz || expr "$FILE" : .*\\.tar.gz; then
        gzip -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tgz$|.tar|' -e 's|\.tar\.gz$|.tar|'`"
    fi
    mv "$FILE" rootfs.tar
    xz rootfs.tar
    echo "Distribution $1 version $2 was just installed into your container." > create-message
    echo "" >> create-message
    echo "Content of the tarballs is provided by third party, thus there is no warranty of any kind." >> create-message
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

get_omnia_url() {
    REL="`wget -O - https://api.turris.cz/openwrt-repo/omnia/ | sed -n 's|.*>\(omnia-medkit[^<]*\)<.*|\1|p'`"
    echo "https://api.turris.cz/openwrt-repo/omnia/$REL"
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

add_image "Turris_OS" "stable" "armv7l" "`get_omnia_url`"
add_image "Turris_OS" "stable" "ppc" "https://api.turris.cz/openwrt-repo/turris/openwrt-mpc85xx-p2020-nand-TURRISNAND-rootfs.tar.gz"
# Wrong structure, would need to be repacked
# add_image "Debian_by_Linaro" "`get_linaro_release debian`" "armv7l" "`get_linaro_url debian`"
add_image "Gentoo" "stable" "armv7l" "`get_gentoo_url arm armv7a_hardfp`"
add_image "openSUSE" "13.2" "armv7l" "http://download.opensuse.org/ports/armv7hl/distribution/13.2/appliances/openSUSE-13.2-ARM-JeOS.armv7-rootfs.armv7l-Current.tbz"
add_image "openSUSE" "Tumbleweed" "armv7l" "http://download.opensuse.org/ports/armv7hl/tumbleweed/images/openSUSE-Tumbleweed-ARM-JeOS.armv7-rootfs.armv7l-Current.tbz"
# Wrong structure, would need to be repacked
# add_image "Ubuntu_by_Linaro" "`get_linaro_release ubuntu`" "armv7l" "`get_linaro_url ubuntu`"

if [ "`gpg -K`" ]; then
if [ -f ~/gpg-pass ]; then
    find . -type f -exec echo cat ~/gpg-pass \| gpg  --batch --no-tty --yes --passphrase-fd 0 -a --detach-sign \{\} \; | sh
else
    find . -type f -exec gpg -a --detach-sign \{\} \;
fi
fi
