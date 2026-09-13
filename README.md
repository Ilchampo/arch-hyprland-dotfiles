# arch-hyprland-dotfiles

Arch Linux + Hyprland configuration with switchable Verdant, Abyss, Mono, Abstract and Reef themes.

## Apply and switch

Run `./apply_changes.sh` **without sudo** in your desktop session. It installs
configuration and theme assets, restores your last selection (Verdant on first
use), and refreshes the desktop. It replaces the previous file backup in
`~/.config/backup/last`; previous GTK session settings are saved there in
`restore-gtk-session.sh`.

Press **Super+W** to open the theme selector, select **Verdant**, **Abyss**, **Mono**, **Abstract**, or **Reef**,
and press Enter (or click). Escape cancels without changing anything.

You can also run:

```sh
~/.local/bin/theme-switch reef
~/.local/bin/theme-switch abstract
~/.local/bin/theme-switch mono
~/.local/bin/theme-switch abyss
~/.local/bin/theme-switch verdant
~/.local/bin/theme-switch --current
~/.local/bin/theme-switch --restore
```

Verdant retains the forest-green and amber palette. Abyss uses deep navy,
ocean-blue surfaces, cyan highlights and the supplied underwater wallpaper.
Mono uses charcoal backgrounds, silver folders, white highlights and a grayscale
dune wallpaper. Its entire palette, including terminal ANSI colors and status
colors, is monochrome. The current wallpaper is a provisional 1672×941 image;
native 3840×2160 generation is still pending (see the theme’s `wallpaper.md`).
Abstract pairs ink-plum backgrounds with lilac folders, pink highlights, turquoise
status accents and an original colorful abstract-art wallpaper (1672×941).
Reef pairs deep teal backgrounds with turquoise folders, peach-coral highlights
and a colorful tropical reef wallpaper (1672×941).
All five cover Hyprland borders/groups, Hyprpaper, Waybar (including workspace
indicators), Alacritty colors, Wofi, Mako, GTK 3/Thunar and folder/place icons.
Application and file-type icons inherit from Adwaita and hicolor. GTK 4, Qt,
and applications with their own themes are not controlled by this switcher.

The current selection lives in `~/.local/state/theme-switch/current`, outside
the repository. Reapplying dotfiles preserves it. Generated configuration and
GTK session settings persist across logout/reboot without a startup script.
Run without sudo: root applies files but does not change the user's session.

On the first installation of this switching system, restart Thunar once after
file operations finish (`thunar -q`, then reopen). This loads the new static
GTK override file; subsequent switches change named GTK themes dynamically.
The switcher never terminates Thunar. Some other GTK applications may need a
restart if they cache their own styles. Alacritty watches its imported palette;
new Wofi menus use the selected style. Refresh failures are reported without
losing the saved selection; `theme-switch --restore` retries the refresh.

## Theme sources

- `.config/themes/verdant/palette.json` and `abyss/palette.json`,
  `mono/palette.json`, `abstract/palette.json`, and `reef/palette.json`: named colors.
- `.config/themes/<theme>/wallpaper.png`: wallpaper, applied to all monitors.
- `.config/themes/templates/config/`: shared theme-controlled app configuration.
- `.config/themes/templates/gtk/`: shared GTK widget styling and palette aliases.
- `.config/themes/templates/icons/`: shared original SVG folder/place artwork.
- `.config/themes/selector.conf`: theme menu layout.
- `.local/bin/theme-switch`: Python 3 standard-library renderer and switcher.

Edit palettes and templates as the source of truth. The switcher regenerates
Hyprland's `appearance.lua`, Waybar config/style, Wofi style, Mako config,
Hyprpaper config, Alacritty's `colors.toml`, and named GTK/icon assets. Changes
to those generated outputs will be overwritten by the next switch. GTK
`settings.ini` retains other settings; only its theme and icon-theme keys change.
Thunar's static overrides remain in `.config/gtk-3.0/gtk.css`. Keybindings,
monitor configuration, fonts in Alacritty, shell, padding and opacity remain
outside the renderer (other appearance layout settings live in templates).

To add a theme, create a new directory under `.config/themes`, copy a palette,
choose a unique simple `name` for its GTK/icon theme, edit all colors, and add
`wallpaper.png`. The menu discovers it automatically. Tokens such as `{{bg}}`
render a six-digit hex color; `{{bg.rgb}}` renders its three decimal channels.

After editing sources, refresh the repository's generated defaults without
changing your live desktop or saved choice:

```sh
.local/bin/theme-switch --root "$PWD" --build
```

Then run `./apply_changes.sh`. Runtime dependencies are Python 3, Wofi,
GSettings, Hyprctl/Hyprpaper, Makoctl and procps (`pgrep`/`pkill`). Notifications
use `notify-send` if available. No additional theme package is needed.
Wallpaper refresh uses Hyprpaper 0.8's `wallpaper` IPC request, as documented
in the [Hyprpaper wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/).

## Checks

```sh
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -v
bash -n apply_changes.sh
```

Tests use temporary home directories and mocked session commands; they never
change your desktop. `--root <temporary-home> --no-reload <theme>` can also be
used to inspect a rendered theme offline after copying `.config` there.
