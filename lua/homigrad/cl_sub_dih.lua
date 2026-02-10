

local HUD_SIZE = 300
local VIEW_FOV = 45
local matWhite = Material("models/debug/debugwhite")
local hudMdl = nil

hook.Add("HUDPaint", "subrosahuy", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local target = ply
    if IsValid(ply:GetRagdollEntity()) then
        target = ply:GetRagdollEntity()
    end

    if not IsValid(hudMdl) or hudMdl:GetModel() ~= target:GetModel() then
        if IsValid(hudMdl) then hudMdl:Remove() end
        hudMdl = ClientsideModel(target:GetModel(), RENDERGROUP_OPAQUE)
        hudMdl:SetNoDraw(true)
        hudMdl:SetIK(false)
    end

    local x = (ScrW() - HUD_SIZE) / 2
    local y = (ScrH() - HUD_SIZE) / 2

    cam.Start3D(Vector(100, 0, 36), Angle(0, 180, 0), VIEW_FOV, x, y, HUD_SIZE, HUD_SIZE)
        render.SuppressEngineLighting(true)
        render.SetColorModulation(1, 1, 1)
        render.MaterialOverride(matWhite)

        target:SetupBones()
        local targetPos = target:GetPos()

        local count = target:GetBoneCount()
        if count then
            for i = 0, count - 1 do
                local matrix = target:GetBoneMatrix(i)
                if matrix then
                    local newPos = matrix:GetTranslation() - targetPos
                    matrix:SetTranslation(newPos)
                    hudMdl:SetBoneMatrix(i, matrix)
                end
            end
        end

        hudMdl:SetPos(Vector(0,0,0))
        hudMdl:DrawModel()

        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
    cam.End3D()
end)

hook.Add("PostCleanupMap", "movenigg", function()
    if IsValid(hudMdl) then hudMdl:Remove() end
end)