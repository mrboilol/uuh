if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Fubar"
SWEP.Instructions = "A Heavy, Industrial fubar. Unless you are an construction worker i dont know how you will put use to this."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_fubar.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_fubar.mdl"
SWEP.ViewModel = ""

SWEP.NoHolster = true


SWEP.HoldType = "camera"

SWEP.HoldPos = Vector(-11,0,0)

SWEP.AttackTime = 0.69
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,2,-15)
SWEP.weaponAng = Angle(180,90,0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 45
SWEP.DamageSecondary = 25

SWEP.PenetrationPrimary = 6
SWEP.PenetrationSecondary = 7.5

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 4
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 30
SWEP.StaminaSecondary = 1

SWEP.AttackLen1 = 60
SWEP.AttackLen2 = 45

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-16,-5,2)
SWEP.BlockHoldAng = Angle(0, 0, 21)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet2.wav"

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_nmrih_fubar")
	SWEP.IconOverride = "vgui/hud/tfa_nmrih_fubar"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(0, -10, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(195, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore


SWEP.AttackHit = "SolidMetal.ImpactHard"
SWEP.Attack2Hit = "SolidMetal.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "SolidMetal.ImpactSoft"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_CLUB
    return true
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 120
SWEP.AttackRads2 = 0

SWEP.SwingAng = -5
SWEP.SwingAng2 = 0