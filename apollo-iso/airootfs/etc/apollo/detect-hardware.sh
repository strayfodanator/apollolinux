#!/usr/bin/env bash
#
# Apollo Linux — detect-hardware.sh
# Installed to: /etc/apollo/detect-hardware.sh
#
# Standalone hardware detection script used by:
#   - The live environment (info display on desktop)
#   - Calamares pre-check before the installer opens
#
# Output format (parseable):
#   GPU_VENDOR=nvidia
#   GPU_MODEL=NVIDIA GeForce GT 610
#   GPU_DRIVER=apollo-nvidia-390xx-dkms
#   GPU_WAYLAND=false
#   RAM_MB=8192
#   CPU_SCORE=medium
#   KERNEL_PKG=linux-lts
#   DESKTOP_DEFAULT=apollo-desktop
#   DESKTOP_LOCKED=true
#   REASON=Sua GPU (NVIDIA Legacy 390xx) não suporta Wayland...

set -euo pipefail

# ── GPU Detection ─────────────────────────────────────────────────────────────
GPU_LINE=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 || echo "")
GPU_MODEL=$(echo "$GPU_LINE" | sed 's/.*: //')

# Get PCI IDs
GPU_VENDOR_ID=$(lspci -n 2>/dev/null | grep -iE '0300|0302' | head -1 | awk '{print $3}' | cut -d: -f1 || echo "0000")
GPU_DEVICE_ID=$(lspci -n 2>/dev/null | grep -iE '0300|0302' | head -1 | awk '{print $3}' | cut -d: -f2 || echo "0000")
PCI_ID="${GPU_VENDOR_ID}:${GPU_DEVICE_ID}"

# NVIDIA 390xx device IDs (GT 610/710/720, GTX 650-680)
NVIDIA_390XX_IDS="1244 1245 1246 1247 0fc1 0fc2 0fc6 0fd1 0fd2 0fd3 0fd4 0fd5 \
  128b 128f 1290 1291 1292 1293 1294 1295 1380 1381 1382 \
  11c0 11c2 11c3 11c4 11c5 1185 1187 1188 1189 1183 1184 1086 1087 1088"

# NVIDIA 470xx IDs (GTX 900/1000 series)
NVIDIA_470XX_IDS="1401 1402 1406 1407 1617 1618 1619 161a \
  1c02 1c03 1c04 1c06 1c07 1c09 1c20 1c21 1c82 1c8c 1c8d 1c8f \
  1d01 1d10 1d12"

GPU_VENDOR="other"
GPU_DRIVER="xf86-video-vesa"
GPU_WAYLAND="false"

case "$GPU_VENDOR_ID" in
    10de)
        GPU_VENDOR="nvidia"
        if echo "$NVIDIA_390XX_IDS" | grep -qw "${GPU_DEVICE_ID:-xxxx}"; then
            GPU_DRIVER="apollo-nvidia-390xx-dkms"
            GPU_WAYLAND="false"
        elif echo "$NVIDIA_470XX_IDS" | grep -qw "${GPU_DEVICE_ID:-xxxx}"; then
            GPU_DRIVER="nvidia-470xx-dkms"
            GPU_WAYLAND="false"
        else
            GPU_DRIVER="nvidia"
            GPU_WAYLAND="true"
        fi
        ;;
    1002)
        GPU_VENDOR="amd"
        GPU_DRIVER="xf86-video-amdgpu"
        GPU_WAYLAND="true"
        ;;
    8086)
        GPU_VENDOR="intel"
        GPU_DRIVER="intel-media-driver"
        GPU_WAYLAND="true"
        ;;
esac

# ── RAM Detection ─────────────────────────────────────────────────────────────
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$(( RAM_KB / 1024 ))

# ── CPU Score ─────────────────────────────────────────────────────────────────
CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
if [ "$CORES" -le 2 ]; then
    CPU_SCORE="low"
elif [ "$CORES" -le 4 ]; then
    CPU_SCORE="medium"
else
    CPU_SCORE="high"
fi

# ── Kernel recommendation ─────────────────────────────────────────────────────
if [ "$GPU_DRIVER" = "apollo-nvidia-390xx-dkms" ] || [ "$GPU_DRIVER" = "nvidia-470xx-dkms" ]; then
    KERNEL_PKG="linux-lts"
else
    KERNEL_PKG="linux"
fi

# ── Desktop recommendation ────────────────────────────────────────────────────
DESKTOP_LOCKED="false"
if [ "$GPU_DRIVER" = "apollo-nvidia-390xx-dkms" ] || [ "$GPU_DRIVER" = "xf86-video-vesa" ]; then
    DESKTOP_DEFAULT="apollo-desktop"
    DESKTOP_LOCKED="true"
    REASON="Sua GPU não suporta Wayland. Apollo Desktop (X11) é o único modo compatível."
elif [ "$GPU_WAYLAND" = "true" ] && [ "$RAM_MB" -ge 6144 ] && [ "$CPU_SCORE" != "low" ]; then
    DESKTOP_DEFAULT="hyprland"
    REASON="Hardware detectado com suporte completo a Wayland. Hyprland recomendado."
else
    DESKTOP_DEFAULT="apollo-desktop"
    REASON="Apollo Desktop recomendado para estabilidade com este hardware."
fi

# ── Output ────────────────────────────────────────────────────────────────────
cat <<EOF
GPU_VENDOR=${GPU_VENDOR}
GPU_MODEL=${GPU_MODEL}
GPU_PCI_ID=${PCI_ID}
GPU_DRIVER=${GPU_DRIVER}
GPU_WAYLAND=${GPU_WAYLAND}
RAM_MB=${RAM_MB}
CPU_CORES=${CORES}
CPU_SCORE=${CPU_SCORE}
KERNEL_PKG=${KERNEL_PKG}
DESKTOP_DEFAULT=${DESKTOP_DEFAULT}
DESKTOP_LOCKED=${DESKTOP_LOCKED}
REASON=${REASON}
EOF
