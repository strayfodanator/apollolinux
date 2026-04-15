#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Apollo Linux — Desktop Selection Module for Calamares
# Module: apollo-desktop-select
#
# Reads GlobalStorage from apollo-detect and installs the selected desktop.
# Also configures the display manager, autostart entries, and session files.

import os
import subprocess
import shutil
import libcalamares


APOLLO_DESKTOP_PACKAGES = [
    # Openbox core (Apollo fork — from local repo)
    "apollo-openbox",
    "obconf-qt",
    # Compositor
    "picom",
    # Panel system
    "apollo-shell",  # QuickShell-based panel (Apollo build)
    # Notifications
    "dunst",
    "libnotify",
    # App launcher
    "ulauncher",
    # Wallpaper
    "nitrogen",
    # Apps
    "thunar",
    "thunar-archive-plugin",
    "thunar-volman",
    "gvfs",
    "gvfs-mtp",
    "alacritty",
    "kate",
    "eog",
    "file-roller",
    "flameshot",
    "blueman",
    "pavucontrol",
    "nm-applet",
    # Themes & assets
    "apollo-themes",          # GTK + Openbox themes (Apollo package)
    "papirus-icon-theme",
    "bibata-cursor-theme",
    "ttf-firacode-nerd",
    # Display manager
    "lightdm",
    "lightdm-gtk-greeter",
    "lightdm-gtk-greeter-settings",
    # Qt theming
    "qt5ct",
    "kvantum",
    # GTK theming
    "lxappearance",
    "adw-gtk3",
    # Polkit agent
    "polkit-gnome",
    # System tools
    "htop",
    "gparted",
]

HYPRLAND_PACKAGES = [
    # Hyprland
    "hyprland",
    "hyprpaper",
    "hyprlock",
    "hypridle",
    # AX Shell (Apollo build)
    "ax-shell",
    # Supporting tools
    "wofi",
    "waybar",
    "wl-clipboard",
    "foot",
    "swaync",
    # XDG portals
    "xdg-desktop-portal-hyprland",
    "xdg-desktop-portal-gtk",
    # Wayland compat
    "qt5-wayland",
    "qt6-wayland",
    # Apps (same as Apollo Desktop)
    "thunar",
    "thunar-archive-plugin",
    "thunar-volman",
    "gvfs",
    "gvfs-mtp",
    "kate",
    "eog",
    "file-roller",
    "flameshot",
    "grim",
    "slurp",
    "blueman",
    "pavucontrol",
    # Themes
    "apollo-themes",
    "papirus-icon-theme",
    "bibata-cursor-theme",
    "ttf-firacode-nerd",
    # Display manager (SDDM for Wayland)
    "sddm",
    "sddm-astronaut-theme",  # or Apollo custom SDDM theme
    # System
    "polkit-gnome",
    "htop",
    "gparted",
    "ulauncher",
]


def _chroot_run(root: str, cmd: list[str], check: bool = False):
    full = ["arch-chroot", root] + cmd
    libcalamares.utils.debug(f"apollo-desktop: chroot: {' '.join(full)}")
    return subprocess.run(full, capture_output=True, text=True, check=check)


def _pacman_install(root: str, pkgs: list[str]) -> bool:
    if not pkgs:
        return True
    result = _chroot_run(root, [
        "pacman", "--noconfirm", "--needed", "--noprogressbar", "-S"
    ] + pkgs)
    if result.returncode != 0:
        libcalamares.utils.warning(
            f"apollo-desktop: install failed: {result.stderr[:500]}"
        )
    return result.returncode == 0


def install_apollo_desktop(root: str):
    """Install Apollo Desktop packages and configure X11 session."""
    libcalamares.utils.debug("apollo-desktop: Installing Apollo Desktop...")
    _pacman_install(root, APOLLO_DESKTOP_PACKAGES)

    # Enable LightDM
    _chroot_run(root, ["systemctl", "enable", "lightdm.service"])

    # Write .xinitrc for manual startx
    xinitrc = os.path.join(root, "etc/skel/.xinitrc")
    with open(xinitrc, "w") as f:
        f.write("#!/bin/sh\n")
        f.write("# Apollo Desktop session\n")
        f.write("exec openbox-session\n")

    # Write desktop session file
    session_dir = os.path.join(root, "usr/share/xsessions")
    os.makedirs(session_dir, exist_ok=True)
    with open(os.path.join(session_dir, "apollo-desktop.desktop"), "w") as f:
        f.write("[Desktop Entry]\n")
        f.write("Name=Apollo Desktop\n")
        f.write("Comment=Lightweight desktop environment by Apollo Linux\n")
        f.write("Exec=openbox-session\n")
        f.write("TryExec=openbox\n")
        f.write("Type=Application\n")
        f.write("DesktopNames=Apollo;Openbox\n")

    # Copy Apollo Shell config
    shell_config_src = "/usr/share/apollo/shell"
    shell_config_dst = os.path.join(root, "etc/skel/.config/apollo-shell")
    if os.path.isdir(shell_config_src):
        shutil.copytree(shell_config_src, shell_config_dst, dirs_exist_ok=True)

    # Copy default Openbox config
    openbox_config_src = "/usr/share/apollo/openbox"
    openbox_config_dst = os.path.join(root, "etc/skel/.config/openbox")
    if os.path.isdir(openbox_config_src):
        shutil.copytree(openbox_config_src, openbox_config_dst, dirs_exist_ok=True)

    libcalamares.utils.debug("apollo-desktop: Apollo Desktop installation complete")


