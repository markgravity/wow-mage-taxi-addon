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
	WorkWorkZoneFrame.isWhoFrameShown = FriendsFrame:IsShown()
	C_FriendList.SetWhoToUi(true)
	C_FriendList.SendWho('n-"'..playerName..'"')
end

WorkWorkZoneFrame = CreateFrame('Frame')
WorkWorkZoneFrame:RegisterEvent('WHO_LIST_UPDATE')
WorkWorkZoneFrame:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function WorkWorkZoneFrame:WHO_LIST_UPDATE()
	C_FriendList.SetWhoToUi(false)
	if not self.isWhoFrameShown then
		FriendsFrame:Hide()
	end

	local info = C_FriendList.GetWhoInfo(1)
	if not info then
		self.callback(nil)
		return
	end

	for i = 1, 10 do
		local info = C_FriendList.GetWhoInfo(i)
		if info == nil then
			self.callback(nil)
			return
		end

		local shortName = info.fullName:gsub('-.*', '')
		if shortName == self.lookupName then
			self.callback(info.area)
			return
		end
	end
end
