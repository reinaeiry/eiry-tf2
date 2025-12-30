-- eiry_materials_init.lua
-- Entry point for the eiry-materials addon.

if SERVER then
    AddCSLuaFile("autorun/eiry_materials_init.lua")
end

_G.eiry_materials = _G.eiry_materials or {}

if SERVER then
    print("[eiry-materials] Loaded core materials.")
end
