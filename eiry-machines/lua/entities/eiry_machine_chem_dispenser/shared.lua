-- shared.lua
-- Finished chemical dispenser machine.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Chem Dispenser"
ENT.Author = "eiry-machines"
ENT.Category = "Eiry Machines"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ReagentIndex")
end
