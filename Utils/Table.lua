function setmetatables(t1, t2)
	local t1Metatable = getmetatable(t1)
	setmetatable(t1, t2)
	for k,v in pairs(t1Metatable) do
		t1[k] = v
	end
end
