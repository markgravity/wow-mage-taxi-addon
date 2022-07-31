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
end

function ProfessionScanner:SetAutoScan(isAuto)
	self.config.isAuto = isAuto
end

function ProfessionScanner:Scan(profession)
	local data = {}
	local baseData = self.baseData[self.profession]
	local numberOfCrafts = GetNumCrafts()
	for craftID = 1, numberOfCrafts do
		local craftName, _, craftType = GetCraftInfo(craftID)
		if craftType ~= 'header' then
			local numberOfReagents = GetCraftNumReagents(craftID)
			local reagents = {}
			for reagentID = 1, numberOfReagents do
				local name, texturePath, numberRequired = GetCraftReagentInfo(craftID, reagentID)
				table.insert(reagents, {
					name = name,
					texturePath = texturePath,
					numRequired = numberRequired
				})
			end

			for i, v in ipairs(baseData) do
				if v.name == craftName then
					v.reagents = reagents
					baseData[i] = v
				end
			end
		end
	end

	if WorkWorkCacheCharacter == nil then
		WorkWorkCacheCharacter = {
			professions = {}
		}
	end

	self.config.data[self.profession] = baseData
end

function ProfessionScanner:CRAFT_SHOW()
	local profession = GetCraftSkillLine(1)
	if self.baseData[profession] == nil then
		return
	end

	self:Scan(profession)
end
