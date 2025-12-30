-- eiry_tf2_init.lua
-- Top-level autorun for the eiry-tf2 addon. Bridges the internal
-- eiry-machines, eiry-medical and eiry-materials trees into the normal
-- Garry's Mod lua/ layout.

if SERVER then
    -- Expose sub-addon autorun files to clients.
    AddCSLuaFile("autorun/eiry_tf2_init.lua")
    AddCSLuaFile("autorun/eiry_machines_init.lua")
    AddCSLuaFile("autorun/eiry_medical_init.lua")
    AddCSLuaFile("autorun/eiry_materials_init.lua")
end

-- Simply include the mirrored autorun files that live under lua/.
include("autorun/eiry_machines_init.lua")
include("autorun/eiry_medical_init.lua")
include("autorun/eiry_materials_init.lua")
