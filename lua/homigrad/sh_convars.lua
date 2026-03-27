-- This file contains shared convars for the homigrad addon.

if not use_homigrad_hud then
    use_homigrad_hud = CreateConVar("use_homigrad_hud", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Use the Homigrad HUD instead of the hjuyy HUD")
end

CreateConVar("homigrad_damage", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable old homigrad damage system")
CreateConVar("hg_arcademovement", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable arcade movement")

