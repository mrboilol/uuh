--local Organism = hg.organism
hg.organism.module = hg.organism.module or {}
local module = hg.organism.module
hook.Add("Org Clear", "Main", function(org)
	org.alive = true
	org.otrub = false
	org.dying = false -- Reset dying state on organism clear
	
	-- Force reset client-side states (Death Screen & Consciousness Timer)
	-- This handles cases where player dies/respawns and previous states get stuck
	if IsValid(org.owner) and org.owner:IsPlayer() then
		net.Start("HG_DeathState")
		net.WriteBool(false)
		net.WriteFloat(0)
		net.Send(org.owner)

		net.Start("HG_ConsciousnessTimer")
		net.WriteBool(false)
		net.WriteFloat(100)
		net.Send(org.owner)
	end

	module.pulse[1](org)
	module.blood[1](org)
	module.pain[1](org)
	module.stamina[1](org)
	module.lungs[1](org)
	module.liver[1](org)
	module.metabolism[1](org)
	module.random_events[1](org)
	-- teeth init
	if module.teeth and module.teeth[1] then module.teeth[1](org) end
	-- emotion init
	if module.emotion and module.emotion[1] then module.emotion[1](org) end
	-- spasms init
	if module.spasms and module.spasms[1] then module.spasms[1](org) end
	org.brain = 0
	org.consciousness = 1
	org.disorientation = 0
	org.paralyzed = false
	org.was_in_agony = false -- Track if player was in agony state
	org.jaw = 0
	org.spine1 = 0
	org.spine2 = 0
	org.spine3 = 0
	org.chest = 0
	org.pelvis = 0
	org.skull = 0
	org.stomach = 0
	org.intestines = 0

	-- eyes
	org.eyeL = 0
	org.eyeR = 0

	org.lleg = 0
	org.rleg = 0
	org.larm = 0
	org.rarm = 0
	org.llegdislocation = false
	org.rlegdislocation = false
	org.rarmdislocation = false
	org.larmdislocation = false
	org.jawdislocation = false

	org.health = 100
	org.canmove = true
	org.recoilmul = 1
	org.meleespeed = 1
	org.temperature = 36.7
	org.superfighter = false
	org.CantCheckPulse = nil
	org.HEV = nil
	org.bleedingmul = 1
	org.berserk = 0
	org.adrenaline = 0
	org.adrenalineAdd = 0
	org.caffeine = 0
	org.cardiac_risk = 0

	--\\ info for rp addition
	org.last_heartbeat = CurTime()
	org.bulletwounds = 0
	org.stabwounds = 0
	org.slashwounds = 0
	org.bruises = 0
	org.burns = 0
	org.explosionwounds = 0

	org.fear = 0
	org.fearadd = 0
	
	-- New emotion system
	org.happiness = 0
	org.happinessadd = 0
	org.sorrow = 0
	org.sorrowadd = 0
	org.anger = 0
	org.angeradd = 0
	org.despair = 0
	org.despairadd = 0
	org.hope = 0
	org.hopeadd = 0
	org.rage = 0
	org.rageadd = 0
	org.calm = 0
	org.calmadd = 0
	org.anxiety = 0
	org.anxietyadd = 0
	org.relief = 0
	org.reliefadd = 0
	org.guilt = 0
	org.guiltadd = 0
	
	-- Food tracking for happiness
	org.last_satiety = 0
	org.last_food_time = 0
	
	-- Additional emotion tracking
	org.previous_fear = 0
	org.last_pain_time = 0
	
	-- Enhanced emotion duration tracking
	org.anger_start_time = 0
	org.fear_start_time = 0
	org.high_pain_start_time = 0
	org.low_blood_start_time = 0
	org.hunger_start_time = 0
	org.last_wound_count = 0
	--//

	if IsValid(org.owner) then
		if org.owner:IsPlayer() and org.owner:Alive() then
			org.owner:SetHealth(100)
			org.owner:SetNetVar("wounds",{})
			org.owner:SetNetVar("arterialwounds",{})
		end
		
		org.owner:SetNetVar("zableval_masku", false)
	end
end)

