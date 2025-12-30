-- init.lua (server) for electronic parts

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_lab/reciever01a.mdl"
    self.BaseClass.Initialize(self)
    self:SetMaterialID("electronic_parts")
end
