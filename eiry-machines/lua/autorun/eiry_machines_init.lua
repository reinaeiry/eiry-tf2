-- eiry_machines_init.lua
-- Entry point for the eiry-machines addon.

if SERVER then
    AddCSLuaFile("autorun/eiry_machines_init.lua")
    AddCSLuaFile("eiry_machines/core/machine_registry.lua")
end

_G.eiry_machines = _G.eiry_machines or {}

-- Core includes
local machine_registry = include("eiry_machines/core/machine_registry.lua")

-- Example machine registration wiring in boards and materials.
machine_registry.RegisterMachine("debug_pump", {
    name = "Debug Pump",
    board_class = "eiry_machine_board_debug_pump",
    entity_class = "eiry_machine_debug_pump",
    build_steps = {
        { type = "material", class = "eiry_material_steel_plate", amount = 2 },
        { type = "material", class = "eiry_material_low_voltage_cable", amount = 1 },
        { type = "material", class = "eiry_material_glass_sheet", amount = 1 },
        { type = "material", class = "eiry_material_electronic_parts", amount = 1 },
    }
})

machine_registry.RegisterMachine("chem_dispenser", {
    name = "Chem Dispenser",
    board_class = "eiry_machine_board_chem_dispenser",
    entity_class = "eiry_machine_chem_dispenser",
    build_steps = {
        { type = "material", class = "eiry_material_steel_plate", amount = 3 },
        { type = "material", class = "eiry_material_glass_sheet", amount = 2 },
        { type = "material", class = "eiry_material_electronic_parts", amount = 3 },
        { type = "material", class = "eiry_material_low_voltage_cable", amount = 2 },
    }
})

machine_registry.RegisterMachine("chem_master", {
    name = "Chem Master",
    board_class = "eiry_machine_board_chem_master",
    entity_class = "eiry_machine_chem_master",
    build_steps = {
        { type = "material", class = "eiry_material_steel_plate", amount = 2 },
        { type = "material", class = "eiry_material_glass_sheet", amount = 2 },
        { type = "material", class = "eiry_material_electronic_parts", amount = 4 },
        { type = "material", class = "eiry_material_low_voltage_cable", amount = 2 },
    }
})

if SERVER then
    print("[eiry-machines] Loaded core systems and registered machines.")
end
