-- init.lua (server) for chem master

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local modes = { "pills", "bottle" }

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self:SetModeIndex(1)
end

local function find_beaker(self)
    local nearby = ents.FindInSphere(self:GetPos() + self:GetForward() * 20, 32)
    for _, ent in ipairs(nearby) do
        if IsValid(ent) and ent.IsChemContainer and ent:IsChemContainer() then
            if ent:GetClass() == "eiry_medical_chem_beaker" then
                return ent
            end
        end
    end
end

local function make_pills(self, ply)
    local beaker = find_beaker(self)
    if not IsValid(beaker) then
        if IsValid(ply) then ply:ChatPrint("Place a beaker in front of the Chem Master.") end
        return
    end

    local total = beaker:GetChemVolume()
    if total <= 0 then
        if IsValid(ply) then ply:ChatPrint("The beaker is empty.") end
        return
    end

    local mix = beaker:RemoveMixture(total)
    local pills = math.max(1, math.min(10, math.floor(total / 5)))
    local per_pill = {}
    for id, v in pairs(mix) do
        per_pill[id] = v / pills
    end

    local bottle = ents.Create("eiry_medical_chem_pill_bottle")
    if not IsValid(bottle) then return end
    bottle:SetPos(self:GetPos() + self:GetForward() * 30 + Vector(0, 0, 10))
    bottle:SetAngles(self:GetAngles())
    bottle:Spawn()
    bottle:Activate()
    bottle:SetPillData(per_pill, pills)

    if IsValid(ply) then
        ply:ChatPrint(string.format("[Chem Master] Created %d pills.", pills))
    end
end

local function make_bottle(self, ply)
    local beaker = find_beaker(self)
    if not IsValid(beaker) then
        if IsValid(ply) then ply:ChatPrint("Place a beaker in front of the Chem Master.") end
        return
    end

    local total = beaker:GetChemVolume()
    if total <= 0 then
        if IsValid(ply) then ply:ChatPrint("The beaker is empty.") end
        return
    end

    local mix = beaker:RemoveMixture(total)

    local bottle = ents.Create("eiry_medical_chem_bottle")
    if not IsValid(bottle) then return end
    bottle:SetPos(self:GetPos() + self:GetForward() * 30 + Vector(0, 0, 10))
    bottle:SetAngles(self:GetAngles())
    bottle:Spawn()
    bottle:Activate()
    bottle:ReceiveMixture(mix)

    if IsValid(ply) then
        ply:ChatPrint("[Chem Master] Created a bottle from the beaker contents.")
    end
end

local function cycle_mode(self, ply)
    local idx = self:GetModeIndex()
    idx = idx + 1
    if idx > #modes then idx = 1 end
    self:SetModeIndex(idx)

    if IsValid(ply) then
        ply:ChatPrint("[Chem Master] Mode: " .. modes[idx])
    end
end

local function perform_action(self, ply)
    local mode = modes[self:GetModeIndex()] or "pills"
    if mode == "pills" then
        make_pills(self, ply)
    elseif mode == "bottle" then
        make_bottle(self, ply)
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if activator:Crouching() then
        perform_action(self, activator)
    else
        cycle_mode(self, activator)
    end
end