hook.Add("Should Fake Up", "organism", function(ply)
    local org = ply.organism
    if org.otrub or org.fake or org.spine1 >= hg.organism.fake_spine1 or org.spine2 >= hg.organism.fake_spine2 or org.spine3 >= hg.organism.fake_spine3 or (org.lleg == 1 or org.rleg == 1) or (org.blood < 2900) then return false end
end)

util.AddNetworkString("organism_send")
util.AddNetworkString("organism_sendply")
util.AddNetworkString("hg_play_client_sound")
util.AddNetworkString("hg_play_client_sound_file")
util.AddNetworkString("hg_dislocation_minigame_pain")
util.AddNetworkString("hg_dislocation_minigame_success")
util.AddNetworkString("HG_ConsciousnessTimer")
util.AddNetworkString("HG_DeathState")
local CurTime = CurTime
local nullTbl = {}
local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer",0,FCVAR_SERVER_CAN_EXECUTE,"enable developer mode (enables damage traces)",0,1)
local function send_organism(org, ply)
	if not IsValid(org.owner) then return end
	local sendtable = {}

	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.stamina = org.stamina
	sendtable.immobilization = org.immobilization
	sendtable.adrenaline = org.adrenaline
	sendtable.adrenalineAdd = org.adrenalineAdd
	sendtable.analgesia = org.analgesia
	sendtable.lleg = org.lleg
	sendtable.rleg = org.rleg
	sendtable.rarm = org.rarm
	sendtable.larm = org.larm
	sendtable.pelvis = org.pelvis
	sendtable.disorientation = org.disorientation
	sendtable.brain = org.brain
	sendtable.eyeL = org.eyeL
	sendtable.eyeR = org.eyeR
	sendtable.o2 = org.o2
	sendtable.blood = org.blood
	sendtable.bloodtype = org.bloodtype
	sendtable.bleed = org.bleed
	sendtable.hurt = org.hurt
	sendtable.pain = org.pain
	sendtable.shock = org.shock
	sendtable.pulse = org.pulse
	sendtable.timeValue = org.timeValue
	sendtable.holdingbreath = org.holdingbreath
	sendtable.arteria = org.arteria
	sendtable.recoilmul = org.recoilmul
	sendtable.meleespeed = org.meleespeed
	sendtable.temperature = org.temperature
	sendtable.canmove = org.canmove
	sendtable.fear = org.fear
	sendtable.caffeine = org.caffeine
	sendtable.cardiac_risk = org.cardiac_risk
	
	-- New emotions for network sync
	sendtable.happiness = org.happiness
	sendtable.sorrow = org.sorrow
	sendtable.anger = org.anger
	sendtable.despair = org.despair
	sendtable.hope = org.hope
	sendtable.rage = org.rage
	sendtable.calm = org.calm
	sendtable.anxiety = org.anxiety
	sendtable.relief = org.relief
	sendtable.guilt = org.guilt
	
	sendtable.llegdislocation = org.llegdislocation
	sendtable.rlegdislocation = org.rlegdislocation
	sendtable.rarmdislocation = org.rarmdislocation
	sendtable.larmdislocation = org.larmdislocation
	sendtable.jawdislocation = org.jawdislocation
	sendtable.lungsfunction = org.lungsfunction
	sendtable.consciousness = org.consciousness
	
	sendtable.critical = org.critical
	sendtable.incapacitated = org.incapacitated
	
	sendtable.superfighter = org.superfighter
	sendtable.berserk = org.berserk
	
	-- Emotional state sync
	sendtable.emotionalIntensity = org.emotionalIntensity or 0
	sendtable.grayscaleIntensity = org.grayscaleIntensity or 0
	sendtable.blurIntensity = org.blurIntensity or 0
	sendtable.blinkRateIncrease = org.blinkRateIncrease or 0
	sendtable.isCrying = org.isCrying or false
	sendtable.ambientSadPlaying = org.ambientSadPlaying or false
	
	net.Start("organism_send")
	net.WriteTable(not hg_developer:GetBool() and sendtable or org)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(false)
	net.WriteBool(true)
	net.WriteBool(false)
	if IsValid(ply) and ply:IsPlayer() then
		net.Send(ply)
	else
		net.Broadcast()
	end
	if org.owner == ply or not IsValid(ply) or not ply:IsPlayer() then
		org.owner.fullsend = nil
	end
