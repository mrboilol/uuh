util.AddNetworkString("homigrad_use_item")

local adjacent_limbs = {
    LeftArm = { "LeftHand", "LeftShoulder" },
    RightArm = { "RightHand", "RightShoulder" },
    LeftLeg = { "LeftFoot" },
    RightLeg = { "RightFoot" },
}

net.Receive("homigrad_use_item", function(len, ply)
    local item_class = net.ReadString()
    local limb = net.ReadString()
    local target_ply = net.ReadEntity()

    if not IsValid(target_ply) or not target_ply:IsPlayer() then return end

    local wep = target_ply:GetWeapon(item_class)
    if not IsValid(wep) then return end

    if wep.ScrappersSlot == "Drug" then
        -- Apply general effect for drugs
        target_ply:SetHealth(math.min(target_ply:Health() + 10, 100))
        wep:Remove()
    else
        -- Apply localized effect for other medical items
        local limb_data = target_ply.organism and target_ply.organism[limb]
        if not limb_data then return end

        if item_class == "weapon_bandage_sh" then
            limb_data.health = math.min(limb_data.health + 25, 100)
            limb_data.bleeding = false
            wep:Remove()
        elseif item_class == "weapon_tourniquet_sh" then
            limb_data.bleeding = false

            if adjacent_limbs[limb] then
                for _, adjacent_limb in pairs(adjacent_limbs[limb]) do
                    local adjacent_limb_data = target_ply.organism and target_ply.organism[adjacent_limb]
                    if adjacent_limb_data then
                        adjacent_limb_data.bleeding = false
                    end
                end
            end
            wep:Remove()
        elseif item_class == "weapon_pill_sh" then
            local head_data = target_ply.organism and target_ply.organism["Head"]
            if not head_data then return end

            head_data.health = math.min(head_data.health + 10, 100)
            wep:Remove()
        end
    end
end)
