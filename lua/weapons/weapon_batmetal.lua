if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Metal Bat"
SWEP.Instructions = "An Alluminum bat, Usually stored as trophies but this one is an upgrade to the usual bat. "
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_bat_metal.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.modelscale = 1

SWEP.Weight = 0

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_nmrih_bat")
	SWEP.IconOverride = "vgui/hud/tfa_nmrih_bat"
	SWEP.BounceWeaponIcon = false
end

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 26
SWEP.DamageSecondary = 13

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 2

SWEP.MaxPenLen = 2

SWEP.PenetrationSizePrimary = 4
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 25
SWEP.StaminaSecondary = 13

SWEP.HoldPos = Vector(-7,0,0)

SWEP.AttackTime = 0.5
SWEP.AnimTime1 = 1.75
SWEP.WaitTime1 = 1.25
SWEP.AttackLen1 = 68
SWEP.ViewPunch1 = Angle(2,4,0)

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-7,0,7)
SWEP.BlockHoldAng = Angle(18, 15, -20)
SWEP.BlockSound = "physics/wood/wood_plank_impact_hard2.wav"

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0)
SWEP.weaponAng = Angle(0,0,0)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.setlh = true
SWEP.setrh = true


SWEP.AttackHit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.Attack2Hit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)

SWEP.NoHolster = true


SWEP.Swing = true -- Это отвесает за первый вид удара, изначально с права на лево
SWEP.LSwing = false -- Это отвесает за второй вид удара, изначально с права на лево
SWEP.SwingLeft = false -- Это отвесает за первый вид удара, переключает с лева на право
SWEP.LSwingLeft = false -- Это отвесает за второй вид удара, переключает с лева на право
SWEP.UpSwing = false -- Это отвесает за первый вид удара, Сверху вниз
SWEP.LUpSwing = false -- Это отвесает за второй вид удара, Сверху вниз

SWEP.BreakBoneMul = 1.1
SWEP.PainMultiplier = 1.2

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.001

SWEP.AttackRads = 85
SWEP.AttackRads2 = 0

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.6

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(3.5, -14, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(205, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore