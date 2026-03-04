if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Jagdkommando Tri-Dagger"
SWEP.Instructions = "The Jagdkommando Tri-Dagger is a small, three-edged combat knife made for close-quarters stealth. Matte finish, textured grip and slim Kydex sheath — stabs deal heavy damage, slashes cause brief bleeding. Ideal for silent takedowns and fast melee fights."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/w_tridagger_dooktr.mdl"
SWEP.WorldModelReal = "models/weapons/gleb/c_knife_t.mdl"
SWEP.WorldModelExchange = "models/weapons/w_tridagger_dooktr.mdl"
SWEP.modelscale = 0.8
SWEP.modelscale2 = 1

SWEP.BleedMultiplier = 1.4
SWEP.PainMultiplier = 2.5

SWEP.DamagePrimary = 30
SWEP.DamageSecondary = 12

SWEP.AttackTime = 0.32
SWEP.AnimTime1 = 1.2
SWEP.WaitTime1 = 0.66
SWEP.AttackLen1 = 65

SWEP.Attack2Time = 0.25
SWEP.AnimTime2 = 0.95
SWEP.WaitTime2 = 0.45
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.setlh = true
SWEP.setrh = true

SWEP.basebone =76

SWEP.weaponPos = Vector(3.7,0,0)
SWEP.weaponAng = Angle(-100,0,0)

SWEP.HoldType = "knife"

SWEP.InstantPainMul = 0.4

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_ins2_tridagger")
	SWEP.IconOverride = "vgui/hud/tfa_ins2_tridagger"
	SWEP.BounceWeaponIcon = false
end

SWEP.BreakBoneMul = 0.6
SWEP.ImmobilizationMul = 0.8
SWEP.HadBackBonus = true

SWEP.HoldPos = Vector(-4.3,0,-4.1)
SWEP.HoldAng = Angle(-15,0,0)

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-4.3,0,-4)
SWEP.BlockHoldAng = Angle(-45,0,0)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

-- Animation list for actual weapon animations
SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab_miss",
    ["attack2"] = "midslash1",
}

function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetAttackLength(60)
    self:SetAttackWait(0)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
        self:DoSecondaryAttack() -- fix: use DoSecondaryAttack for slash, not SecondaryAttack which blocks
        self.allowsec = nil
        return false
    end
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 35
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true