end

local function send_bareinfo(org)
	if not IsValid(org.owner) then return end
	local sendtable = {}

	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.bloodtype = org.bloodtype
	sendtable.pulse = org.pulse
	sendtable.o2 = org.o2
	sendtable.timeValue = org.timeValue
	sendtable.superfighter = org.superfighter
	sendtable.berserk = org.berserk
	sendtable.lungsfunction = org.lungsfunction

	local rf = RecipientFilter()
	--rf:AddAllPlayers()
	rf:AddPVS(org.owner:GetPos())
	if org.owner:IsPlayer() then rf:RemovePlayer(org.owner) end

	net.Start("organism_send")
	net.WriteTable(not hg_developer:GetBool() and sendtable or org)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.Send(rf)
end

hg.send_organism = send_organism
hg.send_bareinfo = send_bareinfo

hook.Add("Org Think", "Main", function(owner, org, timeValue)
	if not IsValid(owner) then
		hg.organism.list[owner] = nil
		return
	end

	if owner:IsPlayer() and not owner:Alive() then return end

	local isPly = owner:IsPlayer()

	org.isPly = isPly

	if isPly or org.fakePlayer then
		if not org.fakePlayer then
			org.alive = owner:Alive()
		end
	else
		org.alive = false
	end

	org.needotrub = false
	org.needfake = false
	if isPly then
		org.ownerFake = org.FakeRagdoll and true
	else
		org.ownerFake = false
	end
	
	org.timeValue = timeValue
	org.incapacitated = false
	org.critical = false

	if isPly then
		module.stamina[2](owner, org, timeValue)
	end
	
	if isPly or org.fakePlayer then
		module.lungs[2](owner, org, timeValue)
	end

	if isPly then
		module.liver[2](owner, org, timeValue)
	end

	--module.blood[3](owner,org,timeValue)--arteria
	module.blood[2](owner, org, timeValue)
	if isPly then
		module.pain[2](owner, org, timeValue)
		-- teeth periodic pain
		if module.teeth and module.teeth[2] then module.teeth[2](owner, org, timeValue) end
		
		-- Track agony state transitions for disorientation
		local current_agony = org.pain > 60 and not org.otrub
		local just_recovered_from_agony = org.was_in_agony and not current_agony
		if just_recovered_from_agony then
			-- Add disorientation when recovering from agony state - NERFED for balance
			org.disorientation = org.disorientation + math.Rand(1.0, 1.5)
		end
		org.was_in_agony = current_agony
		
		module.metabolism[2](owner, org, timeValue)
		module.random_events[2](owner, org, timeValue)
		
		-- emotion module processing
		if module.emotion and module.emotion[2] then module.emotion[2](owner, org, timeValue) end
	end
	module.pulse[2](owner, org, timeValue)

	-- eye loss: apply ongoing bleeding; pain remains additive on hits
	if org.eyeL and org.eyeL >= 1 then
		org.bleed = org.bleed + (timeValue * 0.6)
	end
	if org.eyeR and org.eyeR >= 1 then
		org.bleed = org.bleed + (timeValue * 0.6)
	end

	if org.otrub then
		org.uncon_timer = org.uncon_timer or 0
		-- Timer increment disabled
		-- org.uncon_timer = org.uncon_timer + timeValue
	else
		org.uncon_timer = 0
	end

    local just_went_uncon = not org.otrub and org.needotrub
    -- Removed timer requirement for waking up
    local just_woke_up = not org.needotrub and org.otrub
    if isPly and just_went_uncon then
        hook.Run("HG_OnOtrub", owner)
        hook.Run("PlayerDropWeapon", owner)
        org.otrub_black_delay_until = CurTime() + 1.0
        org.otrub_black_started = false
        
        net.Start("hg_play_client_sound")
        net.WriteString("harmSting.ogg")
        net.Send(owner)
    end
	if isPly and just_woke_up then 
		hook.Run("HG_OnWakeOtrub", owner)
		-- Add disorientation when waking up from full unconsciousness
		org.disorientation = org.disorientation + math.Rand(1.5, 2.0)
	end
	
	org.canmove = (org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3) and not org.otrub
	org.canmovehead = (org.spine3 < hg.organism.fake_spine3) and not org.otrub
	
    if not (org.canmove and org.canmovehead and (org.stun - CurTime()) < 0) then org.needfake = true end
    if (org.blood < 2700) then org.needfake = true end
    if (org.lleg == 1 or org.rleg == 1) then org.needfake = true end

	local just_went_uncon = not org.otrub and org.needotrub
	
    if org.otrub and isPly and org.owner:Alive() then
        if not org.otrub_black_delay_until then
            org.otrub_black_delay_until = CurTime() + 1.0
        end
        if CurTime() >= org.otrub_black_delay_until then
            if not org.otrub_black_started then
                org.owner:ScreenFade(SCREENFADE.OUT, color_black, 0.5, 99999)
                org.otrub_black_started = true
            end
        end
        org.owner:ConCommand("soundfade 100 99999")
    end

    if not org.otrub and isPly and org.owner:Alive() then
        org.owner:ScreenFade(SCREENFADE.PURGE, color_black, 0, 0)
        org.owner:ConCommand("soundfade 0 1")
        org.otrub_black_delay_until = nil
        org.otrub_black_started = nil
    end

	if just_went_uncon then
		org.owner.fullsend = true
	end

	if org.brain > 0.05 then
		if math.random(600) < org.brain * 20 then
			org.needfake = true
		end
	end

	if org.alive then
		-- org.postureType logic removed
	else
		org.postureType = org.postureType
	end

	org.otrub = org.needotrub
	org.fake = org.needfake

	-- Update berserk state based on adrenaline
	if org.adrenaline and org.adrenaline > 2.5 then
		-- Player is in berserk state, increase berserk value (can go above 1 for multipliers)
		org.berserk = org.berserk + timeValue * 2.0
	else
		-- Player is not in berserk state, decrease berserk value
		org.berserk = math.max(org.berserk - timeValue * 1.5, 0)
	end

	if owner:IsPlayer() and (org.healthRegen or 0) < CurTime() then
		org.healthRegen = CurTime() + 30
		owner:SetHealth(math.min(owner:GetMaxHealth(), owner:Health() + math.max(1.5 - org.hurt, 0)))
	end

	org.health = owner:Health()
	local rag = owner:IsPlayer() and owner.FakeRagdoll or owner
	if IsValid(rag) and rag:IsRagdoll() and (not owner.lastFake or owner.lastFake == 0) then rag:SetCollisionGroup((rag:GetVelocity():LengthSqr() > (200*200)) and COLLISION_GROUP_NONE or COLLISION_GROUP_WEAPON) end
	if isPly then
		-- Only auto-reset if not already in a valid fake ragdoll state and not in crash sequence
		local inCrashSequence = owner.crashSequence and owner.crashSequence > CurTime()
		if (org.otrub or org.fake) and not (IsValid(owner.FakeRagdoll) and owner.FakeRagdoll:IsRagdoll()) and not inCrashSequence then 
			hg.Fake(owner,nil,true) 
		end
		-- Delayed death system / Dying State System
		-- Only kill if biologically dead (Brain dead or empty of blood)
		local shouldBeDying = owner:Alive() and ((org.brain and org.brain >= 1) or (org.blood and org.blood <= 0))
		
		-- FORCE IMMEDIATE DEATH - No Death State
		if shouldBeDying then
			if IsValid(owner) and owner:Alive() then
				owner:Kill()
			end
		end
		
		-- Removed Dying State and Consciousness Timer UI logic
	end

	if not org.otrub and isPly then
		local mul = hg.likely_to_phrase(owner)
		
		if not org.likely_phrase then org.likely_phrase = 0 end

		org.likely_phrase = math.max(org.likely_phrase + math.Rand(0, mul) / 100, 0)
		//print(org.likely_phrase)
		if org.likely_phrase >= 1 and !hg.GetCurrentCharacter(owner):IsOnFire() then
			org.likely_phrase = 0

			local str = hg.get_status_message(owner)
			//print(str)
			-- (msg, delay, msgKey, showTime, func, clr)
			owner:Notify(str, 1, "phrase", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), 255))
		end
	end

	if !org.alive then org.otrub = true end

	if !org.alive then
		org.lungsfunction = false
		org.heartstop = true
	end

	time = CurTime()
	if org.pulseStart < time then
		org.pulseStart = time + 60 / org.pulse
		//hg.organism.Pulse(owner, org, timeValue)
	end

	if IsValid(owner) then
		org.sendPlyTime = org.sendPlyTime or CurTime()
		if (org.sendPlyTime > time) and !just_went_uncon then return end
		org.sendPlyTime = CurTime() + 1 + (not isPly and 2 or 0)
		send_bareinfo(org)

		if isPly and owner:Alive() then
			send_organism(org, owner)
		end
	end
