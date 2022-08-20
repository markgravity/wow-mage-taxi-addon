local Eventable = WorkWork.Trails.Eventable
local ProspectingWork = {}

function CreateProspectingWork(parent)
	local info = {
		spellID = 31252,
		results = {},
		activeOre = nil
	}
	local work = CreateWork('WorkWorkPropectingWork', parent)
	extends(work, ProspectingWork, Eventable)

	work.isAutoContact = true
	work.info = info
	work:RegisterEvents({
		'UNIT_SPELLCAST_SUCCEEDED',
		'CHAT_MSG_LOOT'
	})
	work:SetTitle('Prospecting')
	work.frame:Hide()

	work:SetMessage('', 'Search 5 ore of a base metal for precious gem.')

	-- End Button
	work.endButton:SetScript('OnClick', function(self)
		work:End(true, true)
	end)

	-- Item
	local itemLink = GetSpellLink(31252)
	work:SetItem('134081', 'Prospecting', itemLink)

	-- Create actions
	work.actions = {}
	work:CreateActions()

	return work
end

function ProspectingWork:CreateActions()
	local work = self

	for _, action in ipairs(self.actions) do
		action:Hide()
	end
	self.actions = {}

	local foundOres = {}
	for _, ore in pairs(WorkWork.ores) do
		for bag = 0, NUM_BAG_SLOTS do
			local numSlots = GetContainerNumSlots(bag)
			if numSlots > 0 then
				for slot = 1, numSlots do
					local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
					if itemLink then
						local _, _, itemID = GetItemLinkInfo(itemLink)
						if tonumber(itemID) == ore.itemID then
							local foundOre = foundOres[itemID]
							if foundOre == nil then
								foundOre = {
									itemID = ore.itemID,
									name = ore.name,
									numHave = 0
								}
								foundOres[itemID] = foundOre
							end

							foundOre.numHave = foundOre.numHave + itemCount
						end
					end
				end
			end
		end
	end
	local actionListContent = self.actionListContent
	local previousAction = actionListContent
	local totalHeight = 0
	for _, ore in pairs(foundOres) do
		local count = math.floor(ore.numHave / 5)
		local resultDescription = self:GetResultDescription(ore.itemID)
 		local action = CreateAction(
			'Prospecting',
			'|c60808080Destroy|r 5 x |cffffd100'..ore.name..'|r|c60808080\ninto:|r\n'..resultDescription,
			self.frame:GetName()..ore.name,
			previousAction
		)
		action:SetMarcro("/use Prospecting\n/use "..ore.name)
		action:Show()
		action:Enable()
		action:SetCount(count)
		action:HookScript("OnClick", function()
			self.info.activeOre = ore
		end)
		table.insert(self.actions, action)

		totalHeight = totalHeight + action.frame:GetHeight()
		previousAction = action
	end

	self.actionListContent:SetSize(
		WORK_WIDTH - 30,
		totalHeight
	)
end

function ProspectingWork:GetResultDescription(oreItemID)
	local description = ''
	for _, item in pairs(self.info.results[oreItemID] or {}) do
		description = description..'\n|cffffd100'..item.name..'|r|cfffffff0 x '..item.numReceived..'|r'
	end

	return description
end

function ProspectingWork:DebounceCreatingActions()
	local work = self
	work.info.chatMSGLootLock = (work.info.chatMSGLootLock or 0) + 1
	local lock = work.info.chatMSGLootLock
	C_Timer.After(0.1, function()
		if lock ~= work.info.chatMSGLootLock then return end
		work.info.activeOre = nil
		work:CreateActions()
	end)
end

-- EVENTS
function ProspectingWork:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
end

function ProspectingWork:CHAT_MSG_LOOT(text)
	local ore = self.info.activeOre
	if ore == nil then return end
	self:DebounceCreatingActions()

	local itemID = tonumber(text:match("Hitem:(%d+)"))
	local itemName = GetItemInfo(itemID)
	local numReceived = tonumber(text:match("|h|rx(%d+)"))
	if numReceived == nil then
		numReceived = 1
	end


	local results = self.info.results
	local result = results[ore.itemID]
	if result == nil then
		result = {}
		results[ore.itemID] = result
	end

	local item = result[itemID]
	if item == nil then
		item = {
			itemID = itemID,
			name = itemName,
			numReceived = 0
		}
		result[itemID] = item
	end
	item.numReceived = item.numReceived + numReceived
end
