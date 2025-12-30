-- init.lua (server) for chem dispenser board

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_lab/reciever01b.mdl"
    self.BaseClass.Initialize(self)
    self:SetMachineID("chem_dispenser")
end