end)

concommand.Add("hg_organism_setvalue", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	
	if not args[3] then
		if isbool(ply.organism[args[1]]) then
			ply.organism[args[1]] = tonumber(args[2]) != 0
		else
			ply.organism[args[1]] = tonumber(args[2])
		end
	end

	if args[3] then
		for i,pl in pairs(player.GetListByName(args[3])) do
			if isbool(pl.organism[args[1]]) then
				pl.organism[args[1]] = tonumber(args[2]) != 0
			else
				pl.organism[args[1]] = tonumber(args[2])
			end
		end
	end
end)

concommand.Add("hg_organism_setvalue2", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	
	ply.organism[args[1]][tonumber(args[2])] = tonumber(args[3])
end)

concommand.Add("hg_organism_clear", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not args[1] then
		hg.organism.Clear(ply.organism)
	end

	if args[1] then
		for i,pl in pairs(player.GetListByName(args[1])) do
			hg.organism.Clear(pl.organism)
		end
	end
end)

hook.Add("SetupMove", "hg-speed", function(ply, mv) end) --mv:SetMaxClientSpeed(100) --mv:SetMaxSpeed(100)

hook.Add("StartCommand","hg_lol",function(ply,cmd)
	if ply.organism.otrub and ply:Alive() then
		cmd:ClearMovement()
	end
end)

