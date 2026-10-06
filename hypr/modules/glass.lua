local M = {}

function M.glass(enabled)
    if hl.plugin.hyprglass then
        local hg = hl.plugin.hyprglass

        hg.config({
            default_theme = "dark",
            default_preset = "glass",
            tint_color = 0x101316FF,
            enabled = enabled ~= false,

            brightness = 0.9,
            dark = {
                adaptive_dim = 1,
                saturation = 0.0,
            },

            layers = { enabled = true },
        })

        -- Layer surfaces: each call whitelists the namespace and configures it
        hg.layer("quickshell")
        hg.layer("quickshell-launcher")
        hg.layer("quickshell-clipboard")
        hg.layer("quickshell-power")
        hg.layer("quickshell-control")
        hg.layer("debug-panel")

        -- Presets
        hg.preset("glass", {
            blur_strength = 0,
            blur_iterations = 0,
            refraction_strength = 0,
            chromatic_aberration = 0,
            fresnel_strength = 0,
            specular_strength = 0,
            bevel_size = 0,
            edge_thickness = 0.0,
            lens_distortion = 0,
        })
    end
end

function M.set(enabled)
    if hl.plugin.hyprglass then
        hl.plugin.hyprglass.config({ enabled = enabled })
    end
end

M.glass()

return M
