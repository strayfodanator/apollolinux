#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Apollo Linux — Driver Installation Module for Calamares
# Module: apollo-drivers
#
# Reads GlobalStorage values set by apollo-detect and installs
# the correct driver package(s) + kernel into the target system.
# Uses the local driver cache embedded in the ISO.

import os
import subprocess
import libcalamares

# Path to the Apollo driver cache inside the ISO (available in live env)
DRIVER_CACHE_DIR = "/run/archiso/bootmnt/apollo-drivers"
DRIVER_CACHE_FALLBACK = "/opt/apollo-drivers"

# Pacman config pointing to the local driver repo
APOLLO_PACMAN_CONF = "/etc/apollo/pacman-drivers.conf"


def _chroot_run(root: str, cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """Run a command inside the target chroot."""
    full_cmd = ["arch-chroot", root] + cmd
    libcalamares.utils.debug(f"apollo-drivers: chroot cmd: {' '.join(full_cmd)}")
    return subprocess.run(full_cmd, capture_output=True, text=True, check=check)


def _pacman_install(root: str, packages: list[str], extra_conf: str | None = None) -> bool:
    """
    Install packages into the target system via pacman.
    Tries local cache first, then falls back to mirrors.
    """
    if not packages:
        return True

    conf_args = []
    if extra_conf and os.path.exists(extra_conf):
        conf_args = ["--config", extra_conf]

    cmd = (
        ["pacman", "--noconfirm", "--needed", "--noprogressbar"]
        + conf_args
        + ["-S"]
        + packages
    )

    result = _chroot_run(root, cmd, check=False)
    if result.returncode != 0:
        libcalamares.utils.warning(
            f"apollo-drivers: pacman failed for {packages}: {result.stderr}"
        )
        return False
    return True


def get_driver_packages(gs) -> list[str]:
    """
    Build the list of packages to install based on GlobalStorage values.
    Always includes mesa and related base packages.
    """
    driver = gs.value("apollo_gpu_driver") or "xf86-video-vesa"
    vendor = gs.value("apollo_gpu_vendor") or "other"
    kernel_pkg = gs.value("apollo_kernel_pkg") or "linux"

    packages = []

    # Always install mesa (base 3D/GL for compositing even with proprietary drivers)
    packages += ["mesa", "mesa-utils", "libva", "libva-utils"]

    if driver == "apollo-nvidia-390xx-dkms":
        packages += [
            f"{kernel_pkg}-headers",
            "dkms",
            "apollo-nvidia-390xx-dkms",
            "apollo-nvidia-390xx-utils",
            "libvdpau",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected NVIDIA 390xx (Apollo patched)")

    elif driver == "nvidia-470xx-dkms":
        packages += [
            f"{kernel_pkg}-headers",
            "dkms",
            "nvidia-470xx-dkms",
            "nvidia-470xx-utils",
            "lib32-nvidia-470xx-utils",
            "libvdpau",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected NVIDIA 470xx")

    elif driver == "nvidia":
        packages += [
            "nvidia",
            "nvidia-utils",
            "nvidia-settings",
            "lib32-nvidia-utils",
            "libvdpau",
        ]
        # nvidia-open for RTX (Turing+)
        packages.append("nvidia-open")
        libcalamares.utils.debug("apollo-drivers: Selected NVIDIA modern")

    elif driver == "xf86-video-amdgpu":
        packages += [
            "xf86-video-amdgpu",
            "vulkan-radeon",
            "libva-mesa-driver",
            "mesa-vdpau",
            "lib32-mesa",
            "lib32-vulkan-radeon",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected AMD (amdgpu)")

    elif driver == "xf86-video-ati":
        packages += [
            "xf86-video-ati",
            "mesa-vdpau",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected AMD legacy (ati)")

    elif driver == "intel-media-driver":
        packages += [
            "intel-media-driver",
            "vulkan-intel",
            "libva-intel-driver",
            "lib32-mesa",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected Intel modern")

    elif driver == "xf86-video-intel":
        packages += [
            "xf86-video-intel",
        ]
        libcalamares.utils.debug("apollo-drivers: Selected Intel legacy")

    else:
        # VESA fallback — minimal, always works
        packages += ["xf86-video-vesa"]
        libcalamares.utils.debug("apollo-drivers: Selected VESA fallback")

    return packages


def configure_nvidia_legacy(root: str, gs):
    """Post-install configuration for 390xx/470xx NVIDIA on the target system."""
    driver = gs.value("apollo_gpu_driver") or ""
    if "390xx" not in driver and "470xx" not in driver:
        return

    # Enable nvidia-persistenced for stability
    _chroot_run(root, ["systemctl", "enable", "nvidia-persistenced.service"], check=False)

    # Write initramfs modules config so nvidia is included
    modules_conf = os.path.join(root, "etc/mkinitcpio.conf.d/apollo-nvidia.conf")
    os.makedirs(os.path.dirname(modules_conf), exist_ok=True)
    with open(modules_conf, "w") as f:
        f.write("# Apollo Linux — nvidia legacy early KMS modules\n")
        f.write("MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)\n")

    # Regenerate initramfs for both kernels
    _chroot_run(root, ["mkinitcpio", "-P"], check=False)

    libcalamares.utils.debug("apollo-drivers: NVIDIA legacy post-config done")


def write_pacman_conf(root: str):
    """Add Apollo repo to the installed system's pacman.conf (commented out for now)."""
    pacman_conf_path = os.path.join(root, "etc/pacman.conf")
    apollo_repo_comment = """
# Apollo Linux Repository
# Uncomment when repo.apollolinux.org is available
# [apollo]
# Server = https://repo.apollolinux.org/$arch
# SigLevel = Required DatabaseOptional
"""
    try:
        with open(pacman_conf_path, "a") as f:
            f.write(apollo_repo_comment)
    except OSError as e:
        libcalamares.utils.warning(f"apollo-drivers: Could not update pacman.conf: {e}")


def run():
    gs = libcalamares.globalStorage
    root = gs.value("rootMountPoint") or "/mnt"

    libcalamares.utils.debug(f"apollo-drivers: Installing drivers into {root}")

    # Get the driver package list
    packages = get_driver_packages(gs)
    libcalamares.utils.debug(f"apollo-drivers: Packages to install: {packages}")

    # Report progress to Calamares UI
    libcalamares.job.setprogress(0.1)
    libcalamares.utils.debug("apollo-drivers: Installing driver packages...")

    # Try to install from local ISO cache first
    cache_dir = DRIVER_CACHE_DIR if os.path.isdir(DRIVER_CACHE_DIR) else DRIVER_CACHE_FALLBACK
    conf = APOLLO_PACMAN_CONF if os.path.exists(APOLLO_PACMAN_CONF) else None

    success = _pacman_install(root, packages, extra_conf=conf)
    if not success:
        # Fallback: try without local cache (requires internet)
        libcalamares.utils.warning("apollo-drivers: Local cache failed, trying mirrors...")
        success = _pacman_install(root, packages)

    libcalamares.job.setprogress(0.7)

    if success:
        libcalamares.utils.debug("apollo-drivers: Driver packages installed successfully")
    else:
        libcalamares.utils.warning(
            "apollo-drivers: Some driver packages may not have installed correctly. "
            "The system will fall back to VESA/nouveau."
        )

    # Post-install NVIDIA legacy configuration
    configure_nvidia_legacy(root, gs)
    libcalamares.job.setprogress(0.85)

    # Write Apollo pacman.conf stub
    write_pacman_conf(root)
    libcalamares.job.setprogress(1.0)

    return None  # None = success
