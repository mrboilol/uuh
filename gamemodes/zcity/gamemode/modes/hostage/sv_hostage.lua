local MODE = MODE

MODE.name = "hostage"
MODE.BuyTime = 40
MODE.StartMoney = 6500
MODE.start_time = 20
MODE.buymenu = true

MODE.ROUND_TIME = 240

MODE.Chance = 0.04

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

function MODE:CanLaunch()
    local points5 = zb.GetMapPoints( "HOSTAGE_DELIVERY_ZONE" )
    return #points5 > 0
end

MODE.ForBigMaps = true

util.AddNetworkString("hostage_start")
function MODE:Intermission()
	game.CleanUpMap()

	for i, ply in player.Iterator() do
		ply:SetupTeam(ply:Team())
		
		ply:SetNWInt( "TDM_Money", self.StartMoney )
	end

    timer.Simple(3,function()
        local ent = ents.Create("prop_ragdoll")
        local team_t = team.GetPlayers(0)
        local ply = team_t[math.random(#team_t)]
		--ent:SetModel("models/humans/group01/"..(math.random(2) == 1 and "fe" or "").."male_0"..math.random(9)..".mdl")
        ent:SetModel("models/player/hostage/hostage_0"..math.random(4)..".mdl")
        ent:SetPos(ply:GetPos())
        ent:Spawn()
        ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        hg.organism.Add(ent)
        hg.organism.Clear(ent.organism)
        ent.organism.fakePlayer = true

        zb.hostage = ent

        timer.Simple(1, function()
            hg.handcuff(ent)
        end)
    end)

	net.Start("hostage_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function HostageInZone(pos)
	local pts = zb.GetMapPoints("HOSTAGE_DELIVERY_ZONE")

	local vec1
	local vec2
	local vec3
	local vec4

	if #pts >= 2 then
		vec1 = -(-pts[1].pos)
		vec1[3] = vec1[3] - 256
		vec2 = -(-pts[2].pos)
		vec2[3] = vec2[3] + 256
	end

    if #pts >= 4 then
        vec3 = -(-pts[3].pos)
		vec3[3] = vec3[3] - 256
		vec4 = -(-pts[4].pos)
		vec4[3] = vec4[3] + 256
    end
    
	return (#pts >= 2 and pos:WithinAABox(vec1,vec2)) or (#pts >= 4 and pos:WithinAABox(vec3,vec4))
end

function MODE:ShouldRoundEnd()
    if zb.ROUND_START + 5 > CurTime() then return false end

	local tbl = zb:CheckAliveTeams(true)
    
    if not IsValid(zb.hostage) then
        return true
    end

    if #tbl[0] == 0 or #tbl[1] == 0 or not zb.hostage.organism.alive then
        return true
    end
    
    if zb.hostage.organism.alive and HostageInZone(zb.hostage:GetPos()) then
        return true
    end
end

function MODE:RoundStart()
	for k,ply in player.Iterator() do
		ply:Freeze(false)
	end
end

local tblweps = {
	[0] = {
		"weapon_akm",
	},
	[1] = {
		"weapon_m4a1",
	},
}

local tblatts = {
	[0] = {
		{""},
	},
	[1] = {
		{"holo14","laser2","grip3"},
	},
}

local tblarmors = {
	[0] = {
		{"vest4","helmet1"},
	},
	[1] = {
		{"vest4","helmet1"},
	},
}

-- local giveweapons = CreateConVar("zb_tdm_giveweapon","1",FCVAR_LUA_SERVER,"TDMSPAWNS",0,1)

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
	timer.Simple(0.1,function()
		local mrand = math.random(#tblweps[0])

		for _, ply in player.Iterator() do
			if not ply:Alive() then continue end
			
			local inv = ply:GetNetVar("Inventory")
			inv["Weapons"]["hg_sling"] = true
			ply:SetNetVar("Inventory",inv)

			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 1 then
				ply:SetPlayerClass("swat")
				zb.GiveRole(ply, "Counter Terrorist", Color(0,0,190))
				ply:SetNetVar("CurPluv", "pluvberet")
			else
				ply:SetPlayerClass("terrorist")
				zb.GiveRole(ply, "Terrorist", Color(190,0,0))
				ply:SetNetVar("CurPluv", "pluvboss")
			end

			--[[if giveweapons:GetBool() then
				local gun = ply:Give(tblweps[ply:Team()][mrand])
				ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
				
				hg.AddAttachmentForce(ply,gun,tblatts[ply:Team()][mrand])
				hg.AddArmor(ply, tblarmors[ply:Team()][mrand])


				ply:Give("weapon_hg_rgd_tpik")
				ply:Give("weapon_walkie_talkie")
				ply:Give("weapon_bandage_sh")
				ply:Give("weapon_tourniquet")
			end--]]

			//ply:Give("weapon_melee")

			ply:Give("weapon_melee")
			ply:Give("weapon_bandage_sh")
			ply:Give("weapon_tourniquet")
			ply.organism.allowholster = true

			local Radio = ply:Give("weapon_walkie_talkie")
			Radio.Frequency = (ply:Team() == 1 and math.Round(math.Rand(88,95),1)) or math.Round(math.Rand(100,108),1)
			local hands = ply:Give("weapon_hands_sh")
			ply:SelectWeapon("weapon_hands_sh")

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("hostage_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("hostage_roundend")
		net.Broadcast()
	end)

    local winner = 3

    if not IsValid(zb.hostage) then
        winner = 3
        
        if IsValid(zb.hostageLastTouched) then
            winner = zb.hostageLastTouched:Team() == 0 and 1 or 0
        end
    end
    
    if IsValid(zb.hostage) and not zb.hostage.organism.alive then
        local max, maxTeam = 0
        if zb.HarmDoneDetailed[zb.hostage:EntIndex()] then
            for steamid, tbl in pairs(zb.HarmDoneDetailed[zb.hostage:EntIndex()]) do
                if tbl.harm > max then
                    max = tbl.harm
                    maxTeam = tbl.teamAttacker
                end
            end
            
            winner = maxTeam == 0 and 1 or 0
            PrintMessage(HUD_PRINTTALK, (maxTeam == 0 and "Terrorists" or "Counter-Terrorists") .. " have killed the hostage")
        else
            winner = 3
        end
    end

    if IsValid(zb.hostage) and zb.hostage.organism.alive then
        winner = 0

        if #tbl[0] == 0 then
            winner = 1
        end
    end

    if IsValid(zb.hostage) and zb.hostage.organism.alive and HostageInZone(zb.hostage:GetPos()) then
        zb.hostage:Remove()
        winner = 1
    end

	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end
util.AddNetworkString( "hostage_open_buymenu" )
function MODE:ShowSpare1(ply ) -- OpenMenu
	if not ply:Alive() then return end
	net.Start( "hostage_open_buymenu" )
	net.Send( ply )
end

util.AddNetworkString( "hostage_buyitem" )

local AttachmentPrice = 50
net.Receive("hostage_buyitem",function(len,ply)
	if !CurrentRound().buymenu then return end
	if ((zb.ROUND_START or 0) + 40 < CurTime()) then ply:ChatPrint("Time's up!") return end
	local tItem = net.ReadTable()
	if not istable(tItem) then return end
	local category = tItem[1]
	local index = tItem[2]
	if not category or not index then return end
	local buyItems = CurrentRound().BuyItems
	if not buyItems or not buyItems[category] or not buyItems[category][index] then return end
	local item = buyItems[category][index]

	if not item then return end

	if tItem[3] then
		if not ply:HasWeapon(item.ItemClass) then ply:ChatPrint("You can't buy this attachment without a weapon.") return end
		if ((ply:GetNWInt("TDM_Money",0) - AttachmentPrice) < 0) then ply:ChatPrint("Not enough money.") return end

		local wep = ply:GetWeapon(item.ItemClass)
		hg.AddAttachmentForce( ply,wep,tItem[3] )
		ply:SetNWInt( "TDM_Money", ply:GetNWInt("TDM_Money",0) - AttachmentPrice )
		ply:EmitSound("items/itempickup.wav")

		return
	end

	if ((ply:GetNWInt("TDM_Money",0) - item.Price) < 0) then ply:ChatPrint("Not enough money.") return end
	local ent = ply:Give(item.ItemClass)
	
	if ent.Use and IsValid(ent) then
		ent:Use( ply )
	end

	if IsValid(ent) and ent:GetClass() == "weapon_bloodbag" then
		ent.bloodtype = "o-"
		ent.modeValues[1] = 1
	end

	if item.Amount then
		ent.AmmoCount = item.Amount
	end

	if ent.GetPrimaryAmmoType then
		ply:GiveAmmo(ent:GetMaxClip1() * 1,ent:GetPrimaryAmmoType(),true)
	end

	ply:SetNWInt( "TDM_Money", ply:GetNWInt("TDM_Money",0) - item.Price )
	ply:EmitSound("items/itempickup.wav")
end)