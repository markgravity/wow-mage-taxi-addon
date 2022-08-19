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
	FriendsFrame:UnregisterEvent('WHO_LIST_UPDATE')
	C_FriendList.SendWho('n-"'..playerName..'"')
end

WorkWorkZoneFrame = CreateFrame('Frame')
WorkWorkZoneFrame:RegisterEvent('WHO_LIST_UPDATE')
WorkWorkZoneFrame:RegisterEvent('CHAT_MSG_SYSTEM')
WorkWorkZoneFrame:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function WorkWorkZoneFrame:CHAT_MSG_SYSTEM(text)
	FriendsFrame:RegisterEvent('WHO_LIST_UPDATE')
	if self.lookupName == nil
		or self.callback == nil
	 	or text:match('%['..self.lookupName..'%]') == nil then return end
	local area = text:match('- .*'):gsub('- ', '')
	self.callback(area)
	self.lookupName = nil
	self.callback = nil
end

function WorkWorkZoneFrame:WHO_LIST_UPDATE()
	if self.lookupName == nil
		or self.callback == nil then return end
	FriendsFrame:RegisterEvent('WHO_LIST_UPDATE')
	local info = C_FriendList.GetWhoInfo(1)
	local i = 1
	while info do
		if info.fullName == self.lookupName then
			self.callback(info.area)
			return
		end
		i = i + 1
		info = C_FriendList.GetWhoInfo(i)
	end
end
