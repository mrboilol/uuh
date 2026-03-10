if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Antidepressant"
SWEP.Instructions = "Mmm tasty."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/props_junk/garbage_pillbottle001a.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/icons/ico_fent.png")
	SWEP.IconOverride = "vgui/icons/ico_fent.png"
	SWEP.BounceWeaponIcon = false
end
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1.5, 0)
SWEP.offsetAng = Angle(-30, 20, 180)

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)
end

if SERVER then
	function SWEP:PrimaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local org = owner.organism
		if not org then return end

		self:SetNextPrimaryFire(CurTime() + self.Primary.Wait)

		local mood = hg.Abnormalties.GetPlayerStat(owner, "mood")
		if mood then
			local new_mood = math.Clamp(mood + 40, 0, 100)
			hg.Abnormalties.SetPlayerStat(owner, "mood", new_mood)

			owner:Notify("Good for me...", 10, "antidepressant_effect", 0, nil, Color(200, 200, 255, 255))

			timer.Simple(120, function()
				if not IsValid(owner) then return end
				local current_mood = hg.Abnormalties.GetPlayerStat(owner, "mood")
				if current_mood then
					local mood_drop = 20 * hg.Abnormalties:GetMoodInertiaMultiplier(owner)
                    local mood_after_effect = math.Clamp(current_mood - mood_drop, 0, 100)
                    hg.Abnormalties.SetPlayerStat(owner, "mood", mood_after_effect)
					owner:Notify("The world seems a little colder now.", 10, "antidepressant_wore_off", 0, nil, Color(200, 200, 200, 255))
				end
			end)
		end

		self:Remove()
	end
end