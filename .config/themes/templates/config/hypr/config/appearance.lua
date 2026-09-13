-- {{name}} palette (shared with Waybar and Alacritty)
local palette = {
    bg     = "rgb({{bg}})",
    text   = "rgb({{text}})",
    muted  = "rgb({{muted}})",
    grey   = "rgb({{border}})",
    fill   = "rgb({{fill}})",
    green  = "rgb({{success}})",
    accent = "rgb({{accent}})",
    danger = "rgb({{danger}})",
    active_border   = { colors = { "rgba({{fill}}ee)", "rgba({{accent}}ee)" }, angle = 45 },
    inactive_border = "rgba({{border}}aa)",
}

-- Look and feel configuration
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border          = palette.active_border,
            inactive_border        = palette.inactive_border,
            nogroup_border         = palette.inactive_border,
            nogroup_border_active  = palette.active_border,
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
            color        = "rgba({{bg}}ee)",
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
            border_active          = palette.active_border,
            border_inactive        = palette.inactive_border,
            border_locked_active   = "rgba({{accent}}ee)",
            border_locked_inactive = "rgba({{border}}aa)",
        },
        groupbar = {
            enabled     = true,
            font_family = "JetBrainsMono Nerd Font",
            font_size   = 12,
            gradients   = true,
            text_color           = palette.text,
            text_color_inactive  = palette.muted,
            col = {
                active          = "rgba({{fill}}cc)",
                inactive        = "rgba({{base}}cc)",
                locked_active   = "rgba({{accent}}cc)",
                locked_inactive = "rgba({{border}}cc)",
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
        background_color        = palette.bg,
        font_family             = "JetBrainsMono Nerd Font",
        col = {
            splash = palette.accent,
        },
    },
})
