-- init.lua (server) for finished chem dispenser

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local chemistry = _G.eiry_medical and _G.eiry_medical.chemistry

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self:SetReagentIndex(1)
end

local function find_container(self)
    local nearby = ents.FindInSphere(self:GetPos() + self:GetForward() * 20, 32)
    for _, ent in ipairs(nearby) do
        if IsValid(ent) and ent.IsChemContainer and ent:IsChemContainer() then
            return ent
        end
    end
end

local function cycle_reagent(self, ply)
    if not chemistry then return end
    local list = chemistry.GetReagentList()
    if not list or #list == 0 then
        if IsValid(ply) then ply:ChatPrint("No reagents registered.") end
        return
    end

    local idx = self:GetReagentIndex()
    idx = idx + 1
    if idx > #list then idx = 1 end
    self:SetReagentIndex(idx)

    local id = list[idx]
    local def = chemistry.Get(id)
    local name = def and def.name or id
    if IsValid(ply) then
        ply:ChatPrint("[Chem Dispenser] Selected " .. name .. " (" .. id .. ")")
    end
end

local function dispense(self, ply)
    if not chemistry then return end

    local list = chemistry.GetReagentList()
    if not list or #list == 0 then return end
    local idx = self:GetReagentIndex()
    local id = list[idx]
    local def = chemistry.Get(id)
    if not def then return end

    local container = find_container(self)
    if not IsValid(container) then
        if IsValid(ply) then ply:ChatPrint("Place a beaker or syringe in front of the dispenser.") end
        return
    end

    local added = container:AddReagent(id, 10)
    if IsValid(ply) then
        if added > 0 then
            local name = def.name or id
            ply:ChatPrint(string.format("[Chem Dispenser] Added %.1f units of %s.", added, name))
        else
            ply:ChatPrint("Container is full.")
        end
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if activator:Crouching() then
        dispense(self, activator)
    else
        cycle_reagent(self, activator)
    end
end
