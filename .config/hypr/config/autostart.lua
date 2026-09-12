-- Autostart applications
hl.on("hyprland.start", function ()
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("hyprpaper")
end)

-- Default environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")