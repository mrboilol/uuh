local max, halfValue = math.max, util.halfValue
local Organism = hg.organism
hg.organism.module.liver = {}
local module = hg.organism.module.liver
module[1] = function(org)
	org.liver = 0
	org.tranexamic_acid = 0
end

module[2] = function(owner, org, mulTime)
	if not org.alive or org.hearstop then return end

	org.bleedingmul = math.max(1 - org.liver, 0.1)

	local naturalHeal = mulTime / 1800
	if org.tranexamic_acid > 0 then
		naturalHeal = naturalHeal + (mulTime / 240 * org.tranexamic_acid)
		org.tranexamic_acid = math.Approach(org.tranexamic_acid, 0, mulTime / 120)
	end

	if org.liver > 0 then org.liver = math.Approach(org.liver, 0, naturalHeal) end
	if org.stomach > 0 then org.stomach = math.Approach(org.stomach, 0, naturalHeal) end
	if org.intestines > 0 then org.intestines = math.Approach(org.intestines, 0, naturalHeal) end
end