-- hooks.lua
-- Integrate the medical system into Garry's Mod player lifecycle.

local health_component = _G.eiry_medical and _G.eiry_medical.health
local body_zones = _G.eiry_medical and _G.eiry_medical.body_zones

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMedical()
    self._eiry_medical = self._eiry_medical or (health_component and health_component.Create() or nil)
    return self._eiry_medical
end

hook.Add("PlayerInitialSpawn", "EiryMedical_Init", function(ply)
    if not health_component then return end
    ply._eiry_medical = health_component.Create()
end)

hook.Add("PlayerSpawn", "EiryMedical_ResetOnSpawn", function(ply)
    if not health_component then return end
    ply._eiry_medical = health_component.Create()
    ply:SetHealth(100)
end)

hook.Add("EntityTakeDamage", "EiryMedical_RouteDamage", function(ent, dmginfo)
    if not health_component then return end
    if not ent:IsPlayer() then return end

    local med = ent:GetMedical()
    if not med then return end

    local zone_id = "torso"
    local hg = dmginfo:GetDamagePosition()
    -- For now, map everything to torso; later we can decode hitgroups.

    local dtype = "brute"
    local dtype_id = dmginfo:GetDamageType()
    if bit.band(dtype_id, DMG_BURN) ~= 0 then
        dtype = "burn"
    end

    local amount = dmginfo:GetDamage()
    med:ApplyDamage(zone_id, dtype, amount)

    -- We drive HP ourselves; prevent double-counting.
    dmginfo:SetDamage(0)
end)

-- Simple global tick for all players' medical state.
hook.Add("Think", "EiryMedical_Tick", function()
    if not health_component then return end

    local dt = FrameTime()
    for _, ply in ipairs(player.GetAll()) do
        local med = ply:GetMedical()
        if med then
            med:Tick(ply, dt)
        end
    end
end)
