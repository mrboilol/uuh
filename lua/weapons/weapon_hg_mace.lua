if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Mace"
SWEP.Instructions = "A blunt medieval weapon built for crushing armor, the mace features a solid metal head mounted on a reinforced shaft. Designed to deliver high-impact strikes, it was favored by foot soldiers and knights for its reliability against plate and chainmail."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Weight = 0

SWEP.WorldModel = "models/wm/mace/w.mdl"
SWEP.WorldModelReal = "models/wm/mace/v.mdl"
SWEP.ViewModel = ""

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-33.5,5,0)

SWEP.AttackTime = 0.4
SWEP.AnimTime1 = 1.9
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.4
SWEP.AnimTime2 = 1.85
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,-15)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0)
SWEP.weaponAng = Angle(0,-90,0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 45
SWEP.DamageSecondary = 30
SWEP.BreakBoneMul = 2.5
SWEP.ImmobilizationMul = 1.5
SWEP.ShockMultiplier = 1.23

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 7

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 33
SWEP.StaminaSecondary = 18


SWEP.AttackLen1 = 60
SWEP.AttackLen2 = 45

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(3.5, -14, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(205, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore

SWEP.BlockHoldPos = Vector(-31, 7, -3)
SWEP.BlockHoldAng = Angle(15, 2, -65)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "slash3",
    ["attack2"] = "slash2",

}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wm_mace_i.png")
	SWEP.IconOverride = "vgui/wm_mace_i.png"
	SWEP.BounceWeaponIcon = false
end

if SERVER then 
    util.PrecacheSound("sledgehit/hit1.mp3")
    util.PrecacheSound("sledgehit/hit2.mp3")
    util.PrecacheSound("sledgehit/hit3.mp3")
end

SWEP.setlh = true
SWEP.setrh = true


SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)


SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(0, -10, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(195, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    return true
end


-- Overtake function - allows breaking blocks with superior condition
function SWEP:CheckOvertake(target)
    if not SERVER then return false end
    if not IsValid(target) or not target:IsPlayer() then return false end
    
    local attacker = self:GetOwner()
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    
    -- Check if target has a melee weapon and is blocking
    local targetWeapon = target:GetActiveWeapon()
    if not IsValid(targetWeapon) or not targetWeapon.ismelee then return false end
    
    local isBlocking = false
    if targetWeapon.GetIsBlocking then
        isBlocking = targetWeapon:GetIsBlocking()
    elseif targetWeapon.GetBlocking then
        isBlocking = targetWeapon:GetBlocking()
    end
    
    if not isBlocking then return false end
    
    -- Check if both players have organism data
    if not attacker.organism or not target.organism then return false end
    
    -- Calculate condition scores (stamina + adrenaline*10)
    local attackerStamina = attacker.organism.stamina and attacker.organism.stamina[1] or 0
    local attackerAdrenaline = attacker.organism.adrenaline or 0
    local attackerCondition = attackerStamina + (attackerAdrenaline * 10)
    
    local defenderStamina = target.organism.stamina and target.organism.stamina[1] or 0
    local defenderAdrenaline = target.organism.adrenaline or 0
    local defenderCondition = defenderStamina + (defenderAdrenaline * 10)
    
    -- Need at least 20 point advantage to attempt overtake
    local conditionDiff = attackerCondition - defenderCondition
    if conditionDiff < 20 then return false end
    
    -- Calculate overtake chance (15-25% base, increased by condition difference)
    local baseChance = math.random(15, 25)
    local bonusChance = math.min(conditionDiff * 0.3, 20) -- Max 20% bonus
    local totalChance = baseChance + bonusChance
    
    -- Roll for overtake success
    if math.random(1, 100) > totalChance then return false end
    
    -- Overtake successful! Break the block
    if targetWeapon.EndBlock then
        targetWeapon:EndBlock()
    end
    if targetWeapon.SetBlockCooldown then
        targetWeapon:SetBlockCooldown(CurTime() + 4.0) -- Longer cooldown than normal
    end
    
    -- Heavy stamina penalty for failed block
    local staminaPenalty = math.random(25, 40)
    target.organism.stamina.subadd = target.organism.stamina.subadd + staminaPenalty
    
    -- Brief stun effect
    if target.organism then
        target.organism.stun = CurTime() + 1.5
    end
    
    -- 30-40% chance to drop weapon on overtake
    if math.random(1, 100) <= math.random(30, 40) then
        timer.Simple(0.1, function()
            if IsValid(target) and IsValid(targetWeapon) then
                hg.drop(target)
            end
        end)
        
        -- Add knockback when weapon is dropped
        local knockbackForce = (target:GetPos() - attacker:GetPos()):GetNormalized() * 200
        target:SetVelocity(knockbackForce + Vector(0, 0, 50))
    end
    
    -- Play overtake sound effect
    attacker:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 70, math.random(90, 110))
    target:EmitSound("physics/body/body_medium_break" .. math.random(2, 4) .. ".wav", 65, math.random(95, 105))
    
    -- Small adrenaline boost for successful overtake
    if attacker.organism then
        attacker.organism.adrenalineAdd = math.min(attacker.organism.adrenalineAdd + 0.2, 4)
    end
    
    return true
end

function SWEP:PrimaryAttackAdd(ent)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent,self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
    if ent:IsPlayer() then
        self:CheckOvertake(ent)
    end
    if SERVER and IsValid(ent) and self:IsEntSoft(ent) then
        self:GetOwner():EmitSound("sledgehit/hit" .. math.random(1,3) .. ".mp3", 50, math.random(95, 115))
    end
end

SWEP.NoHolster = true

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 95
SWEP.AttackRads2 = 0

SWEP.SwingAng = -165
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.87
