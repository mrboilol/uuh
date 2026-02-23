--thanks nig
if SERVER then 
    CreateConVar("hg_death_effect_enabled", "1", FCVAR_REPLICATED, "enable or disable wave effect thing")
    return 
end



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

local deadSound

hook.Add("Post Post Processing", "TunnelwaveDeadOrSuicide", function()
    local death_effect_enabled = GetConVar("hg_death_effect_enabled")
    if not death_effect_enabled or not death_effect_enabled:GetBool() then return end

    local lply = LocalPlayer()
    if not IsValid(lply) then return end

    local isEffectActive = false
    if not lply:Alive() then
        -- The player is dead, so the effect should be active for them.
        isEffectActive = true
    else
        -- The player is alive, use the original logic to check for nearby dead bodies.
        local deadOwner = getDeadBodyOwner(lply)
        if deadOwner then
            if isDeadBodyAllowed(lply, deadOwner) then
                deadBodyHoldUntil = CurTime() + deadBodyHoldSeconds
            else
                deadBodyHoldUntil = 0
            end
        end
        isEffectActive = deadBodyHoldUntil > CurTime()
    end

	tunnelWaveFade = LerpFT(0.08, tunnelWaveFade, isEffectActive and 1 or 0)
	if tunnelWaveFade < 0.01 then
        if deadSound and deadSound:IsPlaying() then
            deadSound:Stop()
        end
        return
    end
	render.UpdateScreenEffectTexture()
	tunnelWaveMat:SetFloat("$c1_w", tunnelWaveBase * tunnelWaveFade)
	render.SetMaterial(tunnelWaveMat)
	render.DrawScreenQuad()

    if not deadSound then
        deadSound = CreateSound(lply, "ambient/creatures/town_moan1.wav") -- Using one sound for consistency
    end

    if isEffectActive then
        if not deadSound:IsPlaying() then
            deadSound:PlayEx(1, 100) -- Play at full volume initially
        end
    end

    if deadSound:IsPlaying() then
        deadSound:ChangeVolume(tunnelWaveFade, 0.1) -- Fade volume with the visual effect
    end

    if not isEffectActive and deadSound:IsPlaying() then
        deadSound:Stop()
    end
end)
