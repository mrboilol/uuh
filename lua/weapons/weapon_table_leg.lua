if SERVER then
    AddCSLuaFile()
end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "tung tung tung sahur"
SWEP.Instructions = "There was a man named Tung Tung. He was always nice and kind and played with his friends, One day someone named -------- killed tung's parents. Tung tung was filled with anger, so he savagely ripped out a table leg out of his dining table and beat him up merciless until he was braindead. To this day we still dont know where tung tung remained, and the table leg remains as tung's favoured weapon. \n\nLMB to attack.\nRMB to block."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_hatchet.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_hatchet.mdl"
SWEP.WorldModelExchange = "models/gibs/furniture_gibs/furnituretable002a_chunk08.mdl"
SWEP.weaponPos = Vector(0, 1, 5)
SWEP.weaponAng = Angle(0, -90, 0)
SWEP.attack_ang = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)
SWEP.basebone = 94
SWEP.BreakBoneMul = .25
SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}
if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/icons/ico_table_leg.png")
    SWEP.IconOverride = "vgui/icons/ico_table_leg.png"
    SWEP.BounceWeaponIcon = false
end
SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false
SWEP.NoHolster = true
SWEP.HoldPos = Vector(-15, 0, 0)
SWEP.HoldAng = Angle(0,0,0)
SWEP.AttackPos = Vector(0, 0, 0)
SWEP.HoldType = "melee"
SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 35
SWEP.DamageSecondary = 15
SWEP.PenetrationPrimary = 1.1
SWEP.PenetrationSecondary = 0.9
SWEP.MaxPenLen = 4
SWEP.PainMultiplier = 2.5
SWEP.PenetrationSizePrimary = 1
SWEP.PenetrationSizeSecondary = 2
SWEP.StaminaPrimary = 25
SWEP.StaminaSecondary = 10
SWEP.AttackLen1 = 35
SWEP.AttackLen2 = 30
SWEP.AttackHit = "Wood.ImpactHard"
SWEP.Attack2Hit = "Wood.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "Wood.ImpactSoft"
SWEP.weight = 1

function SWEP:CanSecondaryAttack()
    return false
end

SWEP.AttackTimeLength = 0.25
SWEP.Attack2TimeLength = 0.15

SWEP.AttackRads = 65
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0