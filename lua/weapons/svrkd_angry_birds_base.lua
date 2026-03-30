SWEP.Base = "homigrad_base"

if SERVER then
    function MakeHeavyThrowable(ent, owner, damage, force)
        if not IsValid(ent) or not IsValid(owner) then return end

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200) -- Increased Mass
            phys:AddAngleVelocity(VectorRand() * 400)
        end

        ent:SetPhysicsAttacker(owner, damage)

        ent:AddCallback("PhysicsCollide", function(collidedEnt, data)
            if not IsValid(collidedEnt) then return end

            local hitEnt = data.HitEntity
            if not IsValid(hitEnt) or hitEnt == owner or hitEnt:IsWeapon() then return end

            local damageInfo = DamageInfo()
            damageInfo:SetAttacker(owner)
            damageInfo:SetInflictor(collidedEnt)
            damageInfo:SetDamage(damage)
            damageInfo:SetDamageType(DMG_CLUB)
            damageInfo:SetDamageForce(owner:GetAimVector() * force)
            damageInfo:SetDamagePosition(data.HitPos)

            hitEnt:TakeDamageInfo(damageInfo)

            collidedEnt:EmitSound("Flesh.ImpactHard")

            -- Make the bird break apart on heavy impact
            if data.Speed > 400 then
                collidedEnt:EmitSound("physics/concrete/concrete_break2.wav")
                local poof = EffectData()
                poof:SetOrigin(data.HitPos)
                poof:SetScale(2)
                poof:SetNormal(-data.HitNormal)
                util.Effect("eff_jack_hmcd_poof", poof, true, true)
                collidedEnt:Remove()
            end
        end)
    end
end

function SWEP:CustomHolster(dev, wep, speed)
    if wep:GetClass() == "weapon_physgun" or wep:GetClass() == "gmod_tool" or wep:GetClass() == "weapon_physcannon" then return end
    speed.walk = speed.walk / 2
    speed.run = speed.run / 2
end