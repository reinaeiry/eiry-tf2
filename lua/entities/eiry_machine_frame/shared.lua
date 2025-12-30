-- shared.lua
-- Shared definition for the base machine frame entity.

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Machine Frame"
ENT.Author = "eiry-machines"
ENT.Category = "Eiry Machines"

ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	-- Networked machine identifier this frame is configured to build into.
	self:NetworkVar("String", 0, "MachineID")
	-- Current build step index (1-based, 0 = no steps started).
	self:NetworkVar("Int", 0, "BuildStep")
	-- Whether construction is complete and the machine is operational.
	self:NetworkVar("Bool", 0, "MachineBuilt")
end
