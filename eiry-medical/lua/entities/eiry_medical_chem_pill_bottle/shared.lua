-- shared.lua
-- Pill bottle that dispenses doses from stored mixture.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Pill Bottle"
ENT.Author = "eiry-medical"
ENT.Category = "Eiry Medical"

ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "PillsRemaining")
end
