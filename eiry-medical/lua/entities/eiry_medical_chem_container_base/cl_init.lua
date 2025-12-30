-- cl_init.lua (client) for chem container base

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local name = self:GetMixName()
    if not name or name == "" then return end

    local ang = self:GetAngles()
    local pos = self:GetPos() + ang:Up() * 10

    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 90)

    local col = self:GetMixColor() or Vector(1, 1, 1)
    local r = math.Clamp(col.x * 255, 0, 255)
    local g = math.Clamp(col.y * 255, 0, 255)
    local b = math.Clamp(col.z * 255, 0, 255)

    cam.Start3D2D(pos, ang, 0.1)
        surface.SetFont("DermaDefault")
        local txt = name
        local w, h = surface.GetTextSize(txt)

        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(-w / 2 - 4, -h / 2 - 2, w + 8, h + 4)

        surface.SetTextColor(r, g, b, 255)
        surface.SetTextPos(-w / 2, -h / 2)
        surface.DrawText(txt)
    cam.End3D2D()
end