hook.Add("PlayerDeath","next-respawn-full",function(ply)
	ply.fullsend = true
	ply:ScreenFade(SCREENFADE.PURGE, Color(0,0,0,255), 0, 0)
	ply:ConCommand("soundfade 0 1")

	if ply.organism then
		ply.organism.otrub_black_started = nil
		ply.organism.otrub_black_delay_until = nil
	end
end)

hook.Add("HG_OnWakeOtrub", "afterOtrub", function( owner ) 
	owner.organism.after_otrub = true
	local str = hg.get_status_message(owner)
	owner.organism.after_otrub = nil
	//print(str)
	-- (msg, delay, msgKey, showTime, func, clr)
	timer.Simple(0.1,function()
		if not IsValid(owner) then return end
		owner:Notify(str, 1, "wake", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255)) )
	end)

	owner:SendLua("system.FlashWindow()")
end)

hook.Add("HG_OnOtrub", "fearful", function( plya )// ЧЕ
	local ent = hg.GetCurrentCharacter(plya)
	for i,ply in ipairs(ents.FindInSphere(ent:GetPos(),256)) do
		if not ply:IsPlayer() or not ply.organism or plya == ply then continue end
		
		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ent:GetPos()
		tr.filter = {ply,ent}
		if not util.TraceLine(tr).Hit then
			ply.organism.adrenalineAdd = ply.organism.adrenalineAdd + 0.3
			ply.organism.fearadd = ply.organism.fearadd + 0.3
		end
	end
end)

