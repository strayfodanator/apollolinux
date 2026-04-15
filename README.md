# 🚀 Apollo Linux

<p align="center">
  <img src="apollo-themes/logo/apollo-logo.png" width="128" height="128" alt="Apollo Linux Logo">
</p>

<p align="center">
  <b>Fast. Beautiful. Compatible.</b><br>
  <i>An Arch-based distribution engineered for peak performance on legacy and modern hardware.</i>
</p>

---

## 🌟 Vision

Apollo Linux was born from a simple philosophy: **You shouldn't have to choose between a beautiful desktop and extreme hardware optimization.**

We took the bleeding-edge foundation of Arch Linux and crafted a curated, highly polished experience on top of it. Apollo is designed to run flawlessly on everything from a 10-year-old NVIDIA GT 610 to the latest hardware, offering a gorgeous, cohesive user interface via the **Apollo Shell** and a custom **Openbox** environment.

## 📸 Features

- **Apollo Shell**: A breathtaking, custom-built shell written in strict QML (`quickshell`). It features a modular Taskbar, macOS-style auto-hiding Dock, slide-in Sidebar, and rich widgets (App Menu, Weather, Hardware Monitors) without the bloat of traditional panels.
- **Dual Engine**: 
  - **Apollo Desktop (X11)**: Ultra-stable, blazing fast, Openbox-based. Perfect for legacy hardware and maximum compatibility. Uses ~350MB of RAM.
  - **Hyprland (Wayland)**: The future. Available out of the box for supported modern hardware, delivering smooth animations and modern features.
- **Deep Compatibility**: We actively maintain **modern kernel patches** (up to kernel 7.0+) for the legacy **NVIDIA 390xx** driver series, keeping older GPUs alive long past their end-of-life.
- **Smart Installer**: Our **Calamares** extension automatically detects your GPU, VRAM, and RAM, intelligently selecting the best driver and desktop architecture (X11 vs Wayland) for your specific machine before you even install.
- **Dynamic Theming**: First-class support for instant Dark/Light mode switching. A unified design system ensures that GTK3, GTK4, Qt5/6, and the shell always look perfectly cohesive.

## 🏗️ Structure

This Monorepo contains the entire Apollo OS stack:

* `apollo-iso/` - Archiso profile to build the live USB/install media.
* `apollo-shell/` - The QML source code for the Apollo Desktop shell.
* `apollo-desktop/` - Core apps: Control Center, Welcome screen, Session tools, and Window Manager configs.
* `apollo-themes/` - The unified Apollo design system (GTK, Qt, Openbox, Wallpapers, GRUB, Plymouth).
* `apollo-calamares/` - Custom installer modules and branding.
* `apollo-pkgbuild/` - Our custom Arch packages (including the legendary nvidia-390xx patched driver).

## 🚀 Building the ISO

You can build the Apollo Linux live medium directly from Arch Linux:

```bash
# Clone the repository
git clone https://github.com/strayfodanator/apollolinux.git
cd apollolinux

# Install archiso
sudo pacman -S archiso

# Build the ISO
sudo bash apollo-iso/build.sh
```

The resulting ISO will be placed in the `out/` directory.

## 🛠️ Contributing

Please read our [`CONTRIBUTING.md`](CONTRIBUTING.md) for details on our code of conduct, the development workflow, and how you can help test legacy hardware or expand the Apollo Shell.

## 📜 License

Apollo Linux is open-source software licensed under the GPL-3.0 (except where noted, such as specific community patches or external dependencies).

---
*Developed with love by the Apollo Linux Team.*
