if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Tourniquet"
SWEP.Instructions = "An esmarch tourniquet designed to stop large (arterial) bleedings. Can also be used to stop light bleedings, although it makes the limb ineffective."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/tourniquet/tourniquet.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("scrappers/jgut.png")
	SWEP.IconOverride = "scrappers/jgut.png"
	SWEP.BounceWeaponIcon = false

	SWEP.WepSelectIcon2 = Material("scrappers/jgut.png")

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
--
--
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.SetMaterial( self.WepSelectIcon2 )
	
		surface.DrawTexturedRect( x, y + 10,  wide, wide/2 )
	
		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	
	end
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1.5, 0)
SWEP.offsetAng = Angle(-30, 20, -90)
SWEP.ModelScale = 1
SWEP.modeNames = {
	[1] = "tourniquet"
}

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)

	self.modeValues = {
		[1] = 1,
	}
end

SWEP.showstats = false

SWEP.modeValuesdef = {
	[1] = 1,
}


local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	local aimvec = self:GetOwner():GetAimVector()
	local hold = self:GetHolding()
	if (owner.zmanipstart ~= nil and not owner.organism.larmamputated) then return end
	self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 4, -30 + hold / 2 + 20 * aimvec[3], 5 - hold / 3.5))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 10, -hold / 2.5, 35 -hold/1.5))
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:NPCHeal(owner, 0.25, "snd_jack_hmcd_bandage.wav")
	end
end

function SWEP:Heal(ent, mode, bone)
    local org = ent.organism
    if not org then return false end

    if self:Tourniquet(ent, bone) then
        self.modeValues[1] = 0
        self:GetOwner():SelectWeapon("weapon_hands_sh")
        self:Remove()
        return true
    end

    return false
end


function SWEP:Tourniquet(ent, bone)
	local org = ent.organism
	if not org then return false end

	local boneName = ent:GetBoneName(bone)
	-- Find the limb associated with the bone
	local limb
	for l, b in pairs(hg.amputatedlimbs) do
		if b == boneName then
			limb = l
			break
		end
	end

	if not limb then
		for l, b in pairs(hg.amputatedlimbs2) do
			if b == boneName then
				limb = l
				break
			end
		end
	end

	if limb and limb ~= "head" and limb ~= "chest" then
		local applied = false
		for i, wound in ipairs(org.arterialwounds) do
			local wound_bone_name = ent:GetBoneName(ent:LookupBone(wound[4]))
			local wound_limb
			for l, b in pairs(hg.amputatedlimbs) do
				if b == wound_bone_name then
					wound_limb = l
					break
				end
			end

			if not wound_limb then
				for l, b in pairs(hg.amputatedlimbs2) do
					if b == wound_bone_name then
						wound_limb = l
						break
					end
				end
			end

			if wound_limb and string.find(wound_limb, limb) then
				org[limb .. "tourniquet"] = CurTime() + 120 -- Apply for 120 seconds
				applied = true
			end
		end

		if applied then
			org.painadd = (org.painadd or 0) + 20
			ent:EmitSound("physics/flesh/flesh_impact_hard6.wav", 65)
			return true
		end
	end

	return false
end


function SWEP:PrimaryAttack()
    if GetConVar("use_homigrad_hud"):GetBool() then
        if CLIENT then
            RunConsoleCommand("homigrad_show_hud")
        end
        return
    end

	if SERVER then
		local trace = hg.eyeTrace(self:GetOwner())
		self.healbuddy = self:GetOwner()
		local done = self:Heal(self.healbuddy, self.mode, trace.PhysicsBone)
		
		if(done and self.PostHeal)then
			self:PostHeal(self.healbuddy, self.mode)
		end

		if self.net_cooldown2 < CurTime() then
			self:SetNetVar("modeValues",self.modeValues)
			--self.net_cooldown2 = CurTime() + 0.1
		end
	end
end

