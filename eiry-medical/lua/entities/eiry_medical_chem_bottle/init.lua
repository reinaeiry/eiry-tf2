-- init.lua (server) for chem bottle

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self.ModelOverride = "models/props_junk/garbage_glassbottle003a.mdl"
    self.ChemCapacity = 60
    self.BaseClass.Initialize(self)
end

local function drink(self, ply)
    if not chemistry then return end
    local med = ply.GetMedical and ply:GetMedical() or nil
    if not med then return end

    local mix = self:RemoveMixture(10)
    local total = 0
    for id, v in pairs(mix) do
        if chemistry.Get(id) then
            chemistry.AddReagent(med, id, v)
            total = total + v
        end
    end

    if total > 0 then
        ply:ChatPrint(string.format("You drink %.1f units from the bottle.", total))
    else
        ply:ChatPrint("The bottle is empty.")
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if activator:Crouching() then
        self:DescribeContents(activator)
    else
        drink(self, activator)
    end
end
