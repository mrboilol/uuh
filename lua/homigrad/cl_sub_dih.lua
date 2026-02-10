
local plyModel
local matWhite = Material("models/debug/debugwhite")

-- Global cleanup
if IsValid(HG_Silhouette_PlyModel) then HG_Silhouette_PlyModel:Remove() end
if IsValid(HG_Silhouette_WepModel) then HG_Silhouette_WepModel:Remove() end

local function GetSilhouetteModel(ply)
    local targetModel = ply:GetModel()
    
    if not IsValid(HG_Silhouette_PlyModel) or HG_Silhouette_PlyModel:GetModel() ~= targetModel then
        if IsValid(HG_Silhouette_PlyModel) then HG_Silhouette_PlyModel:Remove() end
        HG_Silhouette_PlyModel = ClientsideModel(targetModel)
        if IsValid(HG_Silhouette_PlyModel) then
            HG_Silhouette_PlyModel:SetNoDraw(true)
            HG_Silhouette_PlyModel:SetIK(false)
            
            -- Find an idle sequence
            local seq = HG_Silhouette_PlyModel:LookupSequence("idle_all_01")
            if seq == -1 then seq = HG_Silhouette_PlyModel:LookupSequence("idle") end
            if seq == -1 then seq = 0 end
            
            HG_Silhouette_PlyModel:ResetSequence(seq)
        end
    end
    plyModel = HG_Silhouette_PlyModel
    return plyModel
end

hook.Add("HUDPaint", "subrosa", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end

    GetSilhouetteModel(ply)
    
    if not IsValid(plyModel) then return end
    
    -- Ensure updates but strictly idle
    plyModel:FrameAdvance(FrameTime())
    
    local w, h = ScrW(), ScrH()
    local size = h * 0.35 -- Scaled up a little bit as requested
    local x = w / 2 - size / 2
    local y = h * 0.60 

    render.MaterialOverride(matWhite)
    render.SetColorModulation(1, 1, 1)
    render.SuppressEngineLighting(true)
    render.SetBlend(1) 

    local camDist = 90 -- Closer camera for larger view
    local camPos = Vector(camDist, 0, 35) -- Centered around torso/head
    local camLookAt = Vector(0, 0, 35)
    local camAng = (camLookAt - camPos):Angle()

    cam.Start3D(camPos, camAng, 50, x, y, size, size)
        plyModel:SetPos(Vector(0,0,0))
        plyModel:SetAngles(Angle(0,0,0))
        plyModel:DrawModel()
    cam.End3D()

    render.SetBlend(1)
    render.SuppressEngineLighting(false)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
end)

hook.Add("PostCleanupMap", "ResetSilhouetteModel", function()
    if IsValid(HG_Silhouette_PlyModel) then
        HG_Silhouette_PlyModel:Remove()
        HG_Silhouette_PlyModel = nil
    end
    plyModel = nil
end)
