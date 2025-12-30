-- init.lua (server) for glass sheet

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_phx/construct/glass/glass_plate1x1.mdl"
    self.BaseClass.Initialize(self)
    self:SetMaterialID("glass_sheet")
end
