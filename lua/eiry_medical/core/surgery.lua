-- surgery.lua
-- Very simplified SS14-inspired surgery framework.

local body_zones = include("eiry_medical/core/body_zones.lua")

local M = {}

M.procedures = {
    basic_cleanup = {
        id = "basic_cleanup",
        label = "Basic Wound Treatment",
        steps = { "scalpel", "hemostat", "retractor", "cautery", "suture" },
        effect = function(med, zone)
            if not med or not zone then return end
            zone.brute = math.max(0, (zone.brute or 0) - 40)
            zone.burn = math.max(0, (zone.burn or 0) - 20)
            zone.bleeding = 0
        end,
    },
}

local function ensure_surgery_state(med)
    med.surgery = med.surgery or {}
    return med.surgery
end

local function get_zone_for_hitgroup(hitgroup)
    if hitgroup == HITGROUP_HEAD then return "head" end
    if hitgroup == HITGROUP_CHEST or hitgroup == HITGROUP_STOMACH then return "torso" end
    if hitgroup == HITGROUP_LEFTARM then return "left_arm" end
    if hitgroup == HITGROUP_RIGHTARM then return "right_arm" end
    if hitgroup == HITGROUP_LEFTLEG then return "left_leg" end
    if hitgroup == HITGROUP_RIGHTLEG then return "right_leg" end
    return "torso"
end

function M.ApplyTool(user, target, tool_id, hitgroup)
    if not IsValid(target) or not target:IsPlayer() then return end
    local med = target.GetMedical and target:GetMedical() or nil
    if not med then return end

    local surgery = ensure_surgery_state(med)
    local zone_id = get_zone_for_hitgroup(hitgroup or HITGROUP_CHEST)

    local zone_state = surgery[zone_id]
    if not zone_state then
        zone_state = { procedure = "basic_cleanup", step = 1 }
        surgery[zone_id] = zone_state
    end

    local proc = M.procedures[zone_state.procedure]
    if not proc then return end

    local expected = proc.steps[zone_state.step]
    if tool_id ~= expected then
        if IsValid(user) and user:IsPlayer() then
            user:ChatPrint("You fumble the procedure on the " .. zone_id .. ".")
        end
        surgery[zone_id] = nil
        return
    end

    zone_state.step = zone_state.step + 1

    if IsValid(user) and user:IsPlayer() then
        user:ChatPrint("You advance the surgery on the " .. zone_id .. " (" .. tool_id .. ")")
    end

    if zone_state.step > #proc.steps then
        local zone = med.zones[zone_id]
        if proc.effect then
            proc.effect(med, zone)
        end
        surgery[zone_id] = nil
        if IsValid(user) and user:IsPlayer() then
            user:ChatPrint("You complete " .. proc.label .. " on the " .. zone_id .. ".")
        end
    end
end

return M
