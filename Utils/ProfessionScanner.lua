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
	if numberOfCrafts < #oldData then
		return
	end

	for craftID = 1, numberOfCrafts do
		local craftName, _, craftType = GetCraftInfo(craftID)
		local craftItemLink = GetCraftItemLink(craftID)
		local _, _, craftItemID = GetItemLinkInfo(craftItemLink)
		if craftType ~= 'header' then
			local numberOfReagents = GetCraftNumReagents(craftID)
			local reagents = {}
			for reagentID = 1, numberOfReagents do
				local name, texturePath, numberRequired = GetCraftReagentInfo(craftID, reagentID)
				if name == nil then
					print("logging", name)
				end
				table.insert(reagents, {
					name = name,
					texturePath = texturePath,
					numRequired = numberRequired
				})
			end

			local craftItem = {
				itemID = craftItemID,
				name = craftName,
				reagents = reagents,
				itemLink = craftItemLink or craftName
			}

			-- Append data from base data
			for _, v in ipairs(baseData) do
				if v.name == craftName then
					table.merge(craftItem, v)
				end
			end
			table.insert(data, craftItem)
		end
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
		for _, item in ipairs(data) do
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
