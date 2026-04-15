#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Apollo Linux — archiso profile definition
# ISO profile based on Arch Linux 'releng' with Apollo customizations

iso_name="apollo-linux"
iso_label="APOLLO_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Apollo Linux <https://apollolinux.org>"
iso_application="Apollo Linux Live/Installer"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'bios.syslinux'
    'uefi.systemd-boot'
)
arch="x86_64"
pacman_conf="pacman.conf"

# SquashFS with maximum zstd compression
# -22: maximum compression level
# -b 1M: 1MB block size for better compression ratio
# --long: enable long-distance matching for better compression
airootfs_image_type="squashfs"
airootfs_image_tool_options=(
    '-comp' 'zstd'
    '-Xcompression-level' '22'
    '-b' '1048576'
    '-Xlong-distance'
)

bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
    ["/etc/apollo/detect-hardware.sh"]="0:0:755"
    ["/usr/local/bin/apollo-installer"]="0:0:755"
    ["/usr/local/bin/apollo-setup-user"]="0:0:755"
)
