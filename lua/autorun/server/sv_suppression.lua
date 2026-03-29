util.AddNetworkString("RequestRagdoll")

net.Receive("RequestRagdoll", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    -- Ragdoll the player for a short duration
    if ply.GlideRagdoll then return end -- Don't ragdoll if already ragdolled
    local vel = ply:GetVelocity()
    Glide.RagdollPlayer(ply, vel, 2) -- Ragdoll for 2 seconds
end)
