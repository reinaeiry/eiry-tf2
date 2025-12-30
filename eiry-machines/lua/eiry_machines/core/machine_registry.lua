-- machine_registry.lua
-- Central registry for SS14-style machines.

local machines = {}

local M = {}

-- def structure (minimal):
-- {
--   name = "Debug Pump",
--   board_class = "eiry_machine_board_debug_pump",
--   entity_class = "eiry_machine_debug_pump",
--   build_steps = {
--     { type = "material", class = "eiry_material_steel_plate", amount = 2 },
--     { type = "material", class = "eiry_material_low_voltage_cable", amount = 1 },
--   }
-- }

function M.RegisterMachine(id, def)
    assert(isstring(id), "machine id must be a string")
    assert(istable(def), "machine definition must be a table")

    machines[id] = def
end

function M.GetMachine(id)
    return machines[id]
end

function M.GetAllMachines()
    return machines
end

function M.GetBuildSteps(id)
    local def = machines[id]
    return def and def.build_steps or nil
end

if not _G.eiry_machines then
    _G.eiry_machines = {}
end

_G.eiry_machines.machines = M

return M
