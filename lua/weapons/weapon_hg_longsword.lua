if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Longsword"
SWEP.Instructions = "Ледовое поебище"
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

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_sledge.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_sledge.mdl"
SWEP.WorldModelExchange = "models/poulait/props/epee20.mdl"
SWEP.ViewModel = ""

SWEP.NoHolster = true

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-7.5,0,-2.5)

SWEP.AttackTime = 0.25
SWEP.AnimTime1 = 1.1
SWEP.WaitTime1 = 0.9
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(-2,2,7)
SWEP.weaponAng = Angle(180,0,0)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 37

SWEP.BleedMultiplier = 3
SWEP.PainMultiplier = 1.9

SWEP.PenetrationPrimary = 8

SWEP.MaxPenLen = 7

SWEP.PenetrationSizePrimary = 1.7

SWEP.StaminaPrimary = 40

SWEP.AttackLen1 = 55

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-8, 1, -10)
SWEP.BlockHoldAng = Angle(-15, 2, -55)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_viz_hmcd_katana.png")
	SWEP.IconOverride = "vgui/wep_viz_hmcd_katana.png"
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
    self.AttackHitFlesh = "katana/katanahit"..math.random(3)..".wav"
    return true
end

SWEP.AttackTimeLength = 0.15

SWEP.AttackRads = 65

SWEP.SwingAng = -15

SWEP.MultiDmg1 = true


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