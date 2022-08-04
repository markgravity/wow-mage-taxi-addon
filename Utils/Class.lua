function extends(object, baseClass, trail)
	baseClass.__index = baseClass
	setmetatables(object, baseClass)
	if trail then
		table.merge(object, trail)
	end
end
