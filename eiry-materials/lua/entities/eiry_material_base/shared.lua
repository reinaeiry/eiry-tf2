-- shared.lua
-- Base entity for construction materials (plates, cables, etc.).

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Material"
ENT.Author = "eiry-materials"
ENT.Category = "Eiry Materials"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MaterialID")
end
