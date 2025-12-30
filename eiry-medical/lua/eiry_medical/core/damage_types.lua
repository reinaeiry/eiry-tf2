-- damage_types.lua
-- SS14-inspired damage categories.

local M = {}

M.types = {
    brute = {
        id = "brute",
        label = "Brute",
    },
    burn = {
        id = "burn",
        label = "Burn",
    },
    toxin = {
        id = "toxin",
        label = "Toxin",
    },
    oxygen = {
        id = "oxygen",
        label = "Oxygen",
    },
    clone = {
        id = "clone",
        label = "Clone",
    },
}

function M.Normalize(id)
    return M.types[id]
end

return M
