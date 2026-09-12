-- Ignore applications requests to be maximized
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Prevents xwayland stealing keyboard focus
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Forces hyprland-run windows to be floating and centered
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Blur opaque notification pixels
hl.layer_rule({
    name  = "mako-blur",
    match = { namespace = "^notifications$" },
    blur  = true,
    ignore_alpha = 0.2,
})

-- Blur wofi menu
hl.layer_rule({
    name  = "wofi-blur",
    match = { namespace = "^wofi$" },
    blur  = true,
    ignore_alpha = 0.2,
})
