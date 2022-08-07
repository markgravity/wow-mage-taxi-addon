local ProfessionScanner = CreateFrame('Frame')
WorkWorkProfessionScanner = ProfessionScanner

function ProfessionScanner:Init()
	ProfessionScannerConfig = ProfessionScannerConfig or { data = {} }

	self.baseData = {
		Enchanting = WorkWork.enchants
	}
	self.config = ProfessionScannerConfig
	self:SetScript('OnEvent', function(self, event, ...)
		self[event](self, ...)
	end)
	self:RegisterEvent('CRAFT_SHOW')
	hooksecurefunc('SetItemRef', ProfessionScanner.SetItemRef)
end

function ProfessionScanner:SetAutoScan(isAuto)
	self.config.isAuto = isAuto
end

function ProfessionScanner:Scan(profession)
	local oldData = self.config.data[profession] or {}
	local baseData = self.baseData[profession]
	local data = {}
	local numberOfCrafts = GetNumCrafts()

	for craftID = 1, numberOfCrafts do
		local craftName, _, craftType = GetCraftInfo(craftID)
		local oldCraft = oldData[craftName]

		if oldCraft == nil or not oldCraft.isCompleted then
			local craftItemLink = GetCraftItemLink(craftID)
			local _, _, craftItemID = GetItemLinkInfo(craftItemLink)

			if craftType ~= 'header' then
				local numberOfReagents = GetCraftNumReagents(craftID)
				local reagents = {}
				local isCompleted = true
				if craftItemLink == nil then
					isCompleted = false
					craftItemLink = craftName
				end

				-- Regeants
				local regeantsCount = 0
				for reagentID = 1, numberOfReagents do
					local name, texturePath, numberRequired = GetCraftReagentInfo(craftID, reagentID)
					if name == nil then break end
					local reagentItemLink = GetCraftReagentItemLink(craftID, reagentID)
					local _, _, reagentItemID = GetItemLinkInfo(reagentItemLink)
					if reagentItemLink == nil then
						isCompleted = false
						reagentItemLink = name
					end
					reagents[name] = {
						itemID = reagentItemID,
						name = name,
						itemLink = reagentItemLink,
						texturePath = texturePath,
						numRequired = numberRequired
					}
					regeantsCount = regeantsCount + 1
				end

				if regeantsCount == numberOfReagents then
					local craftItem = {
						itemID = craftItemID,
						name = craftName,
						reagents = reagents,
						itemLink = craftItemLink,
						isCompleted = isCompleted
					}

					data[craftName] = craftItem
				end
			end
		else
			data[craftName] = oldData[craftName]
		end

		-- Append data from base data
		table.merge(data[craftName], baseData[craftName] or {})
	end
	self.config.data[profession] = data
end

function ProfessionScanner:GetData(profession)
	return self.config.data[profession] or {}
end

function ProfessionScanner:CRAFT_SHOW()
	local profession = GetCraftSkillLine(1)
	if self.baseData[profession] == nil then
		return
	end

	self:Scan(profession)
end

function ProfessionScanner:SetItemRef(link, text, button)
	local _, _, id = GetItemLinkInfo(link)
	if id == nil then
		return
	end

	for p, data in pairs(ProfessionScanner.config.data) do
		for _, item in pairs(data) do
			if item.itemID == id then
				ItemRefTooltip:AddLine('|c60808080Learned|r')
				if ItemRefTooltipTextLeft4 then
					ItemRefTooltipTextLeft4:SetPoint('RIGHT', -8, 0)
					ItemRefTooltipTextLeft4:SetJustifyH('RIGHT')
				end
				ItemRefTooltip:Show()
			end
		end
	end
end
