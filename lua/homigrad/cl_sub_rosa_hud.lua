
local hg_subrosa_hud = CreateClientConVar("hg_subrosa_hud", "1", true, false, "Enable Sub Rosa style body HUD")

local subrosa_model
local last_model_path

local function UpdateSubRosaModel(source)
    local model_path = source:GetModel()
    
    if not IsValid(subrosa_model) or last_model_path ~= model_path then
        if IsValid(subrosa_model) then subrosa_model:Remove() end
        
        subrosa_model = ClientsideModel(model_path, RENDERGROUP_OPAQUE)
        subrosa_model:SetNoDraw(true)
        subrosa_model:SetIK(false)
        
        last_model_path = model_path
    end
end

local function CopyBones(source, target)
    if not IsValid(source) or not IsValid(target) then return end
    

    if target:GetModel() ~= source:GetModel() then
        target:SetModel(source:GetModel())
    end

    source:SetupBones()
    

    for i = 0, source:GetBoneCount() - 1 do
        local mat = source:GetBoneMatrix(i)
        if mat then
            target:SetBoneMatrix(i, mat)
        end
    end
    

    target:SetSkin(source:GetSkin())
    for k, v in pairs(source:GetBodyGroups()) do
        target:SetBodygroup(v.id, source:GetBodygroup(v.id))
    end
    
    target:SetMaterial(source:GetMaterial())

    target:SetColor(source:GetColor())
end
--ok time to lock in
hook.Add("HUDPaint", "HG_SubRosaHUD", function()
    if not hg_subrosa_hud:GetBool() then 
        if IsValid(subrosa_model) then subrosa_model:Remove() end
        return 
    end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local source = ply
    if IsValid(ply.FakeRagdoll) then
        source = ply.FakeRagdoll
    end

    UpdateSubRosaModel(source)

    if not IsValid(subrosa_model) then return end

    CopyBones(source, subrosa_model)

    local w, h = ScrW(), ScrH()
    local size = h * 0.35
    local x, y = (w * 0.5) - (size * 0.5), h - size + (size * 0.15)

    local rootPos = source:GetPos()
    local centerPos = rootPos + Vector(0, 0, 35)

    local eyeAng = ply:EyeAngles()
    eyeAng.p = 0
    eyeAng.r = 0
    

    
    local forward = eyeAng:Forward()
    
    local viewPos = rootPos + (forward * 80) + Vector(0, 0, 45)

    local lookAtPos = rootPos + Vector(0, 0, 35)
    if IsValid(ply.FakeRagdoll) then

        local phys = ply.FakeRagdoll:GetPhysicsObject()
        if IsValid(phys) then
             lookAtPos = ply.FakeRagdoll:GetPos() + Vector(0,0,10)
             viewPos = lookAtPos + (forward * 80) + Vector(0, 0, 45)
        end
    end

    local viewAng = (lookAtPos - viewPos):Angle()

    cam.Start3D(viewPos, viewAng, 40, x, y, size, size)
        render.SuppressEngineLighting(true)
        render.SetLightingOrigin(rootPos)
        render.ResetModelLighting(0.5, 0.5, 0.5)
        render.SetModelLighting(BOX_TOP, 1, 1, 1)
        render.SetModelLighting(BOX_FRONT, 1, 1, 1)

        subrosa_model:DrawModel()
        
        local weapon = ply:GetActiveWeapon()
        if IsValid(weapon) then
        end
        
        render.SuppressEngineLighting(false)
    cam.End3D()
end)
