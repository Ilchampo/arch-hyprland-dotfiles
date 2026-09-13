#!/usr/bin/env bash
# One-time system setup; run again after changing palettes/wallpapers/CSS.
# Intentionally separate from apply_changes.sh: no login-manager restarts.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$EUID" -ne 0 ]]; then
    echo "Run: sudo ./setup_greeter.sh" >&2
    exit 1
fi
TARGET_USER="${SUDO_USER:-${1:-}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == root ]]; then
    echo "Run with sudo from your desktop user, or supply that username as argument." >&2
    exit 1
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -d "$TARGET_HOME" ]] || { echo "Unknown home for $TARGET_USER" >&2; exit 1; }
# Do not change which VT/login command is active until every asset is installed.
stage="$(mktemp -d /tmp/dotfiles-greeter.XXXXXXXX)"
trap 'rm -rf -- "$stage"' EXIT
python "$REPO_ROOT/scripts/build-greeter.py" "$stage"
pacman -S --needed --noconfirm greetd-regreet cage
for program in /usr/bin/regreet /usr/bin/cage /usr/bin/dbus-run-session /usr/bin/agreety /usr/bin/start-hyprland; do
    [[ -x "$program" ]] || { echo "Missing $program; greetd is unchanged." >&2; exit 1; }
done
getent passwd greeter >/dev/null
[[ -f /usr/share/wayland-sessions/hyprland.desktop ]] || {
    echo "Hyprland session entry is missing; greetd is unchanged." >&2; exit 1;
}

backup=/var/backups/dotfiles-greetd
install -d -o root -g root -m 0700 "$backup"
# Keep the original working configuration even after repeated installations.
if [[ ! -f "$backup/original-config.toml" ]]; then
    cp -a /etc/greetd/config.toml "$backup/original-config.toml"
fi
cp -a /etc/greetd/config.toml "$backup/previous-config.toml"

assets=/usr/local/share/dotfiles-greeter
install -d -o root -g root -m 0755 "$assets" "$assets/themes"
install -d -o root -g root -m 0755 "$assets/wayland-sessions"
install -o root -g root -m 0644 "$REPO_ROOT/system/greetd/hyprland-uwsm.desktop" \
    "$assets/wayland-sessions/hyprland-uwsm.desktop"
for theme_dir in "$stage"/themes/*; do
    name="$(basename "$theme_dir")"
    install -d -o root -g root -m 0755 "$assets/themes/$name"
    for file in "$theme_dir"/*; do
        install -o root -g root -m 0644 "$file" "$assets/themes/$name/$(basename "$file")"
    done
done
# The owner can change only this short theme ID, not greeter code or assets.
install -d -o root -g root -m 0755 /var/lib/dotfiles-greeter
selected="$(runuser -u "$TARGET_USER" -- head -c 64 "$TARGET_HOME/.local/state/theme-switch/current" 2>/dev/null || true)"
if [[ ! "$selected" =~ ^[a-z][a-z0-9-]{0,47}$ || ! -f "$assets/themes/$selected/regreet.toml" ]]; then
    selected=verdant
fi
printf '%s\n' "$selected" > "$stage/current"
install -o "$TARGET_USER" -g root -m 0644 "$stage/current" /var/lib/dotfiles-greeter/current
# ReGreet caches the last authenticated user/session here.
install -d -o greeter -g greeter -m 0755 /var/lib/regreet /var/log/regreet

# Check access as the actual unprivileged greeter before enabling the new command.
runuser -u greeter -- test -r "$assets/themes/$selected/wallpaper.png"
runuser -u greeter -- test -r "$assets/themes/$selected/regreet.css"
install -o root -g root -m 0755 "$REPO_ROOT/system/greetd/start-greeter" /etc/greetd/start-greeter
install -o root -g root -m 0644 "$REPO_ROOT/system/greetd/config.toml" /etc/greetd/config.toml.new
mv /etc/greetd/config.toml.new /etc/greetd/config.toml
systemctl enable greetd.service
printf '\nGraphical login installed using theme %s.\n' "$selected"
echo "Your current session was not restarted. Reboot when ready to use the new login."
echo "On first login select your user and Hyprland. Later logins remember both."
echo "Recovery from another VT (Ctrl+Alt+F3):"
echo "  sudo cp /var/backups/dotfiles-greetd/original-config.toml /etc/greetd/config.toml"
echo "  sudo systemctl restart greetd"
