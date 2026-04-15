#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Apollo Linux — Hardware Detection Module for Calamares
# Module: apollo-detect
#
# This module runs early in the Calamares pipeline and does:
#   1. Detect GPU (vendor, model, PCI ID, driver tier)
#   2. Detect RAM (total MB)
#   3. Score CPU performance (low / medium / high)
#   4. Check Wayland compatibility (kernel DRM support + driver)
#   5. Set global Calamares variables used by downstream modules:
#        - apollo_gpu_vendor       (nvidia/amd/intel/other)
#        - apollo_gpu_model        (human-readable string)
#        - apollo_gpu_driver       (nvidia/nvidia-470xx/apollo-nvidia-390xx/amdgpu/intel/vesa)
#        - apollo_gpu_pci_id       (e.g. "10de:1244")
#        - apollo_gpu_wayland_ok   (True/False)
#        - apollo_ram_mb           (int)
#        - apollo_cpu_score        (low/medium/high)
#        - apollo_kernel_pkg       (linux / linux-lts)
#        - apollo_desktop_default  (apollo-desktop / hyprland)
#        - apollo_desktop_locked   (True if hardware forces a specific desktop)
#        - apollo_recommend_reason (human-readable reason string)

import re
import os
import subprocess
import libcalamares

# ──────────────────────────────────────────────────────────────────────────────
# PCI ID Database: NVIDIA driver tiers
# Format: (vendor_id, device_id_prefix_or_exact) → driver_pkg
#
# Full list maintained here; Apollo extends it with community-reported IDs.
# ──────────────────────────────────────────────────────────────────────────────

NVIDIA_390XX_PCI_IDS = {
    # GT 610 / 620 / 630 (Fermi/Kepler entry)
    "10de:1244", "10de:1245", "10de:1246", "10de:1247",
    "10de:0fc1", "10de:0fc2", "10de:0fc6", "10de:0fc8", "10de:0fc9",
    "10de:0fcd", "10de:0fce", "10de:0fd1", "10de:0fd2", "10de:0fd3",
    "10de:0fd4", "10de:0fd5", "10de:0fd8", "10de:0fd9",
    # GT 710 / 720 / 730
    "10de:128b", "10de:128f", "10de:1290", "10de:1291", "10de:1292",
    "10de:1293", "10de:1294", "10de:1295", "10de:1296", "10de:1298",
    "10de:1299", "10de:129a", "10de:1380", "10de:1381", "10de:1382",
    # GTX 650 / 660 / 670 / 680 / 690 (Kepler)
    "10de:11c0", "10de:11c2", "10de:11c3", "10de:11c4", "10de:11c5",
    "10de:11c6", "10de:11c7", "10de:11c8", "10de:11cb", "10de:1185",
    "10de:1187", "10de:1188", "10de:1189", "10de:118a", "10de:1183",
    "10de:1184", "10de:1086", "10de:1087", "10de:1088", "10de:1089",
    "10de:108b", "10de:1040", "10de:1042", "10de:1048", "10de:1049",
    # GTX 750 / 750 Ti (Maxwell 1st gen — still 390xx on legacy branch)
    "10de:1380", "10de:1381", "10de:1382", "10de:1390", "10de:1391",
    "10de:1392", "10de:1393", "10de:1398", "10de:139a", "10de:139b",
    "10de:139c", "10de:139d",
}

NVIDIA_470XX_PCI_IDS = {
    # GTX 900 series (Maxwell 2nd gen)
    "10de:17c8", "10de:17c2", "10de:17f0", "10de:17fd",
    "10de:1401", "10de:1402", "10de:1406", "10de:1407",
    "10de:1617", "10de:1618", "10de:1619", "10de:161a",
    "10de:1b81", "10de:1b82", "10de:1b83", "10de:1b84",
    # GTX 10xx series (Pascal)
    "10de:1b00", "10de:1b02", "10de:1b06",
    "10de:1c02", "10de:1c03", "10de:1c04", "10de:1c06", "10de:1c07",
    "10de:1c09", "10de:1c20", "10de:1c21", "10de:1c22", "10de:1c23",
    "10de:1c30", "10de:1c31", "10de:1c35", "10de:1c60", "10de:1c61",
    "10de:1c62", "10de:1c81", "10de:1c82", "10de:1c83", "10de:1c8c",
    "10de:1c8d", "10de:1c8f", "10de:1c90", "10de:1c91", "10de:1c92",
    "10de:1c96", "10de:1cb1", "10de:1cb2", "10de:1cb3",
    "10de:1d01", "10de:1d02", "10de:1d10", "10de:1d11", "10de:1d12",
    "10de:1d13", "10de:1d16", "10de:1d52",
}

