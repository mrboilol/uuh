--thanks nig
if SERVER then 
    CreateConVar("hg_death_effect_enabled", "1", FCVAR_REPLICATED, "enable or disable wave effect thing")
    return 
end

local DeadBodySounds = {
    "ambient/creatures/town_moan1.wav",
    "ambient/creatures/town_muffled_cry1.wav",
    "ambient/creatures/town_scared_breathing1.wav",
    "ambient/creatures/town_scared_breathing2.wav",
    "ambient/creatures/town_scared_sob1.wav",
    "ambient/creatures/town_scared_sob2.wav",
}

local deadBodySoundPlaying = false

local tunnelWaveMat = Material("effects/shaders/zb_tunnelwave")
local tunnelWaveFade = 0
local tunnelWaveBase = 0.9
local deadBodyHoldUntil = 0
local deadBodyHoldSeconds = 1.2

local function getDeadBodyOwner(ply)
	if not IsValid(ply) then return nil end
	local tr = hg.eyeTrace(ply, 160)
	if not tr or not IsValid(tr.Entity) then return nil end
	local ent = tr.Entity
	if ent:IsPlayer() then
		return not ent:Alive() and ent or nil
	end
	if ent:IsRagdoll() then
		local owner = hg.RagdollOwner(ent) or ent:GetNWEntity("ply") or ent.ply
		if IsValid(owner) and owner:IsPlayer() then
			return not owner:Alive() and owner or nil
		end
		return ent
	end
	return nil
end

local function isDeadBodyAllowed(ply, owner)
	return true
end

hook.Add("Post Post Processing", "TunnelwaveDeadOrSuicide", function()
    if not GetConVar("hg_death_effect_enabled"):GetBool() then return end

    local lply = LocalPlayer()
    if not IsValid(lply) or not lply:Alive() then return end
	local deadOwner = getDeadBodyOwner(lply)

    if deadOwner then
        if isDeadBodyAllowed(lply, deadOwner) then
            deadBodyHoldUntil = CurTime() + deadBodyHoldSeconds
        else
            deadBodyHoldUntil = 0
        end
    end

	local deadActive = deadBodyHoldUntil > CurTime()
	tunnelWaveFade = LerpFT(0.08, tunnelWaveFade, deadActive and 1 or 0)
	if tunnelWaveFade < 0.01 then return end
	render.UpdateScreenEffectTexture()
	tunnelWaveMat:SetFloat("$c1_w", tunnelWaveBase * tunnelWaveFade)
	render.SetMaterial(tunnelWaveMat)
	render.DrawScreenQuad()

    if deadActive and not deadBodySoundPlaying then
        deadBodySoundPlaying = true
        surface.PlaySound(table.Random(DeadBodySounds))
        timer.Simple(math.Rand(5, 10), function()
            deadBodySoundPlaying = false
        end)
    end
end)

local DeadBodySounds = {
    "ambient/creatures/town_moan1.wav",
    "ambient/creatures/town_muffled_cry1.wav",
    "ambient/creatures/town_scared_breathing1.wav",
    "ambient/creatures/town_scared_breathing2.wav",
    "ambient/creatures/town_scared_sob1.wav",
    "ambient/creatures/town_scared_sob2.wav",
}

local deadBodySoundPlaying = false
