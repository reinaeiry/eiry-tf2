-- chemistry.lua
-- SS14-inspired reagent registry and simple effect processing.

local damage_types = include("eiry_medical/core/damage_types.lua")
local body_zones = include("eiry_medical/core/body_zones.lua")

local M = {}

M.reagents = {}
M.reagent_ids = {}
M.reactions = {}

local function register(id, def)
    def.id = id
    M.reagents[id] = def
    table.insert(M.reagent_ids, id)
end

function M.Get(id)
    return M.reagents[id]
end

function M.AddReagent(med, id, amount)
    if not med or not med.reagents then return end
    if not M.reagents[id] then return end

    med.reagents[id] = (med.reagents[id] or 0) + (amount or 0)
end

function M.GetAll(med)
    return med and med.reagents or nil
end

function M.GetReagentList()
    return M.reagent_ids
end

local function add_reaction(def)
    table.insert(M.reactions, def)
end

-- Summarize a raw mixture table (id->amount) into a friendly name,
-- approximate color, and sorted component list.
local function compute_mix_info(mix)
    mix = mix or {}
    local total = 0
    for _, amt in pairs(mix) do
        if amt > 0 then
            total = total + amt
        end
    end

    local components = {}
    for id, amt in pairs(mix) do
        if amt > 0 then
            local def = M.reagents[id]
            if def then
                table.insert(components, { id = id, amount = amt, def = def })
            end
        end
    end

    table.sort(components, function(a, b) return a.amount > b.amount end)

    if total <= 0 or #components == 0 then
        return {
            name = "Empty",
            color = { r = 200, g = 200, b = 200 },
            components = {},
            total = 0,
        }
    end

    local name
    if #components == 1 then
        name = components[1].def.name or components[1].id
    else
        local a = components[1].def.name or components[1].id
        local b = components[2].def.name or components[2].id
        name = string.format("Mix: %s/%s", a, b)
    end

    local r, g, b = 0, 0, 0
    for _, comp in ipairs(components) do
        local frac = comp.amount / total
        local col = comp.def.color or { r = 255, g = 255, b = 255 }
        r = r + (col.r or 255) * frac
        g = g + (col.g or 255) * frac
        b = b + (col.b or 255) * frac
    end

    return {
        name = name,
        color = { r = r, g = g, b = b },
        components = components,
        total = total,
    }
end

function M.GetMixtureInfo(mix)
    return compute_mix_info(mix)
end

function M.FormatMixtureReport(mix)
    local info = compute_mix_info(mix)
    local lines = {}

    if info.total <= 0 or #info.components == 0 then
        table.insert(lines, "Mixture: Empty")
        return lines
    end

    table.insert(lines, string.format("Mixture: %s (%.1f units)", info.name, info.total))

    for i, comp in ipairs(info.components) do
        if i > 8 then break end
        table.insert(lines, string.format(" - %s: %.1f", comp.def.name or comp.id, comp.amount))
    end

    return lines
end

-- Apply reagent metabolism and effects each tick.
function M.Tick(med, ent, dt)
    if not med or not med.reagents then return end

    for id, units in pairs(med.reagents) do
        if units > 0 then
            local def = M.reagents[id]
            if def and def.on_tick then
                def.on_tick(def, med, ent, units, dt)
            end

            local rate = (def and def.metabolism) or 0.1
            units = units - rate * dt
            if units <= 0 then
                med.reagents[id] = nil
            else
                med.reagents[id] = units
            end
        else
            med.reagents[id] = nil
        end
    end
end

---------------------------------------------------------------------
-- Core reagents (healing & support)
---------------------------------------------------------------------

-- Basic SS14-like base chems

register("water", {
    name = "Water",
    desc = "Simple H2O; mildly dilutes other reagents.",
    color = {r = 120, g = 120, b = 255},
    metabolism = 0.02,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local factor = 1 - math.min(0.3, units * 0.01)
                zone.toxin = (zone.toxin or 0) * factor
            end
        end
    end,
})