local function healSpine(org, spinePart)
    if org[spinePart] and org[spinePart] > 0 then
        org[spinePart] = 0;
        
        if hg.organism.restoreSpineConstraints and org.owner then
            local rag = org.owner:GetNWEntity("RagdollDeath");
            if not IsValid(rag) then rag = org.owner:GetNWEntity("FakeRagdoll") end
            if not IsValid(rag) and IsValid(org.owner.FakeRagdoll) then rag = org.owner.FakeRagdoll end
            if not IsValid(rag) then rag = org.owner end

            if IsValid(rag) and rag:IsRagdoll() then
                hg.organism.restoreSpineConstraints(rag);
            end
        end
    end
end

local function fixlimb(org, key)
	if math.random(100) > (90 - (org.analgesia * 50 + org.painkiller * 15)) then
		org[key.."dislocation"] = false
		org.painadd = org.painadd + 5
		org.fearadd = org.fearadd + 0.1
		
		-- Restore visual floppy effect for fixed dislocation
		if hg.RestoreLimbConstraints and org.owner then
			local rag = org.owner:GetNWEntity("RagdollDeath")
			if IsValid(rag) then
				hg.RestoreLimbConstraints(rag, key)
			end
		end
	else
		org.painadd = org.painadd + 20
		org.fearadd = org.fearadd + 0.3
	end
end

concommand.Add("hg_fixdislocation", function(ply, cmd, args)
	local org = ply.organism
	if !ply:Alive() or !org or org.otrub then return end
	if (ply.tried_fixing_limb or 0) > CurTime() then return end
	if !org.canmove or org.canmovehead == false or org.pain > 45 then return end
	
	-- Validate arguments
	if !args[1] then return end
	local limbType = tonumber(args[1])
	if !limbType then return end
	
	ply.tried_fixing_limb = CurTime() + org.pain / 30

	if math.Round(limbType) == 1 then
		if org.llegdislocation then
			fixlimb(org, "lleg")
		elseif org.rlegdislocation then
			fixlimb(org, "rleg")
		end
	elseif math.Round(limbType) == 2 then
		if org.larmdislocation then
			fixlimb(org, "larm")
		elseif org.rarmdislocation then
			fixlimb(org, "rarm")
		end
	elseif math.Round(limbType) == 3 then
		if org.jawdislocation then
			fixlimb(org, "jaw")
		end
	end
end)

-- Help fix dislocation on another player
concommand.Add("hg_help_fixdislocation", function(ply, cmd, args)
	local helperOrg = ply.organism
	if !ply:Alive() or !helperOrg or helperOrg.otrub then return end
	if (ply.tried_fixing_limb or 0) > CurTime() then return end
	if !helperOrg.canmove or helperOrg.canmovehead == false or helperOrg.pain > 45 then return end
	
	-- Validate arguments
	if !args[1] or !args[2] then return end
	
	-- Get target player by UserID
	local targetUserID = tonumber(args[1])
	local dislocationType = tonumber(args[2])
	if !targetUserID or !dislocationType then return end
	
	local targetPly = nil
	for _, p in pairs(player.GetAll()) do
		if p:UserID() == targetUserID then
			targetPly = p
			break
		end
	end
	
	if !IsValid(targetPly) or !targetPly:Alive() or !targetPly.organism then return end
	
	-- Check if target is ragdolled
	local ragdoll = targetPly.FakeRagdoll
	if !IsValid(ragdoll) then return end
	
	-- Distance check between helper and target ragdoll
	local helperPos = ply:GetPos()
	local ragdollPos = ragdoll:GetPos()
	if helperPos:Distance(ragdollPos) > 100 then return end
	
	local targetOrg = targetPly.organism
	
	-- Set cooldown for helper
	ply.tried_fixing_limb = CurTime() + helperOrg.pain / 30 + 1 -- Slightly longer cooldown when helping others
	
	-- Apply the fixing attempt to target player
	if dislocationType == 1 then
		if targetOrg.llegdislocation then
			fixlimb(targetOrg, "lleg")
		elseif targetOrg.rlegdislocation then
			fixlimb(targetOrg, "rleg")
		end
	elseif dislocationType == 2 then
		if targetOrg.larmdislocation then
			fixlimb(targetOrg, "larm")
		elseif targetOrg.rarmdislocation then
			fixlimb(targetOrg, "rarm")
		end
	elseif dislocationType == 3 then
		if targetOrg.jawdislocation then
			fixlimb(targetOrg, "jaw")
		end
	end
	
	-- Notify both players
	local bodyPart = dislocationType == 1 and "leg" or (dislocationType == 2 and "arm" or "jaw")
	ply:Notify("You attempt to help fix " .. targetPly:Name() .. "'s dislocated " .. bodyPart, 3, "help_fix", 2)
	targetPly:Notify(ply:Name() .. " is attempting to fix your dislocated " .. bodyPart, 3, "being_helped", 2)
end)

