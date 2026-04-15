# Contributing to Apollo Linux

Thank you for your interest in contributing to Apollo Linux! 🚀

## Ways to Contribute

| Area | How to help |
|---|---|
| **Bug reports** | Open an issue with hardware info + logs |
| **NVIDIA patches** | Test `apollo-nvidia-390xx-dkms` on real hardware |
| **QML widgets** | Add plugins to `apollo-shell/plugins/` |
| **GTK themes** | Improve `apollo-themes/gtk/apollo-dark/gtk.css` |
| **Documentation** | Improve README, write wiki pages |
| **Translations** | Translate Calamares strings |

## Development Setup

```bash
# Clone the repo
git clone https://github.com/strayfodanator/apollolinux.git
cd apollolinux

# Install build deps (Arch Linux)
sudo pacman -S archiso calamares python-gobject gtk4 libadwaita \
               quickshell openbox picom dunst alacritty

# Build a test ISO (requires root)
sudo bash apollo-iso/build.sh

# Or just test desktop configs in a VM:
cp -r apollo-desktop/config ~/.config/
openbox --replace &
quickshell -config apollo-shell/main.qml &
```

## Project Structure

```
apollolinux/
├── apollo-iso/          # archiso profile (profiledef.sh, build.sh, packages)
│   └── airootfs/        # Files copied verbatim into live environment
├── apollo-pkgbuild/     # All PKGBUILDs
│   ├── nvidia-390xx-dkms/  # Legacy NVIDIA (GT 610/710/720)
│   ├── nvidia-470xx-dkms/  # Legacy NVIDIA (GTX 900/1000)
│   ├── apollo-openbox/     # Openbox fork with snap zones
│   └── apollo-themes/      # GTK/Openbox/wallpaper bundle
├── apollo-calamares/    # Installer modules (Python)
│   ├── modules/
│   │   ├── apollo-detect/       # Hardware detection
│   │   ├── apollo-drivers/      # Driver installer
│   │   └── apollo-desktop-select/  # Desktop installer
│   ├── branding/apollo/    # Branding (logo, colors, strings)
│   └── settings.conf       # Installer pipeline
├── apollo-desktop/      # Apollo Desktop (Openbox mode) configs
│   ├── config/          # picom, dunst, openbox, alacritty
│   ├── hyprland/        # Hyprland mode configs
│   ├── apollo-welcome   # First-boot welcome app (Python/GTK4)
│   └── apollo-control   # Control Center (Python/GTK4)
├── apollo-shell/        # QuickShell panels and widgets
│   ├── main.qml         # Entry point
│   ├── panels/          # Taskbar, TopBar, Dock, Sidebar
│   ├── widgets/         # Individual widget components
│   ├── plugins/         # Optional plugins (weather, media, etc.)
│   └── config/          # apollo-shell.json
└── apollo-themes/       # Theme assets
    ├── gtk/apollo-dark/ # GTK3/4 CSS theme
    ├── openbox/         # Openbox themerc
    └── wallpapers/      # Official wallpapers
```

## NVIDIA 390xx Patches

The most critical contribution area. Current patches cover kernels 5.18 → 6.12.

**To add a new kernel patch:**
1. Build the kernel module against the new kernel version
2. Find the compile error
3. Create `apollo-pkgbuild/nvidia-390xx-dkms/patches/NNNN-kernel-X.Y-description.patch`
4. Update `PKGBUILD` source array

**Test hardware:** GT 610, GT 710, GT 720, GTX 650, GTX 660

## Commit Convention

```
feat: add new feature
fix: bug fix
patch: kernel compatibility patch
theme: visual/styling change
docs: documentation update
ci: CI/CD changes
```

## Code Style

- **Python**: PEP 8, type hints where practical
- **QML**: 4-space indent, property declarations at top
- **Bash**: `set -euo pipefail`, functions for reusable code
- **Patches**: Minimal, one concern per patch file

## Hardware Testing Matrix

| GPU | Driver | Expected | Tested |
|---|---|---|---|
| NVIDIA GT 610 | nvidia-390xx | X11 only | ❌ Need testers |
| NVIDIA GT 710 | nvidia-390xx | X11 only | ❌ Need testers |
| NVIDIA GTX 1060 | nvidia | Wayland OK | ❌ Need testers |
| AMD RX 580 | amdgpu | Wayland OK | ❌ Need testers |
| Intel HD 630 | i915 | Wayland OK | ❌ Need testers |

Help us fill this matrix! See [Issues](https://github.com/strayfodanator/apollolinux/issues).

## License

Apollo Linux is **GPL-2.0**. By contributing, you agree your code will be
distributed under this license.
