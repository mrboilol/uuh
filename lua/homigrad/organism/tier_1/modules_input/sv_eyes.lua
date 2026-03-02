local input_list = hg.organism.input_list

local function damageEye(org, bone, dmg, dmgInfo, key)
	if org[key .. "destroyed"] then return 0 end

	local oldDmg = org[key]
	org[key] = math.min(org[key] + dmg * 2, 1)

	if org[key] >= 1 then
		org[key .. "destroyed"] = true
		if org.isPly then org.owner:Notify(destroyed_eye[math.random(#destroyed_eye)], 1, "destroyed"..key, 1, nil, nil) end
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 5, "Eye damage harm")
	
	org.shock = org.shock + dmg * 10
	org.painadd = org.painadd + dmg * 20

	dmgInfo:ScaleDamage(0.1)

	return 0
end

input_list.righteye = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) 
	return damageEye(org, bone, dmg, dmgInfo, "righteye") 
end

input_list.lefteye = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) 
	return damageEye(org, bone, dmg, dmgInfo, "lefteye") 
end
