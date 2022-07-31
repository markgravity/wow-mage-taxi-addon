function setmetatables(t1, t2)
	local t1Metatable = getmetatable(t1)
	setmetatable(t1, t2)
	if t1Metatable == nil then
		return
	end

	for k,v in pairs(t1Metatable) do
		if k ~= '__index' and t1[k] ~= nil then
			local override = t1[k]
			t1[k] = function(self, ...)
				return override(
					self,
					function(...)
						v(self,...)
					end,
					...
				)
			end
		else
			t1[k] = v
		end
	end
end

function table.merge(t1, t2)
	if table.isArray(t1) then
		for _, v in ipairs(t2) do
		  table.insert(t1, v)
		end
		return
	else
		for k, v in pairs(t2) do
			t1[k] = v
		end
		return
	end
end

function table.isArray(t)
  return #t > 0 and next(t, #t) == nil
end