register("carbon", {
    name = "Carbon",
    desc = "Basic solid; modest toxin if injected.",
    color = {r = 40, g = 40, b = 40},
    metabolism = 0.03,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local dmg = units * 0.05 * dt
                zone.toxin = (zone.toxin or 0) + dmg
            end
        end
    end,
})

register("oxygen", {
    name = "Oxygen",
    desc = "Restores oxygen damage.",
    color = {r = 200, g = 200, b = 255},
    metabolism = 0.04,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone and (zone.oxygen or 0) > 0 then
                local heal = units * 0.2 * dt
                zone.oxygen = math.max(0, (zone.oxygen or 0) - heal)
            end
        end
    end,
})

register("hydrogen", {
    name = "Hydrogen",
    desc = "Flammable gas; slightly increases burn damage.",
    color = {r = 230, g = 230, b = 230},
    metabolism = 0.04,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local dmg = units * 0.03 * dt
                zone.burn = (zone.burn or 0) + dmg
            end
        end
    end,
})

register("chlorine", {
    name = "Chlorine",
    desc = "Corrosive gas; damages lungs.",
    color = {r = 180, g = 255, b = 180},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local tox = units * 0.2 * dt
                local oxy = units * 0.1 * dt
                zone.toxin = (zone.toxin or 0) + tox
                zone.oxygen = (zone.oxygen or 0) + oxy
            end
        end
    end,
})

register("ethanol", {
    name = "Ethanol",
    desc = "Alcohol; mild toxin and sedative.",
    color = {r = 255, g = 255, b = 200},
    metabolism = 0.06,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local tox = units * 0.05 * dt
                zone.toxin = (zone.toxin or 0) + tox
            end
        end
        if ent and ent:IsPlayer() and units > 1 then
            if math.random() < units * 0.01 * dt then
                ent:ViewPunch(Angle(0, math.random(-2, 2), 0))
            end
        end
    end,
})

register("sugar", {
    name = "Sugar",
    desc = "Simple carbohydrate; mild stimulant.",
    color = {r = 255, g = 255, b = 255},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if ent and ent:IsPlayer() then
            if math.random() < units * 0.01 * dt then
                ent:ViewPunch(Angle(math.random(-1,1), math.random(-1,1), 0))
            end
        end
    end,
})

register("bicaridine", {
    name = "Bicaridine",
    desc = "Heals brute damage.",
    color = {r = 200, g = 0, b = 0},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone and (zone.brute or 0) > 0 then
                local heal = units * 0.2 * dt
                zone.brute = math.max(0, (zone.brute or 0) - heal)
            end
        end
    end,
})

register("kelotane", {
    name = "Kelotane",
    desc = "Heals burn damage.",
    color = {r = 255, g = 128, b = 0},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone and (zone.burn or 0) > 0 then
                local heal = units * 0.2 * dt
                zone.burn = math.max(0, (zone.burn or 0) - heal)
            end
        end
    end,
})

register("dexalin", {
    name = "Dexalin",
    desc = "Treats oxygen damage.",
    color = {r = 0, g = 128, b = 255},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone and (zone.oxygen or 0) > 0 then
                local heal = units * 0.3 * dt
                zone.oxygen = math.max(0, (zone.oxygen or 0) - heal)
            end
        end
    end,
})

register("antitoxin", {
    name = "Antitoxin",
    desc = "Reduces toxin damage.",
    color = {r = 0, g = 200, b = 0},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone and (zone.toxin or 0) > 0 then
                local heal = units * 0.25 * dt
                zone.toxin = math.max(0, (zone.toxin or 0) - heal)
            end
        end
    end,
})

register("inaprovaline", {
    name = "Inaprovaline",
    desc = "Stabilizes patients in crit.",
    color = {r = 200, g = 200, b = 255},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not ent or not ent:IsPlayer() then return end
        if med.crit then
            med.crit_stable = true
        end
    end,
})

