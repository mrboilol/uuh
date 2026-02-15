if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Tranexamic Acid"
SWEP.Instructions = "An antifibrinolytic agent used to treat or prevent excessive blood loss. Reduces internal bleeding and helps clear blood from the airway. RMB to inject into someone else."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/morphine_syrette/morphine.mdl" -- Placeholder model

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_morphine") -- Placeholder icon
	SWEP.IconOverride = "vgui/wep_jack_hmcd_morphine.png" -- Placeholder icon
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
	[1] = "antifibrinolytic"
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

sound.Add( {
	name = "pshiksnd_tranexamic",
	channel = CHAN_AUTO,
	volume = 0.02,
	level = 65,
	pitch = {5555, 5555},
	sound = "snd_jack_sss.wav",
} )

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:NPCHeal(owner, 0.3, "snd_jack_hmcd_needleprick.wav")
	end
end

if SERVER then
	function SWEP:Heal(ent, mode)
		if ent:IsNPC() then
			self:NPCHeal(ent, 0.3, "snd_jack_hmcd_needleprick.wav")
		end

		local org = ent.organism
		if not org then return end
		self:SetBodygroup(1, 1)
		local owner = self:GetOwner()
		local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner

		local injected = math.min(FrameTime() * 1, self.modeValues[1])
        
        -- Reduce internal bleeding and blood choke
        org.internalBleed = math.max(0, (org.internalBleed or 0) - (injected * 20))
        org.bloodChoke = math.max(0, (org.bloodChoke or 0) - (injected * 0.9))
        
        -- Small analgesic effect
		org.analgesiaAdd = math.min((org.analgesiaAdd or 0) + injected * 0.5, 1)

		self.modeValues[1] = math.max(self.modeValues[1] - injected, 0)

		if self.modeValues[1] != 0 then
			entOwner:EmitSound("pshiksnd_tranexamic")
		else
			-- self:Remove()
		end
	end
end
