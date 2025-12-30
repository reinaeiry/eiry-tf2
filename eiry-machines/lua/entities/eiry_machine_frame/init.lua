-- init.lua (server)

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local machine_api

hook.Add("Initialize", "EiryMachinesCacheAPI", function()
    if _G.eiry_machines and _G.eiry_machines.machines then
        machine_api = _G.eiry_machines.machines
    end
end)

function ENT:Initialize()
    self:SetModel("models/props_c17/TrapPropeller_Engine.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self:SetBuildStep(0)
    self:SetMachineBuilt(false)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local machine_id = self:GetMachineID()

    if not machine_api then
        activator:ChatPrint("Machine system not initialized yet.")
        return
    end

    if machine_id == "" then
        -- Try to install a nearby board first.
        if self:TryInstallBoard(activator) then
            return
        end

        activator:ChatPrint("This machine frame has no board installed.")
        return
    end

    local def = machine_api.GetMachine(machine_id)
    if not def then
        activator:ChatPrint("Unknown machine: " .. machine_id)
        return
    end

    if self:GetMachineBuilt() then
        activator:ChatPrint("This " .. (def.name or machine_id) .. " is already fully constructed.")
        return
    end

    if self:AdvanceBuildStep(def, activator) then
        return
    end

    activator:ChatPrint("Nothing to do for this step. You may need more materials.")
end

-- Simple debugging helper to configure a frame without a physical board yet.
function ENT:ConfigureDebugMachine(machine_id)
    self:SetMachineID(machine_id or "")
end

-- Attempt to find and consume a nearby board entity that matches
-- the board_class defined on the machine.
function ENT:TryInstallBoard(activator)
    if not machine_api then return false end

    local radius = 64
    local nearby = ents.FindInSphere(self:GetPos(), radius)

    for _, ent in ipairs(nearby) do
        if IsValid(ent) and ent.Base == "eiry_machine_board_base" then
            local machine_id = ent.GetMachineID and ent:GetMachineID() or nil
            if machine_id then
                local def = machine_api.GetMachine(machine_id)
                if def then
                    self:SetMachineID(machine_id)
                    self:SetBuildStep(0)
                    self:SetMachineBuilt(false)
                    ent:Remove()

                    activator:ChatPrint("Installed board for " .. (def.name or machine_id) .. ".")
                    return true
                end
            end
        end
    end

    return false
end

-- Consume required materials for the current build step, if available.
function ENT:AdvanceBuildStep(def, activator)
    local steps = def.build_steps
    if not istable(steps) or #steps == 0 then
        self:SetMachineBuilt(true)
        activator:ChatPrint("Construction complete (no build steps defined).")
        self:CompleteConstruction(def)
        return true
    end

    local current = self:GetBuildStep()
    if current < 0 then current = 0 end

    local next_index = current + 1
    local step = steps[next_index]
    if not step then
        self:SetMachineBuilt(true)
        activator:ChatPrint("Construction complete for " .. (def.name or self:GetMachineID()) .. ".")
        self:CompleteConstruction(def)
        return true
    end

    if step.type == "material" then
        local class = step.class
        local amount = step.amount or 1
        local consumed = self:ConsumeNearbyEntitiesOfClass(class, amount)

        if consumed >= amount then
            self:SetBuildStep(next_index)
            if next_index >= #steps then
                self:SetMachineBuilt(true)
                activator:ChatPrint("Construction complete for " .. (def.name or self:GetMachineID()) .. ".")
                self:CompleteConstruction(def)
            else
                activator:ChatPrint("Completed step " .. tostring(next_index) .. " for " .. (def.name or self:GetMachineID()) .. ".")
            end
            return true
        else
            activator:ChatPrint("Need " .. tostring(amount - consumed) .. " more of " .. class .. " to progress.")
            return false
        end
    end

    activator:ChatPrint("Unknown build step type: " .. tostring(step.type))
    return false
end

function ENT:ConsumeNearbyEntitiesOfClass(class, amount)
    local radius = 64
    local nearby = ents.FindInSphere(self:GetPos(), radius)
    local consumed = 0

    for _, ent in ipairs(nearby) do
        if IsValid(ent) and ent:GetClass() == class then
            ent:Remove()
            consumed = consumed + 1
            if consumed >= amount then
                break
            end
        end
    end

    return consumed
end

-- Spawn the finished machine entity (if any) and remove the frame.
function ENT:CompleteConstruction(def)
    local class = def.entity_class
    if not isstring(class) or class == "" then return end

    local machine = ents.Create(class)
    if not IsValid(machine) then return end

    machine:SetPos(self:GetPos())
    machine:SetAngles(self:GetAngles())
    machine:Spawn()
    machine:Activate()

    if machine.SetMachineID then
        machine:SetMachineID(self:GetMachineID())
    end

    self:Remove()
end
