local MODE = MODE

MODE.name = "ragdoll_pluviverse"
MODE.PrintName = "RAGDOLL PLUVIVERSE"
MODE.LootSpawn = true
MODE.noBoxes = true
MODE.OverideSpawnPos = true
MODE.ForBigMaps = false
MODE.base = "dm"
MODE.GuiltDisabled = true

util.AddNetworkString("ragdoll_pluviverse_start")
util.AddNetworkString("ragdoll_pluviverse_end")
local ragdollPluviverseSongs = {
    "RAGDOLL.wav",
    "CHARGE.wav",
    "UNIVERSE.wav"
}

local ragdollPluviverseKillLimit = 10
local ragdollPluviverseRespawnDelay = 2
local ragdollPluviverseSpawnClasses = {
    "info_player_start",
    "info_player_deathmatch",
    "info_player_combine",
    "info_player_rebel",
    "gmod_player_start",
    "info_player_terrorist",
    "info_player_counterterrorist"
}

local function GetRagdollPluviverseSpawnEnt()
    local spawns = {}
    for _, class in ipairs(ragdollPluviverseSpawnClasses) do
        table.Add(spawns, ents.FindByClass(class))
    end
    if #spawns == 0 then return end
    return spawns[math.random(#spawns)]
end

local function ApplyRagdollPluviverseSpawn(ply, spawnEnt)
    if not IsValid(ply) then return end
    ply:SetSuppressPickupNotices(true)
    ply.noSound = true
    ply:StripWeapons()
    ply:Give("weapon_hands_sh")
    local groundPos = Vector(0,0,0)
    if IsValid(spawnEnt) then
        groundPos = spawnEnt:GetPos()
    else
        groundPos = Vector(0,0,100)
    end
    local spawnPos = groundPos + Vector(0, 0, 2000)
    local trUp = util.TraceLine({
        start = groundPos + Vector(0,0,10),
        endpos = groundPos + Vector(0,0,2000),
        mask = MASK_SOLID_BRUSHONLY
    })
    if trUp.Hit then
        local ceilingPos = trUp.HitPos
        spawnPos = ceilingPos - Vector(0, 0, 50)
        local trCheck = util.TraceHull({
            start = spawnPos,
            endpos = spawnPos,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_SOLID
        })
        if trCheck.Hit then
            local midZ = (groundPos.z + ceilingPos.z) / 2
            spawnPos = Vector(groundPos.x, groundPos.y, midZ)
        end
    end
    ply:SetPos(spawnPos)
    ply:SetVelocity(Vector(0, 0, -100))
    ply.Karma = 100
    ply:SetNetVar("Karma", 100)
    ply.Guilt = 0
    timer.Simple(0.1, function() 
        if IsValid(ply) then 
            ply.noSound = false 
            if hg and hg.Fake then
                hg.Fake(ply)
                if ply.organism then ply.organism.godmode = true end
                timer.Simple(15, function()
                    if IsValid(ply) and ply.organism then ply.organism.godmode = false end
                end)
            end
        end
    end)
    ply:SetSuppressPickupNotices(false)
end

for _, song in ipairs(ragdollPluviverseSongs) do
    resource.AddFile("sound/" .. song)
end

function MODE:CanLaunch()
    return false
end

function MODE:EndRound()
    RunConsoleCommand("hg_thirdperson", "0")
    RunConsoleCommand("hg_ragdollcombat", "0")
    net.Start("ragdoll_pluviverse_end")
    net.Broadcast()
end

function MODE:Intermission()
    game.CleanUpMap()

    for k, ply in player.Iterator() do
        if ply:Team() == TEAM_SPECTATOR then continue end
        ply:SetupTeam(0)
        ply:SetFrags(0)
        ply:SetDeaths(0)
    end
    
    net.Start("ragdoll_pluviverse_start")
    net.WriteString(ragdollPluviverseSongs[math.random(#ragdollPluviverseSongs)])
    net.Broadcast()
end

function MODE:RoundStart()
    RunConsoleCommand("hg_thirdperson", "1")
    RunConsoleCommand("hg_ragdollcombat", "1")
    -- Initial loot spawn
    local spawns = zb.GetMapPoints("RandomSpawns")
    if spawns and #spawns > 0 then
        for i=1, 50 do
            local pt = table.Random(spawns)
            local entName, AmmoCount = hg.GenerateLoot()
            if entName then
                local item = ents.Create(entName)
                if IsValid(item) then
                    item:SetPos(pt.pos + Vector(0,0,10))
                    item:Spawn()
                    if AmmoCount then item.AmmoCount = AmmoCount end
                end
            end
        end
    end

    for _, ply in player.Iterator() do
        if not ply:Alive() then continue end
        ApplyRagdollPluviverseSpawn(ply, GetRagdollPluviverseSpawnEnt())
    end
end

hook.Add("Should Fake Up", "RagdollPluviverseNoGetUp", function(ply)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        return true
    end
end)

-- Disable fall damage for this mode
hook.Add("GetFallDamage", "RagdollPluviverseNoFallDamage", function(ply, speed)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        return 0
    end
end)

-- Immunity Logic
hook.Add("EntityTakeDamage", "RagdollPluviverseImmunity", function(target, dmginfo)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        if zb.ROUND_START and CurTime() < (zb.ROUND_START + 15) then
            if target:IsPlayer() or (target:IsRagdoll() and hg.RagdollOwner(target)) then
                return true -- Block damage
            end
        end
    end
end)

hook.Add("HomigradDamage", "RagdollPluviverseImmunity2", function(ply, dmgInfo)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        if zb.ROUND_START and CurTime() < (zb.ROUND_START + 15) then
            return true -- Block damage
        end
    end
end)

hook.Add("PlayerSpawn", "RagdollPluviverseKarmaReset", function(ply)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        ply.Karma = 100
        ply:SetNetVar("Karma", 100)
        ply.Guilt = 0
    end
end)

hook.Add("ZB_EndRound", "RagdollPluviverseEndRound", function()
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        RunConsoleCommand("hg_thirdperson", "0")
        RunConsoleCommand("hg_ragdollcombat", "0")
        net.Start("ragdoll_pluviverse_end")
        net.Broadcast()
    end
end)

util.AddNetworkString("ragdoll_pluviverse_kill")

local function ResolvePluviverseKiller(victim, attacker)
    local killer = attacker
    if IsValid(killer) and killer:IsRagdoll() then
        killer = hg.RagdollOwner(killer)
    end
    if IsValid(killer) and killer:IsPlayer() and killer ~= victim then
        return killer
    end
    local most_harm = 0
    local biggest_attacker
    for harmAttacker, harm in pairs(zb.HarmDone[victim] or {}) do
        if IsValid(harmAttacker) and harmAttacker ~= victim and harm > most_harm then
            most_harm = harm
            biggest_attacker = harmAttacker
        end
    end
    return biggest_attacker
end

hook.Add("PlayerDeath", "RagdollPluviverseKillNotify", function(victim, inflictor, attacker)
    if zb and zb.CROUND == "ragdoll_pluviverse" then
        local killer = ResolvePluviverseKiller(victim, attacker)
        if IsValid(killer) and killer:IsPlayer() and killer ~= victim then
            killer:AddFrags(1)
            local wepName = "Unknown"
            local wep = killer:GetActiveWeapon()
            if IsValid(wep) then
                wepName = wep.PrintName or wep:GetClass() or wepName
            elseif IsValid(inflictor) and inflictor:IsWeapon() then
                wepName = inflictor.PrintName or inflictor:GetClass() or wepName
            end
            net.Start("ragdoll_pluviverse_kill")
            net.WriteString(victim:Name())
            net.WriteString(wepName)
            net.Send(killer)
            timer.Simple(0, function()
                if not IsValid(killer) then return end
                if not zb or zb.CROUND ~= "ragdoll_pluviverse" or zb.ROUND_STATE ~= 1 then return end
                if killer:Frags() >= ragdollPluviverseKillLimit then
                    zb:EndRound()
                end
            end)
        end
        if IsValid(victim) and victim:IsPlayer() and victim:Team() ~= TEAM_SPECTATOR then
            timer.Simple(ragdollPluviverseRespawnDelay, function()
                if not IsValid(victim) then return end
                if not zb or zb.CROUND ~= "ragdoll_pluviverse" or zb.ROUND_STATE ~= 1 then return end
                for _, ply in player.Iterator() do
                    if ply:Frags() >= ragdollPluviverseKillLimit then
                        return
                    end
                end
                if victim:Alive() then return end
                victim:Spawn()
                ApplyRagdollPluviverseSpawn(victim, GetRagdollPluviverseSpawnEnt())
            end)
        end
    end
end)

function MODE:ShouldRoundEnd()
    for _, ply in player.Iterator() do
        if ply:Frags() >= ragdollPluviverseKillLimit then
            return true
        end
    end
    return false
end

-- Loot table definition
MODE.LootTable = {
    {100, { -- Weight group
        -- Weapons
        {4, "weapon_akm"},
        {4, "weapon_m4a1"},
        {3, "weapon_mp5"},
        {3, "weapon_remington870"},
        {3, "weapon_glock17"},
        {3, "weapon_deagle"},
        {3, "weapon_uzi"},
        {2, "weapon_spas12"},
        {2, "weapon_xm1014"},
        -- Grenades
        {3, "weapon_hg_rgd_tpik"},
        {3, "weapon_hg_pipebomb_tpik"},
        {3, "weapon_hg_smokenade_tpik"},
        {3, "weapon_hg_flashbang_tpik"},
        -- Medicine
        {4, "weapon_bandage_sh"},
        {3, "weapon_medkit_sh"},
        {2, "weapon_morphine"},
        {2, "weapon_adrenaline"},
        {2, "weapon_tourniquet"},
        {2, "weapon_fentanyl"}
    }}
}
