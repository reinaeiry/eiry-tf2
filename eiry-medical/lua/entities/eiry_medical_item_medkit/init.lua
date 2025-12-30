-- init.lua (server) for medkit

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local body_zones = _G.eiry_medical and _G.eiry_medical.body_zones

function ENT:Initialize()
    self.ModelOverride = "models/Items/HealthKit.mdl"
    self.BaseClass.Initialize(self)
end

local function apply_medkit(ply)
    local med = ply.GetMedical and ply:GetMedical() or nil
    if not med then return false end

    local changed = false

    for _, id in ipairs(body_zones and body_zones.zone_list or {}) do
        local zone = med.zones[id]
        if zone then
            if (zone.brute or 0) > 0 then
                zone.brute = math.max(0, (zone.brute or 0) - 25)
                changed = true
            end
            if (zone.bleeding or 0) > 0 then
                zone.bleeding = math.max(0, zone.bleeding - 0.5)
                changed = true
            end
        end
    end

    return changed
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if apply_medkit(activator) then
        activator:ChatPrint("You apply the medkit and treat your wounds.")
        self:Remove()
    else
        activator:ChatPrint("You don't need this medkit right now.")
    end
end
