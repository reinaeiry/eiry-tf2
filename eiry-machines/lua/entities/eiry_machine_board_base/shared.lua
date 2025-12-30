-- shared.lua
-- Base entity for machine boards.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Machine Board"
ENT.Author = "eiry-machines"
ENT.Category = "Eiry Machines"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    -- ID of the machine this board configures.
    self:NetworkVar("String", 0, "MachineID")
end
