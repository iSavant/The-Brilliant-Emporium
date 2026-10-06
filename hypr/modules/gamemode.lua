local look = require("modules.look")
local glass = require("modules.glass")

local M = { active = false }

function M.toggle()
    M.active = not M.active
    if M.active then
        hl.exec_cmd("qs kill")
        hl.config(look.game)
        glass.set(false)
        hl.exec_cmd("systemctl --user stop wpe")
    else
        hl.config(look.restore)
        hl.exec_cmd("qs -n")
        glass.set(true)
    end
end

return M
