if SERVER then AddCSLuaFile() include("svrkd_angry_birds_base.lua") end

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

function SWEP:Initialize()
	
	self:SetHoldType("grenade")
	
	// other initialize code goes here

	if CLIENT then
	
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
		
	end

end

function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
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
			
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
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
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
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
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
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
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
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
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r // Fixes mirrostella models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		// Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				// !! ----------- !! //
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	/**************************
		Global utility code
	**************************/

	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
end









SWEP.VElements = {
	["redbird"] = { type = "Model", model = "models/svrkdstuff/stella.mdl", bone = "ValveBiped.Grenade_body", rel = "", pos = Vector(2.408, -0.21, -1.119), angle = Angle(-133.818, 39.349, -6.362), size = Vector(0.524, 0.524, 0.524), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["element_name"] = { type = "Model", model = "models/svrkdstuff/stella.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.558, -0.02, 0.067), angle = Angle(-22.639, -78.784, -104.997), size = Vector(0.651, 0.651, 0.651), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

game.AddAmmoType({
    name = "stella",
    dmgtype = DMG_CRUSH,
    tracer = TRACER_LINE,
    plydmg = 0,
    npcdmg = 0,
    force = 2000,
    minsplash = 10,
    maxsplash = 20
})

SWEP.PrintName = "stella montis"
SWEP.Instructions = "seriously i forgot who this guy is \nSecondary Fire: Spawn balloons on nearby objects."
SWEP.Category = "anger birds"

SWEP.HoldType = "grenade"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, -10.086, 3.517), angle = Angle(-1.445, 4.561, 11.015) },
	["ValveBiped.Grenade_body"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 3
SWEP.DrawAmmo = false
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "stella"

SWEP.Secondary.Ammo = "none"

SWEP.Weight = 50
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.CurrentAngryBird = nil

local STELLA_BALLOON_COLORS = {
    { r = 80,  g = 200, b = 255 }, -- blue
    { r = 80,  g = 255, b = 120 }, -- green
    { r = 255, g = 100, b = 200 }, -- pink
}

local function AttachBalloon( target )
    local colorData = STELLA_BALLOON_COLORS[ math.random( 1, #STELLA_BALLOON_COLORS ) ]
    local balloon = ents.Create( "prop_physics" )
    if not IsValid( balloon ) then return end

    local targetPos = target:GetPos()
    balloon:SetPos( targetPos )
    balloon:SetModel( "models/hunter/misc/shell2x2.mdl" )

    local bModel = "models/balloon_speech.mdl"
    if file.Exists( bModel, "GAME" ) then
        balloon:SetModel( bModel )
    end

    balloon:Spawn()
    balloon:Activate()
    balloon:SetMaterial( "sprops/textures/gear_metal" )
    balloon:SetColor( Color( colorData.r, colorData.g, colorData.b, 200 ) )
    balloon:SetRenderMode( RENDERMODE_TRANSALPHA )

    -- SetParent makes balloon follow the target WITHOUT freezing physics
    balloon:SetParent( target )

    local bphys = balloon:GetPhysicsObject()
    if IsValid( bphys ) then
        bphys:SetMass( 1 )
        bphys:EnableGravity( false )
        bphys:Wake()
    end

    local liftName = "StellaLift_" .. balloon:EntIndex()
    local liftForce = 1500

    timer.Create( liftName, 0.02, 0, function()
        if not IsValid( balloon ) then
            timer.Remove( liftName )
            return
        end
        if not IsValid( target ) then
            timer.Remove( liftName )
            if IsValid( balloon ) then balloon:Remove() end
            return
        end

        local phys = target:GetPhysicsObject()
        if IsValid( phys ) then
            phys:ApplyForceCenter( Vector( 0, 0, liftForce ) )
            phys:Wake()
        end

        if target:IsPlayer() then
            target:SetVelocity( Vector( 0, 0, 20 ) )
        end
    end)

    timer.Simple( 3, function()
        timer.Remove( liftName )
        if IsValid( balloon ) then
            local eff = EffectData()
            eff:SetOrigin( balloon:GetPos() )
            eff:SetScale( 0.5 )
            util.Effect( "balloon_pop_small", eff )
            balloon:EmitSound( "balloon_pop_cute01.wav" )
            balloon:SetParent( nil )
            balloon:Remove()
        end
    end)
end

local function SpawnBalloons( origin, ply, hitEnt )
    local targets = {}

    -- Always directly include the hit entity if valid
    if IsValid( hitEnt ) and hitEnt ~= ply and not hitEnt:IsWorld() then
        local class = hitEnt:GetClass()
        if class == "prop_physics" or class == "prop_ragdoll" or hitEnt:IsPlayer() or hitEnt:IsNPC() then
            table.insert( targets, hitEnt )
        end
    end

    -- Also find everything within 300 units of the hit entity
    local searchOrigin = IsValid( hitEnt ) and hitEnt:GetPos() or origin
    for _, ent in ipairs( ents.FindInSphere( searchOrigin, 300 ) ) do
        if not IsValid( ent ) then continue end
        if ent == ply then continue end
        if ent == hitEnt then continue end -- already added
        if ent:IsWorld() then continue end
        if IsValid( ply ) and ent == ply:GetActiveWeapon() then continue end

        local class = ent:GetClass()
        if class == "prop_physics" or class == "prop_ragdoll" or ent:IsPlayer() or ent:IsNPC() then
            table.insert( targets, ent )
        end
    end

    for _, target in ipairs( targets ) do
        AttachBalloon( target )
    end
end

function SWEP:SecondaryAttack()
    if not SERVER then return end
    self:SetNextSecondaryFire( CurTime() + 3 )
    local ply = self:GetOwner()
    if not IsValid( ply ) then return end

    self:EmitSound( "svrkdstuff/stella_right.mp3" )

    if not IsValid(self.CurrentAngryBird) then return end

    SpawnBalloons( self.CurrentAngryBird:GetPos(), ply, tr.Entity )
end

function SWEP:PrimaryAttack()
    if self:Ammo1() < 1 then return end

    self:SetNextPrimaryFire( CurTime() + 2 )
    self:TakePrimaryAmmo( 1 )

    if SERVER then
        self:SendWeaponAnim( ACT_VM_PULLPIN )

        timer.Simple(0, function()
            local ply = self:GetOwner()
            if not IsValid(ply) then return end

            self:SendWeaponAnim( ACT_VM_THROW )
            ply:SetAnimation( PLAYER_ATTACK1 )
            self:EmitSound( "svrkdstuff/stella_fly.mp3" )

            timer.Simple(0.2, function()
                local angrybird = ents.Create("prop_physics")
                if not IsValid(angrybird) then return end

		self.CurrentAngryBird = angrybird

                angrybird:SetPos( ply:EyePos() + ply:GetAimVector() * 128 )
                angrybird:SetModel( "models/svrkdstuff/stella.mdl" )
                angrybird:SetAngles( ply:EyeAngles() )
                angrybird:Spawn()

                local phys = angrybird:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity( ply:GetAimVector() * 3500 )
                end

                MakeHeavyThrowable(angrybird, ply, 300, 2000)

                timer.Simple(10, function()
                    if IsValid(angrybird) then angrybird:Remove() end
                end)
            end)

            timer.Simple(0.35, function()
                if IsValid(self) then self:SendWeaponAnim(ACT_VM_DRAW) end
            end)

            if self:Ammo1() <= 0 then
                ply:StripWeapon( self:GetClass() )
            end
        end)
    end
end

function SWEP:SecondaryAttack()
    if not SERVER then return end
    self:SetNextSecondaryFire( CurTime() + 3 )
    local ply = self:GetOwner()
    if not IsValid( ply ) then return end

    self:EmitSound( "svrkdstuff/stella_right.mp3" )

    if not IsValid(self.CurrentAngryBird) then return end

    SpawnBalloons( self.CurrentAngryBird:GetPos(), ply, self.CurrentAngryBird )
end

function SWEP:Equip()
    if SERVER then
        self:DefaultReload(ACT_VM_RELOAD)
    end
end

function SWEP:Reload()
	if self:Clip1() <= 0 then
		self:SendWeaponAnim(ACT_VM_DRAW)
		self:DefaultReload( ACT_VM_RELOAD)
	end
end