---------------------------------------------------------------------
-- Advanced custom reagents (divergent from SS14)
---------------------------------------------------------------------

register("overdrive", {
    name = "Overdrive",
    desc = "Aggressive combat stimulant that slightly worsens injuries.",
    color = {r = 255, g = 80, b = 80},
    metabolism = 0.06,
    on_tick = function(self, med, ent, units, dt)
        if ent and ent:IsPlayer() then
            if math.random() < units * 0.02 * dt then
                ent:ViewPunch(Angle(math.random(-3, 3), math.random(-3, 3), 0))
            end
        end

        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local heal = units * 0.15 * dt
                local penalty = units * 0.03 * dt
                zone.brute = math.max(0, (zone.brute or 0) - heal)
                zone.toxin = (zone.toxin or 0) + penalty
            end
        end
    end,
})

register("regenmix", {
    name = "Regenerative Mix",
    desc = "Slowly mends all damage at the cost of exhaustion.",
    color = {r = 80, g = 220, b = 180},
    metabolism = 0.04,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        local amt = units * 0.15 * dt
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                zone.brute = math.max(0, (zone.brute or 0) - amt)
                zone.burn = math.max(0, (zone.burn or 0) - amt)
                zone.toxin = math.max(0, (zone.toxin or 0) - amt * 0.5)
                zone.oxygen = math.max(0, (zone.oxygen or 0) - amt * 0.5)
            end
        end
        if ent and ent:IsPlayer() and units > 1 then
            ent:ViewPunch(Angle(-0.5, 0, 0))
        end
    end,
})

register("neurotoxin_alpha", {
    name = "Neurotoxin Alpha",
    desc = "Violent neurotoxin that shreds nerves and lungs.",
    color = {r = 120, g = 40, b = 160},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local tox = units * 0.4 * dt
                local oxy = units * 0.2 * dt
                zone.toxin = (zone.toxin or 0) + tox
                zone.oxygen = (zone.oxygen or 0) + oxy
            end
        end
        if ent and ent:IsPlayer() and math.random() < units * 0.01 * dt then
            ent:ViewPunch(Angle(math.random(-5, 5), math.random(-5, 5), 0))
        end
    end,
})

register("adrenaline_shot", {
    name = "Adrenaline Shot",
    desc = "Brutal wake-up drug that fights crit for a while.",
    color = {r = 255, g = 200, b = 80},
    metabolism = 0.07,
    on_tick = function(self, med, ent, units, dt)
        if not med then return end
        if med.crit then
            med.crit_stable = true
        end
        if not med or not med.zones then return end
        local heal = units * 0.1 * dt
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                zone.oxygen = math.max(0, (zone.oxygen or 0) - heal)
            end
        end
        if ent and ent:IsPlayer() and units > 0.5 then
            if math.random() < units * 0.03 * dt then
                ent:ViewPunch(Angle(math.random(0, 2), 0, 0))
            end
        end
    end,
})

register("stasis_foam", {
    name = "Stasis Foam",
    desc = "Locks the body in place and halts bleeding.",
    color = {r = 200, g = 230, b = 255},
    metabolism = 0.03,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        med.bleeding = 0
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                zone.brute = math.max(0, (zone.brute or 0) - units * 0.05 * dt)
                zone.burn = math.max(0, (zone.burn or 0) - units * 0.05 * dt)
            end
        end
        if ent and ent:IsPlayer() and units > 0.5 then
            ent:AddAngleVelocity(Vector(0, 0, 0))
        end
    end,
})

register("purge", {
    name = "Purge Solvent",
    desc = "Rapidly scrubs other chemicals from the bloodstream.",
    color = {r = 180, g = 220, b = 255},
    metabolism = 0.06,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.reagents then return end
        for id, amt in pairs(med.reagents) do
            if id ~= self.id and id ~= "purge" then
                med.reagents[id] = amt * math.max(0, 1 - units * 0.3 * dt)
                if med.reagents[id] <= 0.01 then
                    med.reagents[id] = nil
                end
            end
        end
    end,
})

