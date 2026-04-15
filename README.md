# 🚀 Apollo Linux

> The ZorinOS of Arch — Fast, Beautiful, and Built for Everyone.

Apollo Linux is an Arch-based distribution engineered for **maximum ease of use** without sacrificing performance or compatibility. It is one of the only distributions to offer first-class support for legacy NVIDIA hardware (390xx series, patched for kernel 6.x) alongside cutting-edge Wayland setups.

---

## ✨ Features

- **Zero manual configuration** — works out-of-the-box on hardware from a 2010 Core i5 + GT 610 to a modern Ryzen + RTX setup
- **Smart installer (Calamares)** — detects your GPU, RAM, and Wayland compatibility, then recommends the ideal desktop environment and installs only the drivers you need
- **Patched legacy NVIDIA drivers** — `apollo-nvidia-390xx-dkms` built and maintained for kernel 6.x (GT 610, GT 710, GTX 600/700 series)
- **Two official desktop environments**:
  - 🪐 **Apollo Desktop** — A heavily customized Openbox fork that looks and feels like a full DE (comparable to GNOME/KDE), yet runs on minimal hardware. Built on X11.
  - 🌊 **Hyprland Mode** — Hyprland + AX Shell for modern hardware with full Wayland support, GPU acceleration, and fluid animations.
- **Apollo Shell** — A QuickShell-based panel system with XFCE4-style configurability: add/remove panels, move widgets, install official plugins, all via a GUI.
- **Official Plugin System** — Pre-installed optional plugins (weather, media player, calendar, CPU graph, notes) with a public API for community plugins.

---

## 🖥️ System Requirements

### Apollo Desktop (Minimum)
| Component | Minimum |
|-----------|---------|
| CPU | Intel Core 2 Duo / AMD Athlon II |
| RAM | 2 GB (4 GB recommended) |
| GPU | Any GPU with VESA/VESA fallback |
| Storage | 15 GB |

### Apollo Desktop (Recommended — Legacy NVIDIA)
| Component | Spec |
|-----------|------|
| CPU | Intel Core i5 560 (Sandy Bridge) or equivalent |
| RAM | 8 GB DDR3 |
| GPU | NVIDIA GT 610 / GT 710 / GTX 650 (390xx driver) |
| Storage | 30 GB SSD |

### Hyprland Mode (Minimum)
| Component | Minimum |
|-----------|---------|
| CPU | Any x86_64 with 4+ cores |
| RAM | 6 GB |
| GPU | AMD Vega+ / Intel Gen 8+ / NVIDIA GTX 10xx+ |
| Storage | 25 GB |

---

## 📦 Repository Structure

```
apollolinux/
├── apollo-iso/              # ISO build system (archiso-based)
├── apollo-pkgbuild/         # Custom PKGBUILDs (NVIDIA legacy, etc.)
├── apollo-calamares/        # Calamares installer config & modules
├── apollo-desktop/          # Apollo Desktop (Openbox fork + patches)
├── apollo-shell/            # Apollo Shell (QuickShell panels & plugins)
├── apollo-themes/           # GTK themes, icons, cursors, wallpapers
├── apollo-welcome/          # First-boot welcome application
├── apollo-control/          # Apollo Control Center
└── docs/                    # Documentation
```

---

## 🏗️ Building the ISO

> Requirements: `archiso`, `git`, `base-devel`

```bash
git clone https://github.com/strayfodanator/apollolinux.git
cd apollolinux/apollo-iso
sudo ./build.sh
```

The ISO will be output to `apollo-iso/out/`.

---

## 🎨 Apollo Desktop

Apollo Desktop is a complete desktop environment built on a heavily patched fork of **Openbox**, featuring:

- **Snap Zones** — Drag windows to screen edges for tiling
- **Apollo Shell panels** — Configurable top/bottom bars via GUI
- **Comprehensive app stack** — File manager, terminal, text editor, screenshot tool, and more, all pre-configured
- **Apollo theme** — A clean, dark, dynamic aesthetic. No AI-generated look.
- **Icon Pack**: Papirus (GPL-3.0)
- **Cursor**: Bibata (MIT)
- **Font**: Fira Code Nerd Fonts (OFL)

---

## 🌊 Hyprland Mode

Coming once Apollo Desktop reaches 1.0 stability.

---

## 📜 License

- Apollo Linux build system & configs: **MIT**
- Apollo Desktop (Openbox fork): **GPL-2.0** (upstream license retained)
- Apollo Shell (QuickShell components): **MIT**
- Third-party assets: see individual licenses in `apollo-themes/`

---

## 🤝 Contributing

Contribution guidelines coming soon. The project is in early development.

---

*Apollo Linux — Built for humans, not just enthusiasts.*
