if SERVER then AddCSLuaFile() include("svrkd_angry_birds_base.lua") end

/********************************************************
	SWEP Construction Kit base code
	Created by Clavus
	Modified for Matilda: Egg Drop + Ability Sound
********************************************************/

function SWEP:Initialize()
	self:SetHoldType("grenade")
	if CLIENT then
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )
		self:CreateModels(self.VElements)
		self:CreateModels(self.WElements)
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					vm:SetColor(Color(255,255,255,1))
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	end
end

function SWEP:Holster()
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
	end
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then
	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		if (!self.VElements) then return end
		self:UpdateBonePositions(vm)
		if (!self.vRenderOrder) then
			self.vRenderOrder = {}
			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then table.insert(self.vRenderOrder, k) end
			end
		end
		for k, name in ipairs( self.vRenderOrder ) do
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			if (!v.bone) then continue end
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			if (!pos) then continue end
			if (v.type == "Model" and IsValid(model)) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				if (v.material == "") then model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then model:SetMaterial( v.material ) end
				if (v.skin and v.skin != model:GetSkin()) then model:SetSkin(v.skin) end
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then model:SetBodygroup(k, v) end
					end
				end
				if (v.surpresslightning) then render.SuppressEngineLighting(true) end
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				if (v.surpresslightning) then render.SuppressEngineLighting(false) end
			elseif (v.type == "Sprite" and sprite) then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif (v.type == "Quad" and v.draw_func) then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()
			end
		end
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then self:DrawModel() end
		if (!self.WElements) then return end
		if (!self.wRenderOrder) then
			self.wRenderOrder = {}
			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then table.insert(self.wRenderOrder, k) end
			end
		end
		local bone_ent = IsValid(self.Owner) and self.Owner or self
		for k, name in pairs( self.wRenderOrder ) do
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			local pos, ang
			if (v.bone) then pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" ) end
			if (!pos) then continue end
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			if (v.type == "Model" and IsValid(model)) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				if (v.material == "") then model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then model:SetMaterial( v.material ) end
				if (v.skin and v.skin != model:GetSkin()) then model:SetSkin(v.skin) end
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then model:SetBodygroup(k, v) end
					end
				end
				if (v.surpresslightning) then render.SuppressEngineLighting(true) end
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				if (v.surpresslightning) then render.SuppressEngineLighting(false) end
			elseif (v.type == "Sprite" and sprite) then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif (v.type == "Quad" and v.draw_func) then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()
			end
		end
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			local v = basetab[tab.rel]
			if (!v) then return end
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			if (!pos) then return end
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tab.bone)
			if (!bone) then return end
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then pos, ang = m:GetTranslation(), m:GetAngles() end
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip) then ang.r = -ang.r end
		end
		return pos, ang
	end

	function SWEP:CreateModels( tab )
		if (!tab) then return end
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else v.modelEnt = nil end
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then params["$"..j] = 1 name = name.."1" else name = name.."0" end
				end
				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
			end
		end
	end

	function SWEP:UpdateBonePositions(vm)
		if self.ViewModelBoneMods then
			if (!vm:GetBoneCount()) then return end
			local loopthrough = self.ViewModelBoneMods
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				if vm:GetManipulateBoneScale(bone) != s then vm:ManipulateBoneScale( bone, s ) end
				if vm:GetManipulateBoneAngles(bone) != v.angle then vm:ManipulateBoneAngles( bone, v.angle ) end
				if vm:GetManipulateBonePosition(bone) != p then vm:ManipulateBonePosition( bone, p ) end
			end
		else self:ResetBonePositions(vm) end
	end
	
	function SWEP:ResetBonePositions(vm)
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
	end

	function table.FullCopy( tab )
		if (!tab) then return nil end
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then res[k] = table.FullCopy(v)
			elseif (type(v) == "Vector") then res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then res[k] = Angle(v.p, v.y, v.r)
			else res[k] = v end
		end
		return res
	end
end

