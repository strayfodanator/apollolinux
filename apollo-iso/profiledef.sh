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
    'bios.syslinux.mbr'
    'bios.syslinux.eltorito'
    'uefi-ia32.grub.esp'
    'uefi-x64.grub.esp'
    'uefi-ia32.grub.eltorito'
    'uefi-x64.grub.eltorito'
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
    ["/etc/shadow"]="0:0:400"
    ["/etc/gshadow"]="0:0:400"
    ["/root"]="0:0:750"
    ["/root/.automated_script.sh"]="0:0:755"
    ["/root/.gnupg"]="0:0:700"
    ["/etc/apollo/detect-hardware.sh"]="0:0:755"
    ["/usr/local/bin/apollo-installer"]="0:0:755"
    ["/usr/local/bin/apollo-driver-detect"]="0:0:755"
    ["/etc/calamares/scripts/apollo-detect.py"]="0:0:755"
    ["/etc/calamares/scripts/apollo-drivers.py"]="0:0:755"
)
