if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Tranexamic Acid"
SWEP.Instructions = "Used to treat or prevent excessive blood loss."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/morphine_syrette/morphine.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_morphine")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_morphine.png"
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
	[1] = "tranexamic_acid"
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

local hg_healanims = ConVarExists("hg_font") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle heal/food animations", 0, 1)

function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 4, 0))
	end
end

function SWEP:Animation()
	local hold = self:GetHolding()
    self:BoneSet("r_upperarm", vector_origin, Angle(0, -hold + (100 * (hold / 100)), 0))
    self:BoneSet("r_forearm", vector_origin, Angle(-hold / 6, -hold * 2, -15))
end

sound.Add( {
	name = "pshiksnd",
	channel = CHAN_AUTO,
	volume = 0.02,
	level = 65,
	pitch = {5555, 5555},
	sound = "snd_jack_sss.wav",
} )

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:SpawnGarbage()
		self:NPCHeal(owner, 0.3, "snd_jack_hmcd_needleprick.wav")
	end
end

if SERVER then
	function SWEP:Heal(ent, mode)
		if ent:IsNPC() then
			self:SpawnGarbage()
			self:NPCHeal(ent, 0.3, "snd_jack_hmcd_needleprick.wav")
		end

		local org = ent.organism
		if not org then return end

		if self.modeValues[1] <= 0 then return end

		local owner = self:GetOwner()
		if ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
			self:SetHolding(math.Clamp(self:GetHolding() + 100, 0, 50))
		end

		local entOwner = IsValid(owner.FakeRagdoll) and owner.FakeRagdoll or owner

		local injected = math.min(FrameTime() * 0.5, self.modeValues[1])
		org.tranexamic_acid = math.min((org.tranexamic_acid or 0) + injected, 4)
		self.modeValues[1] = math.max(self.modeValues[1] - injected, 0)

		if self.modeValues[1] != 0 then
			entOwner:EmitSound("pshiksnd")
		else
			
		end
	end
end
