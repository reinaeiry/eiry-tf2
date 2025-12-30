-- init.lua (server) for chem container base

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self:SetModel(self.ModelOverride or "models/props_lab/jar01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.ChemCapacity = self.ChemCapacity or 100
    self.ChemContents = self.ChemContents or {}

    if chemistry and chemistry.ProcessContainer then
        chemistry.ProcessContainer(self)
    end
end

function ENT:IsChemContainer()
    return true
end

function ENT:GetChemVolume()
    local vol = 0
    for _, amount in pairs(self.ChemContents) do
        vol = vol + amount
    end
    return vol
end

function ENT:GetChemCapacity()
    return self.ChemCapacity or 100
end

function ENT:AddReagent(id, amount)
    if not chemistry or not chemistry.Get(id) then return 0 end
    amount = amount or 0
    if amount <= 0 then return 0 end

    local cur = self:GetChemVolume()
    local free = math.max(0, self:GetChemCapacity() - cur)
    local add = math.min(free, amount)
    if add <= 0 then return 0 end

    self.ChemContents[id] = (self.ChemContents[id] or 0) + add

    if chemistry and chemistry.ProcessContainer then
        chemistry.ProcessContainer(self)
    end
    return add
end

-- Remove up to `amount` total, returning a mixture table.
function ENT:RemoveMixture(amount)
    amount = amount or 0
    if amount <= 0 then return {} end

    local total = self:GetChemVolume()
    if total <= 0 then return {} end

    local frac = math.min(1, amount / total)
    local mix = {}
    for id, v in pairs(self.ChemContents) do
        local take = v * frac
        if take > 0 then
            mix[id] = take
            self.ChemContents[id] = v - take
            if self.ChemContents[id] <= 0.0001 then
                self.ChemContents[id] = nil
            end
        end
    end

    if chemistry and chemistry.ProcessContainer then
        chemistry.ProcessContainer(self)
    end

    return mix
end

function ENT:ReceiveMixture(mix)
    if not mix then return 0 end
    local added = 0
    for id, v in pairs(mix) do
        added = added + self:AddReagent(id, v)
    end
    if chemistry and chemistry.ProcessContainer then
        chemistry.ProcessContainer(self)
    end
    return added
end

function ENT:DescribeContents(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local vol = self:GetChemVolume()
    if vol <= 0 then
        ply:ChatPrint("Container is empty.")
        return
    end

    ply:ChatPrint(string.format("Container volume: %.1f / %.1f", vol, self:GetChemCapacity()))
    for id, v in pairs(self.ChemContents) do
        ply:ChatPrint(string.format(" - %s: %.1f", id, v))
    end
end

function ENT:RefreshChemAppearance()
    if not chemistry or not chemistry.GetMixtureInfo then return end
    local info = chemistry.GetMixtureInfo(self.ChemContents or {})
    if not info then return end

    self:SetMixName(info.name or "")

    local col = info.color or { r = 255, g = 255, b = 255 }
    local r = (col.r or 255) / 255
    local g = (col.g or 255) / 255
    local b = (col.b or 255) / 255
    self:SetMixColor(Vector(r, g, b))
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    self:DescribeContents(activator)
end