--- MATILDA CUSTOM SETTINGS ---

SWEP.VElements = {
	["matildabird"] = { type = "Model", model = "models/svrkdstuff/matilda.mdl", bone = "ValveBiped.Grenade_body", rel = "", pos = Vector(1.896, 0.853, 1.496), angle = Angle(-133.818, 39.349, -6.362), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["element_name"] = { type = "Model", model = "models/svrkdstuff/matilda.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(4.14, -0.459, 2.298), angle = Angle(-177.109, 69.543, 36.81), size = Vector(0.852, 0.852, 0.852), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}


SWEP.PrintName = "milkshake or sum lik that"
SWEP.Instructions = "drop eggs \nSecondary Fire: Drop an egg bomb."
SWEP.Category = "anger birds"
SWEP.HoldType = "grenade"
SWEP.ViewModelFOV = 70
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0.328, -11.155, 0.411), angle = Angle(0.442, -1.318, 18.063) },
	["ValveBiped.Grenade_body"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.Spawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1
SWEP.DrawAmmo = false
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Matilda"
SWEP.Secondary.Automatic = false
SWEP.Weight = 50

-- Tracking variable
SWEP.LastBird = nil

function SWEP:PrimaryAttack()
    if self:Ammo1() < 1 then return end
    self:SetNextPrimaryFire(CurTime() + 1.2)
    self:TakePrimaryAmmo(1)

    if SERVER then
        local ply = self:GetOwner()
        ply:EmitSound("svrkdstuff/matilda_ready.wav")
        self:SendWeaponAnim(ACT_VM_PULLPIN)
        
        timer.Simple(0.1, function()
            if not IsValid(self) or not IsValid(ply) then return end
            self:SendWeaponAnim(ACT_VM_THROW)
            ply:SetAnimation(PLAYER_ATTACK1)
            ply:EmitSound("svrkdstuff/matilda_fly.mp3")

            local angrybird = ents.Create("prop_physics")
            if not IsValid(angrybird) then return end

            angrybird:SetPos(ply:EyePos() + (ply:GetAimVector() * 25))
            angrybird:SetModel("models/svrkdstuff/matilda.mdl")
            angrybird:SetAngles(ply:EyeAngles())
            angrybird:Spawn()

            local phys = angrybird:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(ply:GetAimVector() * 3500)
            end
            
            self.LastBird = angrybird
            angrybird.CanDropEgg = true

            MakeHeavyThrowable(angrybird, ply, 300, 2000)

            timer.Simple(10, function() if IsValid(angrybird) then angrybird:Remove() end end)
            timer.Simple(0.4, function() if IsValid(self) then self:SendWeaponAnim(ACT_VM_DRAW) end end)

            if self:Ammo1() <= 0 then
                ply:StripWeapon(self:GetClass())
            end
        end)
    end
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    
    local bird = self.LastBird
    if IsValid(bird) and bird.CanDropEgg then
        bird.CanDropEgg = false 
        
        -- Ability Sound
        self:EmitSound("svrkdstuff/egg_fly.mp3")
        
        local phys = bird:GetPhysicsObject()
        if IsValid(phys) then
            -- Boost Matilda Up
            phys:SetVelocity(Vector(0, 0, 650)) 
        end

        local egg = ents.Create("prop_physics")
        if IsValid(egg) then
            egg:SetModel("models/svrkdstuff/egg.mdl")
            egg:SetPos(bird:GetPos() - Vector(0, 0, 30))
            egg:Spawn()
            
            local ePhys = egg:GetPhysicsObject()
            if IsValid(ePhys) then ePhys:SetVelocity(Vector(0, 0, -1200)) end

            MakeHeavyThrowable(egg, self:GetOwner(), 180, 2000)
        end
    end
end

function SWEP:Reload()
	if self:Clip1() <= 0 then
		self:SendWeaponAnim(ACT_VM_DRAW)
		self:DefaultReload(ACT_VM_RELOAD)
	end
end