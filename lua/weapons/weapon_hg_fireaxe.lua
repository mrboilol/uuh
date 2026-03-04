if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Fire Axe"
SWEP.Instructions = "An axe is an implement that has been used for millennia to shape, split, and cut wood. Can break down doors."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.SuicidePos = Vector(20, 1, -27)
SWEP.SuicideAng = Angle(-90, -180, 90)
SWEP.SuicideCutVec = Vector(3, -6, 0)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "weapons/knife/knife_hit1.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_axe_fire.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_nmrih/w_me_axe_fire.mdl"
SWEP.ViewModel = ""

SWEP.Weight = 0

SWEP.HoldType = "pistol"

SWEP.HoldPos = Vector(-9,0,0)
SWEP.HoldAng = Angle(0,0,-10)

SWEP.AttackTime = 0.5
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,1,-1)
SWEP.BleedMultiplier = 3

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(-0.2,-0.1,-0.2)
SWEP.weaponAng = Angle(0,-90,75)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 44
SWEP.DamageSecondary = 8

SWEP.PenetrationPrimary = 12
SWEP.PenetrationSecondary = 3.5

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.5

SWEP.StaminaPrimary = 39
SWEP.StaminaSecondary = 15

SWEP.AttackLen1 = 75
SWEP.AttackLen2 = 40

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-7,0,7)
SWEP.BlockHoldAng = Angle(18, 15, -20)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet1.wav"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/wep_jack_hmcded_axe")
	SWEP.IconOverride = "vgui/hud/wep_jack_hmcded_axe"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true


SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)

SWEP.NoHolster = true

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.BreakBoneMul = 1.7
SWEP.ImmobilizationMul = 2.7
SWEP.PainMultiplier = 3.5

SWEP.AttackRads = 75
SWEP.AttackRads2 = 0

SWEP.SwingAng = -10
SWEP.SwingAng2 = 0

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    return true
end

function SWEP:PrimaryAttackAdd(ent)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent,self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
end

SWEP.MinSensivity = 0.7

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeVPShouldUseHand = false
SWEP.FakeViewBobBaseBone = "base"
SWEP.ViewPunchDiv = 50

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(3.5, -14, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(205, 75, 230) -- Adjust rotation
SWEP.Concealed = true -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore
SWEP.Ignorebelt = true