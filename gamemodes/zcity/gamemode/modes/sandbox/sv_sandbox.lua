local MODE = MODE

MODE.name = "sandbox"
MODE.PrintName = "Sandbox"
MODE.LootSpawn = true
MODE.GuiltDisabled = true
MODE.randomSpawns = true

function MODE:PlayerLoadout(ply)
    -- No items by default in sandbox
end

concommand.Add("set_role", function(ply, cmd, args)
    if zb.CROUND ~= "sandbox" then
        ply:ChatPrint("This command can only be used in Sandbox mode.")
        return
    end
    if not ply:IsAdmin() then
        ply:ChatPrint("You must be an admin to use this command.")
        return
    end

    local target_ply = ply
    local role_type = args[1]
    local role_name = args[2]

    if not role_type or not role_name then
        ply:ChatPrint("Usage: set_role <subrole|playerclass> <role_name>")
        return
    end

    if role_type == "subrole" then
        target_ply.SubRole = role_name
        ply:ChatPrint("Set " .. target_ply:Name() .. "'s subrole to " .. role_name)
    elseif role_type == "playerclass" then
        target_ply:SetPlayerClass(role_name)
        ply:ChatPrint("Set " .. target_ply:Name() .. "'s playerclass to " .. role_name)
    else
        ply:ChatPrint("Invalid role type. Use 'subrole' or 'playerclass'.")
    end
end)