def install_hyprland(root: str):
    """Install Hyprland + AX Shell and configure Wayland session."""
    libcalamares.utils.debug("apollo-desktop: Installing Hyprland mode...")
    _pacman_install(root, HYPRLAND_PACKAGES)

    # Enable SDDM
    _chroot_run(root, ["systemctl", "enable", "sddm.service"])

    # Hyprland session is registered automatically by the hyprland package
    # Copy Apollo Hyprland config
    hypr_config_src = "/usr/share/apollo/hyprland"
    hypr_config_dst = os.path.join(root, "etc/skel/.config/hypr")
    if os.path.isdir(hypr_config_src):
        shutil.copytree(hypr_config_src, hypr_config_dst, dirs_exist_ok=True)

    libcalamares.utils.debug("apollo-desktop: Hyprland installation complete")


def configure_theming(root: str, desktop: str):
    """Write GTK/Qt theme defaults for new users."""
    settings_dir = os.path.join(root, "etc/skel/.config")
    os.makedirs(settings_dir, exist_ok=True)

    # GTK3 settings
    gtk3_dir = os.path.join(settings_dir, "gtk-3.0")
    os.makedirs(gtk3_dir, exist_ok=True)
    with open(os.path.join(gtk3_dir, "settings.ini"), "w") as f:
        f.write("[Settings]\n")
        f.write("gtk-theme-name=Apollo-Dark\n")
        f.write("gtk-icon-theme-name=Papirus-Dark\n")
        f.write("gtk-cursor-theme-name=Bibata-Modern-Classic\n")
        f.write("gtk-cursor-theme-size=24\n")
        f.write("gtk-font-name=FiraCode Nerd Font 10\n")
        f.write("gtk-application-prefer-dark-theme=1\n")
        f.write("gtk-button-images=1\n")
        f.write("gtk-menu-images=1\n")

    # GTK4 settings
    gtk4_dir = os.path.join(settings_dir, "gtk-4.0")
    os.makedirs(gtk4_dir, exist_ok=True)
    with open(os.path.join(gtk4_dir, "settings.ini"), "w") as f:
        f.write("[Settings]\n")
        f.write("gtk-theme-name=Apollo-Dark\n")
        f.write("gtk-icon-theme-name=Papirus-Dark\n")
        f.write("gtk-cursor-theme-name=Bibata-Modern-Classic\n")
        f.write("gtk-font-name=FiraCode Nerd Font 10\n")
        f.write("gtk-application-prefer-dark-theme=1\n")

    # Qt5ct config
    qt5ct_dir = os.path.join(settings_dir, "qt5ct")
    os.makedirs(qt5ct_dir, exist_ok=True)
    with open(os.path.join(qt5ct_dir, "qt5ct.conf"), "w") as f:
        f.write("[Appearance]\n")
        f.write("icon_theme=Papirus-Dark\n")
        f.write("style=kvantum\n")
        f.write("[Fonts]\n")
        f.write("fixed=\"FiraCode Nerd Font,10,-1,5,50,0,0,0,0,0\"\n")
        f.write("general=\"FiraCode Nerd Font,10,-1,5,50,0,0,0,0,0\"\n")

    # Environment variables for theming consistency
    env_dir = os.path.join(root, "etc/environment.d")
    os.makedirs(env_dir, exist_ok=True)
    with open(os.path.join(env_dir, "apollo-theming.conf"), "w") as f:
        f.write("# Apollo Linux — Theme environment variables\n")
        f.write("QT_QPA_PLATFORMTHEME=qt5ct\n")
        f.write("GTK_THEME=Apollo-Dark\n")
        f.write("XCURSOR_THEME=Bibata-Modern-Classic\n")
        f.write("XCURSOR_SIZE=24\n")
        if desktop == "hyprland":
            f.write("QT_QPA_PLATFORM=wayland;xcb\n")
            f.write("GDK_BACKEND=wayland,x11\n")
            f.write("MOZ_ENABLE_WAYLAND=1\n")
            f.write("ELECTRON_OZONE_PLATFORM_HINT=auto\n")


def run():
    gs = libcalamares.globalStorage
    root = gs.value("rootMountPoint") or "/mnt"

    # Check if user made a selection in the Calamares UI (overrides auto-detect)
    desktop = gs.value("apollo_desktop_chosen") or gs.value("apollo_desktop_default") or "apollo-desktop"
    libcalamares.utils.debug(f"apollo-desktop: Installing desktop: {desktop} into {root}")

    libcalamares.job.setprogress(0.05)

    if desktop == "hyprland":
        install_hyprland(root)
    else:
        install_apollo_desktop(root)

    libcalamares.job.setprogress(0.85)
    configure_theming(root, desktop)
    libcalamares.job.setprogress(1.0)

    # Store final choice for post-install modules
    gs.insert("apollo_desktop_installed", desktop)

    return None
