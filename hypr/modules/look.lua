local c = require("modules.theme")

local M = {}

M.normal = {
    render   = { direct_scanout = 2 },
    xwayland = { force_zero_scaling = true },
    general = {
        gaps_in          = 6,
        gaps_out         = 12,
        border_size      = 2,
        layout           = "master",
        resize_on_border = true,
        allow_tearing    = true,
        col = {
            active_border   = { colors = { c.soulflame, c.steel }, angle = 45 },
            inactive_border = c.steel,
        },
    },
    decoration = {
        border_part_of_window = true,
        active_opacity     = 0.69,
        inactive_opacity   = 0.42,
        fullscreen_opacity = 1.0,
        rounding       = 12,
        rounding_power = 2,
        dim_inactive   = true,
        dim_strength   = 0.08,
        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 3,
            color        = c.shadow,
        },
    },
    master = {
        mfact = 0.69,
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 2,
        vrr                      = 2,
        enable_anr_dialog = false,
    },
    animations = { enabled = true },
}

M.game = {
    decoration = {
        rounding     = 0,
        dim_inactive = false,
        shadow       = { enabled = false },
        blur         = { enabled = false },
    },
    animations = { enabled = false },
}

M.restore = {
    decoration = {
        rounding     = M.normal.decoration.rounding,
        dim_inactive = true,
        shadow       = { enabled = true },
        blur         = { enabled = true },
    },
    animations = { enabled = true },
}

hl.config(M.normal)

function M.reveal(on)
    local d = M.normal.decoration
    if on then
        hl.config({
            general = { border_size = 0 },
            decoration = {
                active_opacity = 0,
                inactive_opacity = 0,
                fullscreen_opacity = 0,
                dim_inactive = false,
                shadow = { enabled = false },
            },
        })
    else
        hl.config({
            general = { border_size = M.normal.general.border_size },
            decoration = {
                active_opacity = d.active_opacity or 1,
                inactive_opacity = d.inactive_opacity or 1,
                fullscreen_opacity = d.fullscreen_opacity or 1,
                dim_inactive = d.dim_inactive,
                shadow = { enabled = d.shadow.enabled },
            },
        })
    end
end

return M
