-- shared.lua
-- Base for chemical containers (beakers, syringes, etc.).

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Chem Container"
ENT.Author = "eiry-medical"
ENT.Category = "Eiry Medical"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Label")
    self:NetworkVar("String", 1, "MixName")
    self:NetworkVar("Vector", 0, "MixColor")
end
