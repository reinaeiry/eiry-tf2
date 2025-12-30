-- init.lua (server) for pill bottle

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self:SetModel("models/props_lab/jar01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.PillMixture = self.PillMixture or {}
    self:SetPillsRemaining(self:GetPillsRemaining() > 0 and self:GetPillsRemaining() or 10)
end

function ENT:SetPillData(mix, count)
    self.PillMixture = table.Copy(mix or {})
    self:SetPillsRemaining(count or 10)
end

local function take_pill(self, ply)
    if not chemistry then return end
    if self:GetPillsRemaining() <= 0 then
        ply:ChatPrint("The bottle is empty.")
        return
    end

    local med = ply.GetMedical and ply:GetMedical() or nil
    if not med then return end

    local total = 0
    for id, v in pairs(self.PillMixture or {}) do
        if chemistry.Get(id) then
            chemistry.AddReagent(med, id, v)
            total = total + v
        end
    end

    if total > 0 then
        ply:ChatPrint(string.format("You swallow a pill (%.1f units).", total))
        self:SetPillsRemaining(self:GetPillsRemaining() - 1)
        if self:GetPillsRemaining() <= 0 then
            self:Remove()
        end
    else
        ply:ChatPrint("These pills seem inert.")
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    take_pill(self, activator)
end
