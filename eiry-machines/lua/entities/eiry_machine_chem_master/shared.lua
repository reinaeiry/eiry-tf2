-- shared.lua
-- Finished chem master machine.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Chem Master"
ENT.Author = "eiry-machines"
ENT.Category = "Eiry Machines"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ModeIndex")
end
