# arch-hyprland-dotfiles
Repository to store dotfiles for Arch + Hyprland.

## Verdant / Thunar

The GTK 3 theme is stored in `.local/share/themes/Verdant/gtk-3.0/`.
It uses GTK's built-in Adwaita dark widget geometry, with Verdant colors for
controls, menus, dialogs, tabs and borders. Edit `colors.css` for its palette
and `gtk.css` for widget states. Thunar-specific refinements remain in
`.config/gtk-3.0/gtk.css`.

The original SVG folder and place icons live in `.local/share/icons/Verdant/`.
Other file-type and application icons inherit from Adwaita (with hicolor as
the final fallback), preserving their recognizable artwork. Regular icon
artwork is separate from GTK CSS: change these SVGs to change folder colors.

`.config/gtk-3.0/settings.ini` selects both Verdant themes. These are user-wide
GTK 3 settings, so other GTK 3 applications also use the theme. GTK 4 and Qt
applications have separate theming systems. Hyprland draws Thunar's outer
window border using `.config/hypr/config/appearance.lua`.

Apply from the repository with `./apply_changes.sh` (no sudo needed for this
theme). This also copies the repository's other managed configurations and
replaces the previous backup in `~/.config/backup/last`.
When run without sudo, the script also synchronizes the desktop session's
`org.gnome.desktop.interface` GTK and icon theme settings. On Wayland these
can override `settings.ini`; stale values can otherwise leave Thunar using
fallback colors and blue folders even when Verdant is installed. Previous
session settings are saved as shell commands in
`~/.config/backup/last/restore-gtk-session.sh`.
Once file operations finish, run `thunar -q`, then reopen Thunar so the running
process reloads the GTK and icon themes. Restart other GTK 3 applications as
needed. No icon-cache generation or additional theme package is required.
