hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "xwayland-drag-fix",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "float-utils",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|xdg-desktop-portal-gtk)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Open Folder|Save As|Save File|Select a File|File Upload).*$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "games",
    match = { class = "^(steam_app_.*|gamescope)$" },
    immediate    = true,
    idle_inhibit = "fullscreen",
    content   = "game",
    opaque    = true,
    no_blur   = true,
    no_shadow = true,
    no_dim    = true,
    no_anim   = true,
    tag       = "+hyprglass_disabled",
})

hl.window_rule({
    name  = "ncspot-hidden",
    match = { class = "^ncspot$" },
    workspace = "special:music silent",
})
