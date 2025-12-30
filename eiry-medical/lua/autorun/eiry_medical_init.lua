-- eiry_medical_init.lua
-- Entry point for the eiry-medical addon.

if SERVER then
    AddCSLuaFile("autorun/eiry_medical_init.lua")
    AddCSLuaFile("eiry_medical/core/damage_types.lua")
    AddCSLuaFile("eiry_medical/core/body_zones.lua")
    AddCSLuaFile("eiry_medical/core/health_component.lua")
    AddCSLuaFile("eiry_medical/core/chemistry.lua")
    AddCSLuaFile("eiry_medical/core/surgery.lua")
end

_G.eiry_medical = _G.eiry_medical or {}

local dmg_types = include("eiry_medical/core/damage_types.lua")
local body_zones = include("eiry_medical/core/body_zones.lua")
local health_component = include("eiry_medical/core/health_component.lua")
local chemistry = include("eiry_medical/core/chemistry.lua")
local surgery = include("eiry_medical/core/surgery.lua")

_G.eiry_medical.damage_types = dmg_types
_G.eiry_medical.body_zones = body_zones
_G.eiry_medical.health = health_component
_G.eiry_medical.chemistry = chemistry
_G.eiry_medical.surgery = surgery

if SERVER then
    include("eiry_medical/core/hooks.lua")
    print("[eiry-medical] Loaded medical core.")
end
