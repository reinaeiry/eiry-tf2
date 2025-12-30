-- body_zones.lua
-- Simple SS14-like body layout.

local M = {}

M.zones = {
    head = {
        id = "head",
        max_health = 100,
    },
    torso = {
        id = "torso",
        max_health = 150,
    },
    left_arm = {
        id = "left_arm",
        max_health = 75,
    },
    right_arm = {
        id = "right_arm",
        max_health = 75,
    },
    left_leg = {
        id = "left_leg",
        max_health = 75,
    },
    right_leg = {
        id = "right_leg",
        max_health = 75,
    },
}

M.zone_list = {
    "head",
    "torso",
    "left_arm",
    "right_arm",
    "left_leg",
    "right_leg",
}

function M.Get(id)
    return M.zones[id]
end

return M
