function extends(object, baseClass)
	baseClass.__index = baseClass
	setmetatables(object, baseClass)
end
