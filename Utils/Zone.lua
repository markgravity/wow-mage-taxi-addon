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

function GetZoneByPlayerName(playerName, callback)
	WorkWorkZoneFrame.lookupName = playerName
	WorkWorkZoneFrame.callback = callback
	C_FriendList.SendWho('n-"'..playerName..'"')
end

WorkWorkZoneFrame = CreateFrame('Frame')
WorkWorkZoneFrame:RegisterEvent('CHAT_MSG_SYSTEM')
WorkWorkZoneFrame:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function WorkWorkZoneFrame:CHAT_MSG_SYSTEM(text)
	if self.lookupName == nil
		or self.callback == nil
	 	or text:match('%['..self.lookupName..'%]') == nil then return end
	local area = text:match('- .*'):gsub('- ', '')
	self.callback(area)
	self.lookupName = nil
	self.callback = nil
end
