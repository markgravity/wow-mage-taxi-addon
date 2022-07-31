function GetPartyMemberZone(playerName)
	local unitID = GetUnitPartyID(playerName)

	if unitID == nil then
		return nil
	end

	local mapID = C_Map.GetBestMapForUnit(unitID);

	if mapID == nil then
		return nil
	end

	return GetZone(mapID)
end

function GetPlayerZone()
	local mapID = C_Map.GetBestMapForUnit('player');

	if mapID == nil then
		return nil
	end

	return GetZone(mapID)
end

function GetZone(mapID)
	local map = C_Map.GetMapInfo(mapID);

	if map.mapType > 3 then
		return GetZone(map.parentMapID)
	end
	return map.name
end
