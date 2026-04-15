# Apollo Linux — Shell Environment
# /etc/profile.d/apollo.sh
# Sourced by all login shells on Apollo Linux

# ── Theming ───────────────────────────────────────────────────────────────────
export GTK_THEME="Apollo-Dark"
export XCURSOR_THEME="Bibata-Modern-Classic"
export XCURSOR_SIZE="24"

# Qt platform theming
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_AUTO_SCREEN_SCALE_FACTOR="1"

# ── Wayland / X11 hints ───────────────────────────────────────────────────────
if [ -n "$WAYLAND_DISPLAY" ]; then
    export GDK_BACKEND="wayland,x11"
    export SDL_VIDEODRIVER="wayland"
    export CLUTTER_BACKEND="wayland"
    export MOZ_ENABLE_WAYLAND="1"
    export ELECTRON_OZONE_PLATFORM_HINT="auto"
    export QT_QPA_PLATFORM="wayland;xcb"
else
    export GDK_BACKEND="x11"
    export QT_QPA_PLATFORM="xcb"
fi

# ── Terminal ──────────────────────────────────────────────────────────────────
export TERMINAL="alacritty"
export TERM="xterm-256color"

# ── Editor preference ─────────────────────────────────────────────────────────
if command -v kate &>/dev/null; then
    export EDITOR="kate"
    export VISUAL="kate"
elif command -v nano &>/dev/null; then
    export EDITOR="nano"
    export VISUAL="nano"
fi

# ── Browser ───────────────────────────────────────────────────────────────────
if command -v firefox &>/dev/null; then
    export BROWSER="firefox"
fi

# ── PATH additions ────────────────────────────────────────────────────────────
# Apollo tools
[ -d "/usr/lib/apollo" ] && export PATH="$PATH:/usr/lib/apollo"

# User local bin (already standard on Arch, but ensure it)
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ── Locale ────────────────────────────────────────────────────────────────────
# Preserve user locale — do not override here. Set at install time by Calamares.

# ── Apollo-specific ───────────────────────────────────────────────────────────
export APOLLO_DESKTOP_VERSION="1.0"
export APOLLO_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/apollo"