register("hypertoxin", {
    name = "Hypertoxin", 
    desc = "Concentrated systemic poison.",
    color = {r = 50, g = 10, b = 10},
    metabolism = 0.04,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local dmg = units * 0.35 * dt
                zone.toxin = (zone.toxin or 0) + dmg
                zone.brute = (zone.brute or 0) + dmg * 0.25
            end
        end
    end,
})

---------------------------------------------------------------------
-- Poisons (example reagents)
---------------------------------------------------------------------

register("toxin_basic", {
    name = "Basic Toxin",
    desc = "Deals toxin damage over time.",
    color = {r = 50, g = 200, b = 50},
    metabolism = 0.05,
    on_tick = function(self, med, ent, units, dt)
        if not med or not med.zones then return end
        for _, id in ipairs(body_zones.zone_list) do
            local zone = med.zones[id]
            if zone then
                local dmg = units * 0.15 * dt
                zone.toxin = (zone.toxin or 0) + dmg
            end
        end
    end,
})

---------------------------------------------------------------------
-- Auto-generated functional reagents to reach large counts
---------------------------------------------------------------------
-- Ensure we have at least 500 reagents registered, all with some effect.
local target_count = 500
local base_count = 0
for _ in pairs(M.reagents) do
    base_count = base_count + 1
end

local function make_effect(kind, scale)
    if kind == "heal_brute" then
        return function(self, med, ent, units, dt)
            if not med or not med.zones then return end
            local total = units * scale * dt
            for _, id in ipairs(body_zones.zone_list) do
                local zone = med.zones[id]
                if zone and (zone.brute or 0) > 0 then
                    local heal = total / #body_zones.zone_list
                    zone.brute = math.max(0, (zone.brute or 0) - heal)
                end
            end
        end
    elseif kind == "heal_burn" then
        return function(self, med, ent, units, dt)
            if not med or not med.zones then return end
            local total = units * scale * dt
            for _, id in ipairs(body_zones.zone_list) do
                local zone = med.zones[id]
                if zone and (zone.burn or 0) > 0 then
                    local heal = total / #body_zones.zone_list
                    zone.burn = math.max(0, (zone.burn or 0) - heal)
                end
            end
        end
    elseif kind == "heal_toxin" then
        return function(self, med, ent, units, dt)
            if not med or not med.zones then return end
            local total = units * scale * dt
            for _, id in ipairs(body_zones.zone_list) do
                local zone = med.zones[id]
                if zone and (zone.toxin or 0) > 0 then
                    local heal = total / #body_zones.zone_list
                    zone.toxin = math.max(0, (zone.toxin or 0) - heal)
                end
            end
        end
    elseif kind == "damage_toxin" then
        return function(self, med, ent, units, dt)
            if not med or not med.zones then return end
            local total = units * scale * dt
            for _, id in ipairs(body_zones.zone_list) do
                local zone = med.zones[id]
                if zone then
                    local dmg = total / #body_zones.zone_list
                    zone.toxin = (zone.toxin or 0) + dmg
                end
            end
        end
    elseif kind == "stimulant" then
        return function(self, med, ent, units, dt)
            if not ent or not ent:IsPlayer() then return end
            if math.random() < units * scale * dt * 0.01 then
                ent:ViewPunch(Angle(math.random(-2, 2), math.random(-2, 2), 0))
            end
        end
    elseif kind == "sedative" then
        return function(self, med, ent, units, dt)
            if not ent or not ent:IsPlayer() then return end
            if units * scale > 5 then
                ent:ViewPunch(Angle(-1, 0, 0))
            end
        end
    else
        return function() end
    end
end

local templates = {
    { kind = "heal_brute", scale = 0.15, base_color = {200, 50, 50} },
    { kind = "heal_burn", scale = 0.15, base_color = {255, 140, 40} },
    { kind = "heal_toxin", scale = 0.15, base_color = {40, 200, 40} },
    { kind = "damage_toxin", scale = 0.2, base_color = {80, 160, 80} },
    { kind = "stimulant", scale = 1.0, base_color = {180, 180, 255} },
    { kind = "sedative", scale = 1.0, base_color = {160, 120, 220} },
}

