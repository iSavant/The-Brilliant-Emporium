hl.curve("soul",   { type = "bezier", points = { {0.4, 0}, {0.2, 1} } })

local function anim(leaf, speed, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = "soul", style = style })
end

anim("global",            8)
anim("windowsIn",         4,  "popin 92%")
anim("windowsOut",        3,  "popin 95%")
anim("windowsMove",       4)
anim("fade",              3)
anim("fadeDim",           4)
anim("border",            5)
anim("layersIn",          3,  "fade")
anim("layersOut",         2,  "fade")
anim("workspaces",        4,  "slidefade 15%")
anim("specialWorkspace",  4,  "slidefadevert 20%")
