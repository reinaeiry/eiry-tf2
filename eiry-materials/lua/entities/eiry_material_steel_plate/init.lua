-- init.lua (server) for steel plate

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_phx/construct/metal_plate1.mdl"
    self.BaseClass.Initialize(self)
    self:SetMaterialID("steel_plate")
end