net.Receive("hg_dislocation_minigame_pain", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if this is for another player
    local target = net.ReadEntity()
    if IsValid(target) and target:IsPlayer() and target != ply then
        -- Apply pain to target (maybe less fear since they aren't doing it?)
        -- Or apply to both? Let's apply to target as they are the one being hurt
        local org = target.organism
        if not org then return end
        
        org.painadd = org.painadd + 5
        org.fearadd = org.fearadd + 0.1
        target:EmitSound("physics/body/body_medium_impact_hard1.wav", 60, 100, 1, CHAN_AUTO)
        return
    end

    local org = ply.organism
    if not org then return end
    
    org.painadd = org.painadd + 5
    org.fearadd = org.fearadd + 0.1
    ply:EmitSound("physics/body/body_medium_impact_hard1.wav", 60, 100, 1, CHAN_AUTO)
end)

net.Receive("hg_dislocation_minigame_success", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    local target = net.ReadEntity()
    local patient = ply
    
    -- If fixing someone else
    if IsValid(target) and target:IsPlayer() and target != ply then
        patient = target
        -- Verify distance
        if ply:GetPos():Distance(patient:GetPos()) > 200 then return end
    end

    local org = patient.organism
    if not org then return end
    
    local limbType = net.ReadInt(4)
    local failures = net.ReadInt(16)
    
    local key
    if limbType == 1 then
        if org.llegdislocation then key = "lleg"
        elseif org.rlegdislocation then key = "rleg" end
    elseif limbType == 2 then
        if org.larmdislocation then key = "larm"
        elseif org.rarmdislocation then key = "rarm" end
    elseif limbType == 3 then
        if org.jawdislocation then key = "jaw" end
    end
    
    if key then
        org[key.."dislocation"] = false
        
        -- Base pain for fixing
        org.painadd = org.painadd + 5
        org.fearadd = org.fearadd + 0.1
        
        -- Extra pain from failures
        if failures > 0 then
            org.painadd = org.painadd + (failures * 2)
        end
        
        -- Restore visual floppy effect
        if hg.RestoreLimbConstraints then
            local rag = patient:GetNWEntity("RagdollDeath")
            if not IsValid(rag) then rag = patient:GetNWEntity("FakeRagdoll") end
            
            if IsValid(rag) then
                hg.RestoreLimbConstraints(rag, key)
            end
        end
        
        patient:EmitSound("physics/body/body_medium_impact_soft1.wav", 60, 100, 1, CHAN_AUTO)
        
        if patient == ply then
            ply:Notify("You fixed your dislocation.", 3, "fix", 2)
        else
            ply:Notify("You fixed " .. patient:Name() .. "'s dislocation.", 3, "fix", 2)
            patient:Notify(ply:Name() .. " fixed your dislocation.", 3, "fix", 2)
        end
    end
end)
