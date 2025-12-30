-- init.lua (server) for health scanner

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local body_zones = _G.eiry_medical and _G.eiry_medical.body_zones

function ENT:Initialize()
    self.ModelOverride = "models/Items/battery.mdl"
    self.BaseClass.Initialize(self)
end

local function describe_medical(ply)
    local med = ply.GetMedical and ply:GetMedical() or nil
    if not med then
        return "No medical data."
    end

    local lines = {}
    table.insert(lines, "-- Vitals for " .. ply:Nick() .. " --")

    for _, id in ipairs(body_zones and body_zones.zone_list or {}) do
        local zone = med.zones[id]
        if zone then
            local brute = math.floor(zone.brute or 0)
            local burn = math.floor(zone.burn or 0)
            local oxy = math.floor(zone.oxygen or 0)
            local tox = math.floor(zone.toxin or 0)
            local bleed = zone.bleeding or 0
            table.insert(lines, string.format("%s: B:%d Bu:%d O:%d T:%d Bleed:%.2f", id, brute, burn, oxy, tox, bleed))
        end
    end

    return table.concat(lines, "\n")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local trace = activator:GetEyeTrace()
    local target = IsValid(trace.Entity) and trace.Entity or activator

    if not target:IsPlayer() then
        activator:ChatPrint("Point at a player to scan.")
        return
    end

    local report = describe_medical(target)
    for _, line in ipairs(string.Explode("\n", report, false)) do
        activator:ChatPrint(line)
    end
end
