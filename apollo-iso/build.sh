#!/usr/bin/env bash
#
# Apollo Linux — ISO Build Script
# Usage: sudo ./build.sh [OPTIONS]
#
# Options:
#   -o, --output DIR    Output directory (default: ./out)
#   -w, --work DIR      Working directory (default: ./work)
#   -v, --verbose       Verbose output
#   -c, --clean         Clean work directory before building
#   -h, --help          Show this help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${SCRIPT_DIR}/out"
WORK_DIR="${SCRIPT_DIR}/work"
VERBOSE=0
CLEAN=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()    { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

usage() {
    cat <<EOF
${BOLD}Apollo Linux ISO Builder${NC}

Usage: sudo $0 [OPTIONS]

Options:
  -o, --output DIR    Output directory (default: ./out)
  -w, --work DIR      Working directory (default: ./work)
  -v, --verbose       Verbose output
  -c, --clean         Clean work directory before building
  -h, --help          Show this help

Examples:
  sudo $0                          # Build with defaults
  sudo $0 -c -o /tmp/apollo-out   # Clean build to custom output
EOF
}

check_deps() {
    log_step "Checking dependencies"
    local missing=()
    local deps=(archiso mksquashfs grub mkfs.fat)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null && ! pacman -Q "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Install with: pacman -S archiso"
        exit 1
    fi
    log_ok "All dependencies satisfied"
}

build_driver_cache() {
    log_step "Building driver package cache"
    local cache_dir="${PROFILE_DIR}/driver-cache/x86_64"
    mkdir -p "${cache_dir}"

    # List of driver packages to cache in ISO
    # These are NOT installed in the live env, only available for Calamares
    local driver_pkgs=(
        "nvidia"
        "nvidia-utils"
        "nvidia-settings"
        "nvidia-open"
        "lib32-nvidia-utils"
        "xf86-video-amdgpu"
        "xf86-video-ati"
        "xf86-video-intel"
        "xf86-video-vesa"
        "mesa"
        "libva-mesa-driver"
        "mesa-vdpau"
        "lib32-mesa"
        "vulkan-radeon"
        "vulkan-intel"
        "intel-media-driver"
    )

    # Apollo custom driver packages (built locally)
    local apollo_pkgs=(
        "apollo-nvidia-390xx-dkms"
        "apollo-nvidia-390xx-utils"
        "apollo-nvidia-470xx-dkms"
        "apollo-nvidia-470xx-utils"
    )

    log_info "Downloading driver packages to cache..."
    if [[ ${#driver_pkgs[@]} -gt 0 ]]; then
        # Use 'yes' to auto-select the default provider (e.g. for ambiguous 'nvidia' package)
        yes "" | pacman --noconfirm --downloadonly --cachedir "${cache_dir}" \
            -Sw "${driver_pkgs[@]}" 2>/dev/null || \
            log_warn "Some packages may not be cached (check AUR/custom repo for Apollo packages)"
    fi

    # Create local pacman repo from cached packages
    if [[ -n "$(ls "${cache_dir}"/*.pkg.tar.zst 2>/dev/null)" ]]; then
        repo-add "${cache_dir}/apollo-drivers.db.tar.gz" "${cache_dir}"/*.pkg.tar.zst
        log_ok "Driver cache built at ${cache_dir}"
    else
        log_warn "No packages cached — driver cache will be empty"
    fi
}

build_iso() {
    log_step "Building Apollo Linux ISO"

    local mkarchiso_args=(
        -w "${WORK_DIR}"
        -o "${OUTPUT_DIR}"
    )

    if [[ ${VERBOSE} -eq 1 ]]; then
        mkarchiso_args+=("-v")
    fi

    # Append profile dir last
    mkarchiso_args+=("${PROFILE_DIR}")

    mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}"
    mkarchiso "${mkarchiso_args[@]}"
}

print_result() {
    local iso_file
    iso_file=$(ls -t "${OUTPUT_DIR}"/apollo-linux-*.iso 2>/dev/null | head -1)
    if [[ -n "${iso_file}" ]]; then
        local size
        size=$(du -sh "${iso_file}" | cut -f1)
        echo ""
        echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${GREEN}║     Apollo Linux ISO Build Complete  ║${NC}"
        echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${NC}"
        echo -e "  ${BOLD}File:${NC}  ${iso_file}"
        echo -e "  ${BOLD}Size:${NC}  ${size}"
        echo -e "  ${BOLD}SHA256:${NC}"
        sha256sum "${iso_file}"
        echo ""
    else
        log_error "ISO file not found in ${OUTPUT_DIR}"
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -w|--work)   WORK_DIR="$2";   shift 2 ;;
        -v|--verbose) VERBOSE=1;       shift   ;;
        -c|--clean)  CLEAN=1;          shift   ;;
        -h|--help)   usage; exit 0              ;;
        *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# Must be root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Main
echo -e "${BOLD}${CYAN}"
cat <<'BANNER'
    ___    ____  ____  __    __    ____     __    _____   ___  _  __ 
   /   |  / __ \/ __ \/ /   / /   / __ \   / /   /  _/ / / / / |/ /
  / /| | / /_/ / / / / /   / /   / / / /  / /    / // / / / /    / 
 / ___ |/ ____/ /_/ / /___/ /___/ /_/ /  / /____/ // /_/ / /|  /  
/_/  |_/_/    \____/_____/_____/\____/  /_____/___/\____/_/ |_/   

BANNER
echo -e "${NC}"

check_deps

if [[ ${CLEAN} -eq 1 ]]; then
    log_step "Cleaning work directory"
    rm -rf "${WORK_DIR}"
    log_ok "Work directory cleaned"
fi

build_driver_cache
build_iso
print_result
