-- init.lua (server) for syringe

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self.ModelOverride = "models/props_lab/jar01a.mdl"
    self.ChemCapacity = 15
    self.BaseClass.Initialize(self)
end

local function transfer_to_player(self, ply)
    if not chemistry then return end
    local med = ply.GetMedical and ply:GetMedical() or nil
    if not med then return end

    local mix = self:RemoveMixture(self:GetChemVolume())
    local total = 0
    for id, v in pairs(mix) do
        chemistry.AddReagent(med, id, v)
        total = total + v
    end

    if total > 0 then
        ply:ChatPrint(string.format("Injected %.1f units.", total))
    else
        ply:ChatPrint("Syringe is empty.")
    end
end

local function draw_from_container(self, container)
    if not IsValid(container) or not container.IsChemContainer or not container:IsChemContainer() then return end

    local free = math.max(0, self:GetChemCapacity() - self:GetChemVolume())
    if free <= 0 then return end

    local mix = container:RemoveMixture(free)
    self:ReceiveMixture(mix)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local trace = activator:GetEyeTrace()
    local target = IsValid(trace.Entity) and trace.Entity or nil

    if target and target:IsPlayer() then
        transfer_to_player(self, target)
        return
    end

    if target and target.IsChemContainer and target:IsChemContainer() then
        draw_from_container(self, target)
        activator:ChatPrint("You fill the syringe.")
        return
    end

    self:DescribeContents(activator)
end
