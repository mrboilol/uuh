local input_list = hg.organism.input_list

local function damageNose(org, bone, dmg, dmgInfo, key)
	if org[key] >= 1 then return 0 end

	local oldDmg = org[key]
	org[key] = math.min(org[key] + dmg, 1)

	if org[key] >= 1 then
		org.bleed = org.bleed + 5
		org.painadd = org.painadd + 10
		if org.isPly then org.owner:Notify("My nose is broken!", 1, "broken"..key, 1, nil, nil) end
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 2, "Nose damage harm")
	
	org.shock = org.shock + dmg * 5
	org.painadd = org.painadd + dmg * 10

	dmgInfo:ScaleDamage(0.1)

	return 0
end

input_list.nose = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) 
	return damageNose(org, bone, dmg, dmgInfo, "nose") 
end
