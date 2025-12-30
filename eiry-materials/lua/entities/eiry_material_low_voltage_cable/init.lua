-- init.lua (server) for low voltage cable

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_c17/canister01a.mdl" -- placeholder coil/cable-like prop
    self.BaseClass.Initialize(self)
    self:SetMaterialID("low_voltage_cable")
end
