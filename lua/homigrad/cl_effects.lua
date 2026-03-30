if not CLIENT then return end

util.AddNetworkString("hg_skull_destroyed_effect")

net.Receive("hg_skull_destroyed_effect", function()
    local pos = net.ReadVector()
    local dir = net.ReadVector()
    local ply = net.ReadEntity()

    if not IsValid(ply) then return end

    -- Blood effect
    local emitter = ParticleEmitter(pos)
    for i = 1, 100 do
        local particle = emitter:Add("effects/blood_core", pos)
        if particle then
            particle:SetVelocity(dir * math.Rand(50, 200) + VectorRand() * 50)
            particle:SetDieTime(math.Rand(0.5, 1.5))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(1, 3))
            particle:SetEndSize(0)
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-5, 5))
            particle:SetColor(150, 0, 0)
        end
    end
    emitter:Finish()

     org.owner:EmitSound("owfuck"..math.random(1,4)..".ogg", 100, 100)
     org.owner:EmitSound("flesh"..math.random(1,10)..".wav", 100, 100)
end)