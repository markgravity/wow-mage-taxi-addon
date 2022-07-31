function GetUnitPartyID(playerName)
	for i = 1, 4 do
		local unitID = 'party'..i
		local unitName = UnitName(unitID)
		if unitName == playerName then
			return unitID
		end
	end

	return nil
end
