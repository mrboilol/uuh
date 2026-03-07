-- This file contains shared convars for the homigrad addon.

if not use_homigrad_hud then
    use_homigrad_hud = CreateConVar("use_homigrad_hud", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Use the Homigrad HUD instead of the hjuyy HUD")
end
