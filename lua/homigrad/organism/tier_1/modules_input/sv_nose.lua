local input_list = hg.organism.input_list

local function damageNose(org, bone, dmg, dmgInfo, key)
	if org[key] >= 1 then
		print("Nose broken for", org.owner:Nick())
 return 0 end

	local oldDmg = org[key]
	org[key] = math.min(org[key] + dmg * 5, 1)

	if org[key] >= 1 then
		org.bleed = org.bleed + 10
		org.painadd = org.painadd + 20
		if org.isPly then org.owner:Notify("My nose is broken!", 1, "broken"..key, 1, nil, nil) end
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 5, "Nose damage harm")
	
	org.shock = org.shock + dmg * 10
	org.painadd = org.painadd + dmg * 20

	return 0
end

input_list.nose = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) 
	return damageNose(org, bone, dmg, dmgInfo, "nose") 
end
