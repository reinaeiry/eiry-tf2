-- init.lua (server) for retractor

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local surgery = include("eiry_medical/core/surgery.lua")

function ENT:Initialize()
    self.ModelOverride = "models/props_junk/garbage_metalcan001a.mdl"
    self.BaseClass.Initialize(self)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local trace = activator:GetEyeTrace()
    local target = IsValid(trace.Entity) and trace.Entity or nil
    if not target or not target:IsPlayer() then
        activator:ChatPrint("Point at a patient to operate.")
        return
    end

    surgery.ApplyTool(activator, target, "retractor", trace.HitGroup)
end