WAYLAND_INCOMPATIBLE_DRIVERS = {"apollo-nvidia-390xx-dkms", "xf86-video-vesa", "xf86-video-ati"}


# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def _run(cmd: list[str]) -> str:
    """Run a shell command, return stdout or empty string on error."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return result.stdout.strip()
    except Exception:
        return ""


def _read_file(path: str) -> str:
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def detect_gpus() -> list[dict]:
    """
    Parse lspci output to find all display controllers.
    Returns a list of dicts: {vendor_id, device_id, pci_id, description}
    """
    gpus = []
    lspci = _run(["lspci", "-mm", "-n"])
    # Format: slot "Class" "Vendor" "Device" "SVendor" "SDevice"
    for line in lspci.splitlines():
        parts = [p.strip('"') for p in re.split(r'\s+', line, maxsplit=1)]
        # Also parse the full lspci -mm -n for class 0300/0302
        pass

    # Prefer: lspci -mm -n for numeric IDs
    lspci_n = _run(["lspci", "-mm", "-n"])
    for line in lspci_n.splitlines():
        # Example: "00:02.0" "0300" "8086" "1912" ...
        m = re.match(r'^"[^"]*"\s+"0[23]\d\d"\s+"([0-9a-f]{4})"\s+"([0-9a-f]{4})"', line, re.I)
        if m:
            vendor_id = m.group(1).lower()
            device_id = m.group(2).lower()
            gpus.append({
                "vendor_id": vendor_id,
                "device_id": device_id,
                "pci_id": f"{vendor_id}:{device_id}",
            })

    # Add human-readable descriptions
    lspci_v = _run(["lspci", "-mm"])
    desc_map = {}
    for line in lspci_v.splitlines():
        m = re.match(r'^"([^"]*)".*?"[^"]*"\s+"([^"]+)"\s+"([^"]+)"', line)
        if m:
            desc_map[m.group(1)] = f"{m.group(2)} {m.group(3)}"

    return gpus


def classify_gpu(gpu: dict) -> dict:
    """
    Given a GPU dict with pci_id, determine:
      - vendor (nvidia/amd/intel/other)
      - driver package
      - wayland_compatible
    """
    vid = gpu["vendor_id"]
    pci_id = gpu["pci_id"]
    result = {**gpu}

    if vid == "10de":  # NVIDIA
        result["vendor"] = "nvidia"
        if pci_id in NVIDIA_390XX_PCI_IDS:
            result["driver"] = "apollo-nvidia-390xx-dkms"
            result["wayland_ok"] = False
            result["driver_label"] = "NVIDIA Legacy 390xx (Apollo patched)"
            result["tier"] = "legacy-390xx"
        elif pci_id in NVIDIA_470XX_PCI_IDS:
            result["driver"] = "nvidia-470xx-dkms"
            result["wayland_ok"] = False  # 470xx on Wayland is unstable
            result["driver_label"] = "NVIDIA Legacy 470xx"
            result["tier"] = "legacy-470xx"
        else:
            # Assume modern NVIDIA (RTX/GTX 16xx+)
            result["driver"] = "nvidia"
            result["wayland_ok"] = True
            result["driver_label"] = "NVIDIA Proprietary (Modern)"
            result["tier"] = "modern"

    elif vid == "1002":  # AMD
        result["vendor"] = "amd"
        # Check if it's a very old AMD (needs xf86-video-ati)
        # HD 4000/5000/6000/7000 pre-GCN series
        old_amd_prefixes = {"68", "94", "95", "96", "97", "98", "99", "aa", "ac", "ad", "9e"}
        if gpu["device_id"][:2] in old_amd_prefixes:
            result["driver"] = "xf86-video-ati"
            result["wayland_ok"] = False
            result["driver_label"] = "AMD Legacy (radeon)"
            result["tier"] = "legacy-amd"
        else:
            result["driver"] = "xf86-video-amdgpu"
            result["wayland_ok"] = True
            result["driver_label"] = "AMD Open Source (amdgpu)"
            result["tier"] = "modern"

    elif vid == "8086":  # Intel
        result["vendor"] = "intel"
        # Gen ≤ 7: needs xf86-video-intel; Gen 8+: iris/i915 is fine
        # Device IDs for Gen ≤ 7: < 0x0400 roughly
        try:
            dev_int = int(gpu["device_id"], 16)
        except ValueError:
            dev_int = 0xFFFF

        if dev_int < 0x0400:
            result["driver"] = "xf86-video-intel"
            result["wayland_ok"] = False
            result["driver_label"] = "Intel Legacy (xf86-video-intel)"
            result["tier"] = "legacy-intel"
        else:
            result["driver"] = "intel-media-driver"
            result["wayland_ok"] = True
            result["driver_label"] = "Intel Open Source (i915/iris)"
            result["tier"] = "modern"
    else:
        result["vendor"] = "other"
        result["driver"] = "xf86-video-vesa"
        result["wayland_ok"] = False
        result["driver_label"] = "Generic VESA (fallback)"
        result["tier"] = "vesa"

    return result


def detect_ram_mb() -> int:
    """Return total RAM in MB from /proc/meminfo."""
    meminfo = _read_file("/proc/meminfo")
    m = re.search(r"MemTotal:\s+(\d+)\s+kB", meminfo)
    return int(m.group(1)) // 1024 if m else 0


def score_cpu() -> str:
    """
    Simple CPU performance tier: low / medium / high
    Based on core count and a rough benchmark via /proc/cpuinfo model name.
    """
    cpuinfo = _read_file("/proc/cpuinfo")

    # Count physical cores (unique core id entries)
    core_ids = set(re.findall(r"core id\s*:\s*(\d+)", cpuinfo))
    core_count = len(core_ids) if core_ids else cpuinfo.count("processor\t:")

    # Extract model name for generation hints
    model_match = re.search(r"model name\s*:\s*(.+)", cpuinfo)
    model = model_match.group(1).strip().lower() if model_match else ""

    # Rough generation scoring from model name
    # Very old: Core 2 Duo, Pentium 4, Athlon 64, Atom
    is_very_old = any(x in model for x in [
        "core2", "core 2", "pentium 4", "athlon 64", "athlon ii",
        "phenom", "atom", "celeron", "sempron"
    ])
    # Old-ish: Core i3/i5/i7 first-second gen, Athlon X4
    is_old = any(x in model for x in [
        "core(tm) i3", "core(tm) i5", "core(tm) i7",
        "fx-", "a4-", "a6-", "a8-", "a10-"
    ])

    if core_count <= 2 or is_very_old:
        return "low"
    elif core_count <= 4 or is_old:
        return "medium"
    else:
        return "high"


def recommend_desktop(gpu: dict, ram_mb: int, cpu_score: str) -> tuple[str, bool, str]:
    """
    Returns (desktop_default, desktop_locked, reason_string)
    desktop_default: 'apollo-desktop' | 'hyprland'
    desktop_locked: True = user cannot change (hardware forces this)
    """
    driver = gpu.get("driver", "xf86-video-vesa")
    wayland_ok = gpu.get("wayland_ok", False)
    vendor = gpu.get("vendor", "other")

    # Definite Apollo Desktop cases (hardware limitation)
    if driver in {"apollo-nvidia-390xx-dkms", "xf86-video-vesa"}:
        return (
            "apollo-desktop",
            True,  # locked — no Wayland possible
            f"Sua GPU ({gpu.get('driver_label', 'desconhecida')}) não suporta Wayland. "
            f"Apollo Desktop (X11) é o único modo compatível.",
        )

    if driver == "xf86-video-ati":
        return (
            "apollo-desktop",
            True,
            "Sua GPU AMD legada não tem suporte estável a Wayland. "
            "Apollo Desktop (X11) recomendado.",
        )

    if driver == "nvidia-470xx-dkms":
        return (
            "apollo-desktop",
            False,  # Not locked, but strongly recommended
            "Sua GPU NVIDIA (driver 470xx) tem suporte limitado a Wayland. "
            "Apollo Desktop (X11) é recomendado para estabilidade.",
        )

    # Resource-constrained
    if ram_mb < 4096:
        return (
            "apollo-desktop",
            False,
            f"Memória RAM baixa ({ram_mb}MB). Apollo Desktop usa menos de 300MB em idle.",
        )

    if cpu_score == "low":
        return (
            "apollo-desktop",
            False,
            "CPU com poucos núcleos/performance limitada. "
            "Apollo Desktop é mais eficiente para este hardware.",
        )

    # Modern hardware with good Wayland support
    if wayland_ok and ram_mb >= 6144 and cpu_score in {"medium", "high"}:
        if vendor == "amd":
            reason = (
                f"GPU AMD detectada com suporte nativo a Wayland. "
                f"Hyprland é recomendado para a melhor experiência visual."
            )
        elif vendor == "intel" and gpu.get("tier") == "modern":
            reason = (
                f"GPU Intel moderna com suporte a Wayland via i915/iris. "
                f"Hyprland é compatível."
            )
        else:
            reason = (
                f"Hardware compatível com Wayland ({ram_mb}MB RAM, CPU {cpu_score}). "
                f"Hyprland recomendado."
            )
        return ("hyprland", False, reason)

    # Fallback: Apollo Desktop (safe choice)
    return (
        "apollo-desktop",
        False,
        "Apollo Desktop recomendado como opção mais estável para este hardware.",
    )


def select_kernel(gpu: dict) -> str:
    """
    Returns the kernel package to install:
      - linux-lts: for legacy NVIDIA (390xx/470xx) — more stable for DKMS patches
      - linux: for modern hardware
    """
    driver = gpu.get("driver", "")
    if driver in {"apollo-nvidia-390xx-dkms", "nvidia-470xx-dkms"}:
        return "linux-lts"
    return "linux"


# ──────────────────────────────────────────────────────────────────────────────
# Calamares entry point
# ──────────────────────────────────────────────────────────────────────────────

def run():
    libcalamares.utils.debug("Apollo Detect: Starting hardware detection...")

    gpus = detect_gpus()
    libcalamares.utils.debug(f"Apollo Detect: Found {len(gpus)} GPU(s): {gpus}")

    # Pick the primary GPU (prefer discrete over integrated)
    primary_gpu = {}
    if gpus:
        classified = [classify_gpu(g) for g in gpus]
        # Sort: nvidia > amd > intel > other (prefer discrete)
        priority = {"nvidia": 0, "amd": 1, "intel": 2, "other": 3}
        classified.sort(key=lambda g: priority.get(g.get("vendor", "other"), 3))
        primary_gpu = classified[0]
    else:
        # No GPU detected — use VESA fallback
        primary_gpu = {
            "vendor": "other",
            "vendor_id": "0000",
            "device_id": "0000",
            "pci_id": "0000:0000",
            "driver": "xf86-video-vesa",
            "wayland_ok": False,
            "driver_label": "Generic VESA (no GPU detected)",
            "tier": "vesa",
        }

    ram_mb = detect_ram_mb()
    cpu_score = score_cpu()
    desktop_default, desktop_locked, reason = recommend_desktop(primary_gpu, ram_mb, cpu_score)
    kernel_pkg = select_kernel(primary_gpu)

    libcalamares.utils.debug(
        f"Apollo Detect: GPU={primary_gpu.get('pci_id')} "
        f"driver={primary_gpu.get('driver')} "
        f"RAM={ram_mb}MB CPU={cpu_score} "
        f"→ desktop={desktop_default} kernel={kernel_pkg}"
    )

    # Write results to Calamares global storage
    gs = libcalamares.globalStorage
    gs.insert("apollo_gpu_vendor",      primary_gpu.get("vendor", "other"))
    gs.insert("apollo_gpu_model",       primary_gpu.get("driver_label", "Unknown GPU"))
    gs.insert("apollo_gpu_driver",      primary_gpu.get("driver", "xf86-video-vesa"))
    gs.insert("apollo_gpu_pci_id",      primary_gpu.get("pci_id", ""))
    gs.insert("apollo_gpu_wayland_ok",  primary_gpu.get("wayland_ok", False))
    gs.insert("apollo_ram_mb",          ram_mb)
    gs.insert("apollo_cpu_score",       cpu_score)
    gs.insert("apollo_kernel_pkg",      kernel_pkg)
    gs.insert("apollo_desktop_default", desktop_default)
    gs.insert("apollo_desktop_locked",  desktop_locked)
    gs.insert("apollo_recommend_reason", reason)

    return None  # Success
