-- shared.lua
-- Finished Debug Pump machine.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Debug Pump"
ENT.Author = "eiry-machines"
ENT.Category = "Eiry Machines"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MachineID")
end
