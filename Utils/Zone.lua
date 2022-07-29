function GetPartyMemberZone(playerName)
	local unknownText = 'Unknown'
	local unitID
	for i = 1, 4 do
		local tmpUnitID = 'party'..i
		local unitName = UnitName(tmpUnitID)
		if unitName == playerName then
			unitID = tmpUnitID
		end
	end

	print(unitID)
	if unitID == nil then
		return unknownText
	end

	local mapID = C_Map.GetBestMapForUnit(unitID);

	print(mapID)
	if mapID == nil then
		return unknownText
	end

	return GetZone(mapID)
end

function GetZone(mapID)
	local map = C_Map.GetMapInfo(mapID);
	print(map.mapType, map.name)
	if map.mapType > 3 then
		return GetZone(map.parentMapID)
	end
	return map.name
end