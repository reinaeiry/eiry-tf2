-- init.lua (server) for beaker

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_lab/beaker.mdl"
    self.ChemCapacity = 100
    self.BaseClass.Initialize(self)
end
