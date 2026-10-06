local gamemode = require("modules.gamemode")

local mainMod  = "SUPER"
local terminal = "kitty"
local shotDir  = "~/Pictures/Screenshots"

local function bind(keys, desc, action, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(mainMod .. " + " .. keys, action, opts)
end

local function key(keys, desc, action, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, action, opts)
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

local function screenshot(region)
    local grab = region and 'g=$(slurp) && grim -g "$g" - ' or "grim - "
    return exec(grab .. "| tee " .. shotDir .. "/$(date +%F_%H-%M-%S).png | wl-copy -t image/png")
end

bind("Return",         "Open terminal",                exec(terminal))
bind("Z",              "Open editor",                  exec("zeditor"))
bind("E",              "Open file manager",            exec(terminal .. " -e yazi"))
bind("B",              "Open browser", exec("helium-browser"))
bind("Space",          "Open launcher",                hl.dsp.global("quickshell:launcher"))
bind("C",              "Open clipboard",               hl.dsp.global("quickshell:clipboard"))
bind("W",              "Open wallpaper picker",        hl.dsp.global("quickshell:wallpaper"))
bind("Escape",         "Open power menu",              hl.dsp.global("quickshell:power"))
bind("N",              "Open Obsidian",                exec("obsidian"))
bind("M",              "Show / hide ncspot",           hl.dsp.workspace.toggle_special("music"))
bind("X",              "Open Control Center",          hl.dsp.global("quickshell:control"))
bind("Q",              "Close window",                 hl.dsp.window.close())
bind("F",              "Toggle fullscreen",            hl.dsp.window.fullscreen())
bind("A",              "Toggle floating",              hl.dsp.window.float({ action = "toggle" }))
bind("SHIFT + Return", "Swap with master",             hl.dsp.layout("swapwithmaster"))
bind("V",              "Screenshot screen",            screenshot(false))
bind("SHIFT + V",      "Screenshot region",            screenshot(true))
bind("G",              "Toggle gamemode",              gamemode.toggle)
bind("SHIFT + Escape", "Exit Hyprland",                hl.dsp.exit())

local dirs = { h = "left", j = "down", k = "up", l = "right" }
local step = { h = { -40, 0 }, j = { 0, 40 }, k = { 0, -40 }, l = { 40, 0 } }

for k, dir in pairs(dirs) do
    bind(k,              "Focus " .. dir,              hl.dsp.focus({ direction = dir }))
    bind("SHIFT + " .. k, "Move window " .. dir,        hl.dsp.window.move({ direction = dir }))
    bind("CTRL + " .. k,  "Resize window " .. dir,      hl.dsp.window.resize({ x = step[k][1], y = step[k][2], relative = true }), { repeating = true })
end

for i = 1, 10 do
    local n = i % 10
    bind(n,              "Go to workspace " .. i,      hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. n, "Send window to workspace " .. i, hl.dsp.window.move({ workspace = i }))
end

bind("S",              "Toggle scratchpad",            hl.dsp.workspace.toggle_special("scratch"))
bind("SHIFT + S",      "Send window to scratchpad",    hl.dsp.window.move({ workspace = "special:scratch" }))

bind("mouse_down",     "Next workspace",               hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",       "Previous workspace",           hl.dsp.focus({ workspace = "e-1" }))
bind("mouse:272",      "Drag window",                  hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273",      "Resize window with mouse",     hl.dsp.window.resize(), { mouse = true })

bind("equal",          "Volume up",                    exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
bind("minus",          "Volume down",                  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { repeating = true })
bind("SHIFT + equal",  "Brightness up",                exec("brightnessctl -e4 -n2 set 5%+"),                  { repeating = true })
bind("SHIFT + minus",  "Brightness down",              exec("brightnessctl -e4 -n2 set 5%-"),                  { repeating = true })

key("XF86AudioRaiseVolume",  "Volume up",       exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
key("XF86AudioLowerVolume",  "Volume down",     exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
key("XF86AudioMute",         "Mute",            exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
key("XF86AudioMicMute",      "Mute microphone", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
key("XF86MonBrightnessUp",   "Brightness up",   exec("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
key("XF86MonBrightnessDown", "Brightness down", exec("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
key("XF86AudioPlay",         "Play / pause",    exec("playerctl play-pause"), { locked = true })
key("XF86AudioPause",        "Play / pause",    exec("playerctl play-pause"), { locked = true })
key("XF86AudioNext",         "Next track",      exec("playerctl next"),       { locked = true })
key("XF86AudioPrev",         "Previous track",  exec("playerctl previous"),   { locked = true })
