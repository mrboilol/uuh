
local plyModel

hook.Add("HUDPaint", "subrosa", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end

    if not IsValid(plyModel) then
        plyModel = ClientsideModel(ply:GetModel())
        if not IsValid(plyModel) then return end
        plyModel:SetNoDraw(true)
    end

    if plyModel:GetModel() ~= ply:GetModel() then
        plyModel:SetModel(ply:GetModel())
    end
    plyModel:SetPos(Vector(0, 0, 0))
    plyModel:SetAngles(Angle(0, 0, 0))
    plyModel:SetSequence(ply:GetSequence())
    plyModel:SetCycle(ply:GetCycle())
    plyModel:SetPlaybackRate(ply:GetPlaybackRate())
    
    for i = 0, ply:GetNumPoseParameters() - 1 do
        local name = ply:GetPoseParameterName(i)
        plyModel:SetPoseParameter(name, ply:GetPoseParameter(i))
    end

    for i = 0, ply:GetNumBodyGroups() - 1 do
        plyModel:SetBodygroup(i, ply:GetBodygroup(i))
    end

    local w, h = ScrW(), ScrH()
    local size = h * 0.25
    local x = w / 2 - size / 2
    local y = h * 0.65 -- Below middle

    -- Setup lighting for silhouette effect (flat shading)
    render.MaterialOverride(Material("models/debug/debugwhite"))
    render.SetColorModulation(0.2, 0.2, 0.2) -- Dark grey silhouette
    render.SuppressEngineLighting(true)
    render.SetBlend(0.8) -- Slight transparency


    local camPos = Vector(80, 0, 36)
    local camLookAt = Vector(0, 0, 36)
    
    if ply:Crouching() then
        camPos.z = 28
        camLookAt.z = 28
    end

    local camAng = (camLookAt - camPos):Angle()

    cam.Start3D(camPos, camAng, 45, x, y, size, size)
        plyModel:DrawModel()
    cam.End3D()

    render.SetBlend(1)
    render.SuppressEngineLighting(false)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
end)

hook.Add("PostCleanupMap", "ResetSilhouetteModel", function()
    if IsValid(plyModel) then
        plyModel:Remove()
        plyModel = nil
    end
end)
