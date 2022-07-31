function setmetatables(t1, t2)
	local t1Metatable = getmetatable(t1)
	setmetatable(t1, t2)
	if t1Metatable == nil then
		return
	end
	
	for k,v in pairs(t1Metatable) do
		if t1[k] ~= nil then
			local override = t1[k]
			t1[k] = function(self, ...)
				override(
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
   for k,v in ipairs(t2) do
      table.insert(t1, v)
   end

   return t1
end
