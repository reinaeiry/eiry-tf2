-- init.lua (server) for chem analyzer

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self.ModelOverride = "models/Items/combine_rifle_ammo01.mdl"
    self.BaseClass.Initialize(self)
end

local function analyze_container(ent)
    if not chemistry then return {"Chemistry core not available."} end
    if not ent or not ent.ChemContents then return {"No chemical data."} end

    local lines = chemistry.FormatMixtureReport and chemistry.FormatMixtureReport(ent.ChemContents) or {}
    if #lines == 0 then
        table.insert(lines, "Mixture: Unknown")
    end

    return lines
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local tr = activator:GetEyeTrace()
    local target = IsValid(tr.Entity) and tr.Entity or nil

    if not IsValid(target) or not (target.IsChemContainer and target:IsChemContainer()) then
        activator:ChatPrint("Point at a chem container to analyze.")
        return
    end

    local report = analyze_container(target)
    for _, line in ipairs(report) do
        activator:ChatPrint(line)
    end
end
