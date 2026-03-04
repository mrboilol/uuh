if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Zweihander"
SWEP.Instructions = "A two-handed German greatsword inspired by the massive blades used by Landsknecht mercenaries in the 16th century."
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

SWEP.WorldModel = "models/weapons/tfa_kf2/w_zweihander.mdl"
SWEP.WorldModelReal = "models/wm/mace/v.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_kf2/w_zweihander.mdl"
SWEP.ViewModel = ""

SWEP.NoHolster = true

SWEP.HoldType = "slam"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-28.5,5,0)

SWEP.AttackTime = 0.7
SWEP.AnimTime1 = 2.8
SWEP.WaitTime1 = 2
SWEP.ViewPunch1 = Angle(3,5,0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 2.5
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)



SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 39

SWEP.weaponPos = Vector(0,0,-2)
SWEP.weaponAng = Angle(0,0,-80)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 55

SWEP.BleedMultiplier = 3
SWEP.PainMultiplier = 2

SWEP.PenetrationPrimary = 7

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 1.5

SWEP.StaminaPrimary = 40

SWEP.AttackLen1 = 75

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-31, 7, -10)
SWEP.BlockHoldAng = Angle(-3, 2, -55)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "slash3",
    ["attack2"] = "slash2",

}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/zweihander.png")
	SWEP.IconOverride = "vgui/zweihander.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true


SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "weapons/knife/knife_hit1.wav"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "snd_jack_hmcd_knifehit.wav"
    self.AttackHitFlesh = "sword/bladeslash"..math.random(4)..".ogg"
    return true
end

SWEP.AttackTimeLength = 0.15

SWEP.AttackRads = 75
SWEP.AttackRads2 = 90

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = true
SWEP.MultiDmg2 = false


SWEP.LastAxeHitSoundTime = 0
SWEP.AxeHitSoundCooldown = 0.5 

function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and IsValid(ent) and self:IsEntSoft(ent) then
        local owner = self:GetOwner()
        if IsValid(owner) then
            local currentTime = CurTime()
            if currentTime - self.LastAxeHitSoundTime >= self.AxeHitSoundCooldown then
                owner:EmitSound("snd_jack_hmcd_axehit.wav", 50, math.random(95, 105))
                self.LastAxeHitSoundTime = currentTime
            end
        end
    end
end

SWEP.MinSensivity = 0.25

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(3.5, -14, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(205, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore