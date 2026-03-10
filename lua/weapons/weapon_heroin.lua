if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Heroin"
SWEP.Instructions = "Heroin is a powerful opioid made from morphine, known for its intense euphoria and high risk of addiction. It’s illegal in most countries and can cause severe physical and mental damage. Use with caution — or better, don't use at all. Theres no label on it. RMB to inject into someone else."
SWEP.Category = "Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/morphine_syrette/morphine.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/heroin.png")
	SWEP.IconOverride = "vgui/heroin.png"
	SWEP.BounceWeaponIcon = false
end
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1.5, 0)
SWEP.offsetAng = Angle(-30, 20, 180)
SWEP.modeNames = {
	[1] = "analgesic"
}

SWEP.DeploySnd = ""
SWEP.HolsterSnd = ""

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)
	self.modeValues = {
		[1] = 1,
	}
end
SWEP.ofsV = Vector(0,8,-3)
SWEP.ofsA = Angle(-90,-90,90)
SWEP.modeValuesdef = {
	[1] = {1, true},
}

SWEP.showstats = true

function SWEP:Animation()
	local hold = self:GetHolding()
    self:BoneSet("r_upperarm", vector_origin, Angle(0, (-55*hold/65) + hold / 2, 0))
    self:BoneSet("r_forearm", vector_origin, Angle(-hold / 6, -hold / 0.8, (-20*hold/100)))
end

if SERVER then
	function SWEP:Heal(ent, mode)
		local org = ent.organism
		if not org then return end
		self:SetBodygroup(1, 1)
		local owner = self:GetOwner()
		local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner

		local injected = math.min(FrameTime() * 18, self.modeValues[1]) -- Faster injection rate
		org.analgesiaAdd = math.min(org.analgesiaAdd + injected, 10) -- Much higher analgesia cap
		self.modeValues[1] = math.max(self.modeValues[1] - FrameTime() * 1.2, 0) -- Slower consumption for longer effect

		owner.injectedinto = owner.injectedinto or {}
		owner.injectedinto[org.owner] = owner.injectedinto[org.owner] or 0
		owner.injectedinto[org.owner] = owner.injectedinto[org.owner] + injected

		if owner.injectedinto[org.owner] > 1 and injected > 0 then
			local dmgInfo = DamageInfo()
			dmgInfo:SetAttacker(owner)
			hook.Run("HomigradDamage", org.owner, dmgInfo, HITGROUP_RIGHTARM, hg.GetCurrentCharacter(org.owner), injected * 100)
		end

		if self.poisoned2 then
			org.poison4 = CurTime()

			self.poisoned2 = nil
		end

		if self.modeValues[1] != 0 then
			entOwner:EmitSound("pshiksnd")
		else
			//owner:SelectWeapon("weapon_hands_sh")
			//self:Remove()
		end

	local mood = org.mood
		if mood then
			local new_mood = mood
			if ent == owner then
				new_mood = new_mood + 10 -- Larger mood boost for self-healing
			else
				new_mood = new_mood + 15 -- Even bigger mood boost for helping others
			end
			new_mood = math.Clamp(new_mood, 0, 100)
			hg.Abnormalties.SetPlayerStat(owner, "mood", new_mood)

			timer.Simple(60, function()
				if not IsValid(ent) then return end
				local org = ent.organism
				if not org then return end
local mood = org.mood
				if not mood then return end
				local new_mood = math.Clamp(mood - 20, 0, 100) -- Mood crash
				hg.Abnormalties.SetPlayerStat(ent, "mood", new_mood)
			end)
		end
	end
end