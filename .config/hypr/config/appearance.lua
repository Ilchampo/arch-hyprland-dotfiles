-- Verdant palette (shared with Waybar and Alacritty)
local verdant = {
    bg     = "rgb(10180E)",
    text   = "rgb(E4EBE0)",
    muted  = "rgb(8A9584)",
    grey   = "rgb(6A7466)",
    fill   = "rgb(8FB56A)",
    green  = "rgb(7DCE7A)",
    accent = "rgb(D4A05A)",
    danger = "rgb(D97070)",
    active_border   = { colors = { "rgba(8fb56aee)", "rgba(d4a05aee)" }, angle = 45 },
    inactive_border = "rgba(6a7466aa)",
}

-- Look and feel configuration
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border          = verdant.active_border,
            inactive_border        = verdant.inactive_border,
            nogroup_border         = verdant.inactive_border,
            nogroup_border_active  = verdant.active_border,
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(10180eee)",
        },
        blur = {
            enabled   = true,
            size      = 5,
            passes    = 2,
            vibrancy  = 0.2,
        },
    },
    animations = {
        enabled = true,
    },
    group = {
        col = {
            border_active          = verdant.active_border,
            border_inactive        = verdant.inactive_border,
            border_locked_active   = "rgba(d4a05aee)",
            border_locked_inactive = "rgba(6a7466aa)",
        },
        groupbar = {
            enabled     = true,
            font_family = "JetBrainsMono Nerd Font",
            font_size   = 12,
            gradients   = true,
            text_color           = verdant.text,
            text_color_inactive  = verdant.muted,
            col = {
                active          = "rgba(8fb56acc)",
                inactive        = "rgba(1a2416cc)",
                locked_active   = "rgba(d4a05acc)",
                locked_inactive = "rgba(6a7466cc)",
            },
        },
    },
})

-- Layouts
hl.config({
    dwindle = {
        preserve_split = true,
    },
})
hl.config({
    master = {
        new_status = "master",
    },
})
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- No default Hyprland anime thingy!
hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        background_color        = verdant.bg,
        font_family             = "JetBrainsMono Nerd Font",
        col = {
            splash = verdant.accent,
        },
    },
})
