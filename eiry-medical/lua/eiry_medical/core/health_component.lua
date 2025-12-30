-- health_component.lua
-- Per-entity medical state with SS14-style damage types and body zones.

local damage_types = include("eiry_medical/core/damage_types.lua")
local body_zones = include("eiry_medical/core/body_zones.lua")
local chemistry = include("eiry_medical/core/chemistry.lua")

local M = {}

local function new_zone_state(zone_def)
    local t = {}
    for id, _ in pairs(damage_types.types) do
        t[id] = 0
    end
    t.max_health = zone_def.max_health or 100
    t.bleeding = 0 -- bleed rate for this zone
    return t
end

function M.Create()
    local self = {}

    self.zones = {}
    for _, id in ipairs(body_zones.zone_list) do
        local def = body_zones.Get(id)
        self.zones[id] = new_zone_state(def)
    end

    self.total_oxygen = 0
    self.total_toxin = 0
    self.alive = true

    self.crit = false
    self.crit_time = 0
    self.crit_stable = false

    self.reagents = {}

    return self
end

function M.ApplyDamage(self, zone_id, dmg_type, amount)
    if not self.alive then return end

    local zone = self.zones[zone_id]
    if not zone then return end

    local dtype = damage_types.Normalize(dmg_type)
    if not dtype then return end

    amount = math.max(0, amount or 0)

    zone[dtype.id] = (zone[dtype.id] or 0) + amount

    if dtype.id == "brute" and amount > 5 then
        zone.bleeding = (zone.bleeding or 0) + 0.05 * amount
    end
end

function M.Tick(self, ent, dt)
    if not self.alive then return end
    if not IsValid(ent) then return end

    -- Apply chemistry effects first.
    if chemistry then
        chemistry.Tick(self, ent, dt)
    end

    local total_oxy = 0
    local total_toxin = 0

    for _, id in ipairs(body_zones.zone_list) do
        local zone = self.zones[id]
        if zone then
            local bleed = zone.bleeding or 0
            if bleed > 0 then
                zone.brute = (zone.brute or 0) + bleed * dt
                zone.oxygen = (zone.oxygen or 0) + bleed * dt * 0.5
            end
            total_oxy = total_oxy + (zone.oxygen or 0)
            total_toxin = total_toxin + (zone.toxin or 0)
        end
    end

    self.total_oxygen = total_oxy
    self.total_toxin = total_toxin

    local health_fraction = 1.0
    local worst = 0
    for _, id in ipairs(body_zones.zone_list) do
        local zone = self.zones[id]
        local brute = zone.brute or 0
        local burn = zone.burn or 0
        local sum = brute + burn
        if sum > worst then
            worst = sum
        end
    end

    health_fraction = math.Clamp(1.0 - worst / 200, -1, 1)

    if ent:IsPlayer() then
        local target_hp = math.max(1, 100 * health_fraction)
        ent:SetHealth(target_hp)
    end

    -- Basic crit handling: below 25% health we enter crit and freeze.
    if not self.crit and health_fraction <= 0.25 and health_fraction > 0 then
        self.crit = true
        self.crit_time = 0
        if ent:IsPlayer() then
            ent:Freeze(true)
            ent:ChatPrint("You collapse into critical condition!")
        end
    end

    if self.crit then
        self.crit_time = self.crit_time + dt

        -- If stabilized by reagents, we don't die from elapsed time alone.
        if not self.crit_stable and (self.crit_time > 30 or self.total_oxygen > 100) then
            self.alive = false
            if ent:IsPlayer() and ent:Alive() then
                ent:Kill()
            end
            return
        end
    end

    if health_fraction <= 0 then
        self.alive = false
        if ent:IsPlayer() and ent:Alive() then
            ent:Kill()
        end
    end
end

return M
