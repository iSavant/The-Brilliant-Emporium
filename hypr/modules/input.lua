hl.config({
    input = {
        kb_layout     = "us",
        follow_mouse  = 1,
        sensitivity   = 0.4,
        accel_profile = "flat",
        touchpad = {
            natural_scroll        = true,
            disable_while_typing  = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "special", workspace_name = "scratch" })