local i = 1
while base_count < target_count do
    local tmpl = templates[((i - 1) % #templates) + 1]
    local id = string.format("rx_%03d", i)
    if not M.reagents[id] then
        local r, g, b = unpack(tmpl.base_color)
        r = math.Clamp(r + math.random(-20, 20), 0, 255)
        g = math.Clamp(g + math.random(-20, 20), 0, 255)
        b = math.Clamp(b + math.random(-20, 20), 0, 255)

        register(id, {
            name = string.format("Experimental Compound %03d", i),
            desc = "Auto-generated reagent with simple effects.",
            color = { r = r, g = g, b = b },
            metabolism = 0.04,
            on_tick = make_effect(tmpl.kind, tmpl.scale),
        })
        base_count = base_count + 1
    end
    i = i + 1
end

---------------------------------------------------------------------
-- Reactions: combine base chems into useful meds
---------------------------------------------------------------------

-- Simple helper to declare stoichiometric reactions. All amounts are in
-- arbitrary "units" and operate directly on container mixtures.

add_reaction({
    id = "bicaridine_synthesis",
    inputs = { carbon = 1, oxygen = 1, water = 1 },
    outputs = { bicaridine = 1 },
    max_times = 5,
})

add_reaction({
    id = "kelotane_synthesis",
    inputs = { carbon = 1, hydrogen = 1, water = 1 },
    outputs = { kelotane = 1 },
    max_times = 5,
})

add_reaction({
    id = "dexalin_synthesis",
    inputs = { oxygen = 2, water = 1 },
    outputs = { dexalin = 1 },
    max_times = 5,
})

add_reaction({
    id = "antitoxin_synthesis",
    inputs = { carbon = 1, chlorine = 1, water = 1 },
    outputs = { antitoxin = 1 },
    max_times = 5,
})

add_reaction({
    id = "inaprovaline_blend",
    inputs = { bicaridine = 1, dexalin = 1, sugar = 0.5 },
    outputs = { inaprovaline = 2 },
    max_times = 3,
})

add_reaction({
    id = "ethanol_from_sugar",
    inputs = { sugar = 1, water = 1 },
    outputs = { ethanol = 1 },
    max_times = 10,
})

add_reaction({
    id = "overdrive_mixture",
    inputs = { bicaridine = 1, kelotane = 1, sugar = 1 },
    outputs = { overdrive = 2 },
    max_times = 4,
})

add_reaction({
    id = "regenmix_full_stack",
    inputs = { bicaridine = 1, kelotane = 1, dexalin = 1, antitoxin = 1, water = 1 },
    outputs = { regenmix = 3 },
    max_times = 3,
})

add_reaction({
    id = "adrenaline_brew",
    inputs = { dexalin = 1, sugar = 0.5, oxygen = 1 },
    outputs = { adrenaline_shot = 2 },
    max_times = 4,
})

add_reaction({
    id = "stasis_foam_mix",
    inputs = { inaprovaline = 1, kelotane = 0.5, water = 1 },
    outputs = { stasis_foam = 2 },
    max_times = 4,
})

add_reaction({
    id = "purge_solvent_mix",
    inputs = { antitoxin = 1, water = 1, oxygen = 1 },
    outputs = { purge = 2 },
    max_times = 4,
})

add_reaction({
    id = "neurotoxin_alpha_synthesis",
    inputs = { toxin_basic = 1, chlorine = 1, ethanol = 1 },
    outputs = { neurotoxin_alpha = 2 },
    max_times = 5,
})

add_reaction({
    id = "hypertoxin_concentrate",
    inputs = { neurotoxin_alpha = 1, toxin_basic = 1, ethanol = 0.5 },
    outputs = { hypertoxin = 2 },
    max_times = 3,
})

add_reaction({
    id = "toxin_refinement_one",
    inputs = { toxin_basic = 1, antitoxin = 1, water = 1 },
    outputs = { rx_001 = 2 },
    max_times = 6,
})

add_reaction({
    id = "combat_tonic",
    inputs = { overdrive = 1, adrenaline_shot = 1, sugar = 0.5 },
    outputs = { rx_002 = 2 },
    max_times = 3,
})

add_reaction({
    id = "burnshield_mix",
    inputs = { kelotane = 1, ethanol = 0.5, water = 1 },
    outputs = { rx_003 = 2 },
    max_times = 4,
})

add_reaction({
    id = "deep_detox",
    inputs = { purge = 1, antitoxin = 1, water = 1 },
    outputs = { rx_004 = 2 },
    max_times = 4,
})

add_reaction({
    id = "regen_booster",
    inputs = { regenmix = 1, stasis_foam = 1, adrenaline_shot = 1 },
    outputs = { rx_005 = 3 },
    max_times = 2,
})

add_reaction({
    id = "stimulant_chain_a",
    inputs = { sugar = 1, ethanol = 1, oxygen = 0.5 },
    outputs = { rx_006 = 2 },
    max_times = 5,
})

add_reaction({
    id = "stimulant_chain_b",
    inputs = { rx_006 = 1, adrenaline_shot = 1 },
    outputs = { rx_007 = 2 },
    max_times = 3,
})

add_reaction({
    id = "shock_gel",
    inputs = { hydrogen = 1, water = 1, kelotane = 0.5 },
    outputs = { rx_008 = 2 },
    max_times = 4,
})

add_reaction({
    id = "lung_wash",
    inputs = { water = 1, oxygen = 1, antitoxin = 0.5 },
    outputs = { rx_009 = 2 },
    max_times = 4,
})

add_reaction({
    id = "nerve_stabilizer",
    inputs = { inaprovaline = 1, ethanol = 0.5, water = 1 },
    outputs = { rx_010 = 2 },
    max_times = 3,
})

add_reaction({
    id = "panic_mix",
    inputs = { hypertoxin = 1, overdrive = 1, sugar = 1 },
    outputs = { rx_011 = 3 },
    max_times = 2,
})

add_reaction({
    id = "cryobath",
    inputs = { water = 2, dexalin = 1, kelotane = 1 },
    outputs = { rx_012 = 3 },
    max_times = 3,
})

add_reaction({
    id = "stasis_regen_loop",
    inputs = { regenmix = 1, stasis_foam = 1, water = 1 },
    outputs = { regenmix = 1.5, stasis_foam = 1.5 },
    max_times = 2,
})

-- Core reaction solver operating on a mixture table id->amount.
local function process_mix(mix)
    if not mix then return end

    local changed = true
    local safety = 8

    while changed and safety > 0 do
        changed = false

        for _, rx in ipairs(M.reactions) do
            local max_times = math.huge

            for id, need in pairs(rx.inputs) do
                local have = mix[id] or 0
                if need > 0 then
                    max_times = math.min(max_times, have / need)
                end
            end

            if max_times >= 1 then
                local times = math.floor(max_times)
                if rx.max_times then
                    times = math.min(times, rx.max_times)
                end

                if times > 0 then
                    changed = true

                    for id, need in pairs(rx.inputs) do
                        local v = (mix[id] or 0) - need * times
                        mix[id] = v > 0.0001 and v or nil
                    end

                    for id, out in pairs(rx.outputs) do
                        mix[id] = (mix[id] or 0) + out * times
                    end
                end
            end
        end

        safety = safety - 1
    end
end

function M.ProcessMixture(mix)
    process_mix(mix)
    return mix
end

-- Optional helper for containers to call.
function M.ProcessContainer(ent)
    if not IsValid(ent) then return end
    if not ent.ChemContents then return end
    process_mix(ent.ChemContents)
    if ent.RefreshChemAppearance then
        ent:RefreshChemAppearance()
    end
end

return M
