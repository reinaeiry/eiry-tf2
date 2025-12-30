-- Bridged eiry-materials autorun under lua/.

if SERVER then
    AddCSLuaFile()
end

_G.eiry_materials = _G.eiry_materials or {}

if SERVER then
    print("[eiry-materials] Loaded core materials (bridged).")
end
