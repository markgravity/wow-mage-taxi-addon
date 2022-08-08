local Eventable = WorkWork.Trails.Eventable
local EnchantWork = {}

function DetectEnchantWork(targetName, guid, message, parent)
	if not WorkWork.isDebug then
		if playerName == UnitName('player') then
			return nil
		end
	end

	local originalMessage = message
	local message = string.lower(message)
	if message:match('wts') ~= nil
		or message:match('lfm') ~= nil
		or message:match('selling') ~= nil
		or message:match('free') ~= nil
	 	or message:match('lfw') ~= nil then
		return
	end

    if message:match('lf') == nil
		and message:match('wtb') == nil
		and message:match('looking for') == nil then
		return nil
	end

	local enchants = WorkWorkProfessionScanner:GetData('Enchanting')
	local matchedEnchants = {}
	for _, enchant in pairs(enchants) do
		if message:match('henchant:'..enchant.itemID) ~= nil then
			table.insert(matchedEnchants, enchant)
		else
			for _, keyword in ipairs(enchant.keywords or {}) do
				if message:match(keyword) ~= nil then
					table.insert(matchedEnchants, enchant)
					break
				end
			end
		end
	end

	if #matchedEnchants > 0 then
		local clearedMessage = ClearItemLink(originalMessage)
		return CreateEnchantWork(targetName, clearedMessage, matchedEnchants, parent)
	end
    return nil
end

function CreateEnchantWork(targetName, message, enchants, parent)
	local work = CreateWork('WorkWorkEnchantWork'..targetName, parent)
	extends(work, EnchantWork, Eventable)

	local info = {
		targetName = targetName,
		enchants = enchants,
		receivedReagents = {},
		isLazy = WorkWork.charConfigs.lazyMode.enchant
	}

	work.isAutoContact = true
	work.info = info
	work:RegisterEvents({
		'TRADE_ACCEPT_UPDATE',
		'CRAFT_SHOW',
		'TRADE_TARGET_ITEM_CHANGED',
		'CHAT_MSG_SYSTEM'
	})

	local frame = work.frame
	frame:Hide()

    work:SetTitle('Enchant')
	work:SetMessage(info.targetName, message)

	-- Item List
	work.itemList:SetItems(work:GetItems())
	work.itemList:SetAllowsMultipleSelection(true)
	if #info.enchants == 0 then
		work:ToggleItemList(true)
		C_Timer.After(0.1, function()
			work.itemList:FocusSearch()
		end)
	end

	-- End Button
	work.endButton:SetScript('OnClick', function(self)
		work:End(work.state == 'FINISHING', true)
	end)

	-- Create actions
	local actionListContent = work.actionListContent
	work.contactAction = CreateContactAction(
		info.targetName,
		"i can do it",
		120,
		info.isLazy,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		frame:GetName()..'ContactAction',
		actionListContent
	)
	work.contactAction:SetScript('OnStateChange', function(self)
		if work.state == 'ENDED' then return end
		
		local state = work.contactAction:GetState()
		if state == 'WAITING_FOR_CONTACT_RESPONSE'
			or state == 'CONTACTED_TARGET'
			or state == 'CONTACT_FAILED' then
			work:SetState(state)
			return
		end
	end)
	work.contactAction:SetPoint('TOP', actionListContent, 'TOP', 0, 0)

	work.moveAction = CreateMoveAction(
		info.targetName,
		false,
		WORK_INTERECT_DISTANCE_TRADE,
		'Move',
		'|c60808080Waiting for contact|r',
		frame:GetName()..'MoveAction',
		actionListContent,
	 	work.contactAction
	)
	work.moveAction:SetScript('OnStateChange', function(self)
		local state = work.moveAction:GetState()
		if state == 'MOVING_TO_TARGET_ZONE' or state == 'MOVED_TO_TARGET_ZONE' then
			work:SetState(state)
			return
		end
	end)

	work.gatherAction = CreateAction(
		'Gather',
		nil,
		frame:GetName()..'GatherAction',
		actionListContent,
		work.moveAction
	)
	work.gatherAction:SetScript('OnClick', function(self, button)
		if button == 'LeftButton' then
			work:SetState('GATHERING_REAGENTS')
		end
	end)
	work.gatherAction:SetContextMenu({
		{
			text = 'Gather',
			isTitle = true,
			notCheckable = true
		},
		{
			text = 'Return Reagents',
			notCheckable = true,
			func = function()
				work:ReturnReagens()
			end
		},
		{
			text = 'Close',
			notCheckable = true
		}
	})

	work:UpdateEnchants()

	work.moveAction:Disable()
	work.gatherAction:Disable()
	work.contactAction:Enable()
	return work
end

function EnchantWork:Start(super)
	if self.isAutoContact then
		self.contactAction:Excute()
	end
	super()
end

function EnchantWork:SetState(super, state)
	super(state)

	local work = self

	if state == 'CONTACT_FAILED' then
		self:End(false, false, self.info.isLazy)
		return
	end

	if state == 'CONTACTED_TARGET' then
		PlaySound(6197)
		self.contactAction:Complete()
		self.moveAction:Enable()
		self.moveAction:Excute()
		return
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		self.moveAction:Complete()
		self.gatherAction:Enable()
		return
	end

	if state == 'GATHERING_REAGENTS' then
		if TradeFrame == nil or not TradeFrame:IsShown() then
			local unitID = GetUnitPartyID(self.info.targetName)
			InitiateTrade(unitID)
		end
		return
	end

	if state == 'ENCHANTING' then
		if TradeFrame == nil or not TradeFrame:IsShown() then
			local unitID = GetUnitPartyID(self.info.targetName)
			InitiateTrade(unitID)
		end
		if CraftCreateButton then
			CraftCreateButton:HookScript('OnClick', function()
				if work.state ~= 'ENCHANTING' then
					return
				end
				ClickTargetTradeButton(TRADE_ENCHANT_SLOT)
				work:SetState('ENCHANTED')
			end)
		end
		return
	end

	if state == 'ENCHANTED' then
		return
	end

	if state == 'DELIVERED' then
		self:DeduceReceivedReagents()
		self:SetState('READY_TO_ENCHANT')
		return
	end
end

function EnchantWork:GetStateText()
	local state = self.state
	if state == 'WAITING_FOR_CONTACT_RESPONSE' then
		return 'Contacting'
	end

	if state == 'CONTACTED_TARGET' then
		return 'Contacted'
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return 'Moving'
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		return 'Moved'
	end

	if state == 'GATHERING_REAGENTS' then
		return 'Gathering'
	end

	if state == 'READY_TO_ENCHANT' then
		return 'Ready'
	end

	if state == 'ENCHANTING' then
		return 'Enchanting'
	end

	if state == 'ENCHANTED' then
		return 'Enchanted'
	end

	if state == 'DELIVERED' then
		return 'Delivered'
	end

	return ''
end


function EnchantWork:GetPriorityLevel()
	if self.state == 'INITIALIZED'
		or self.state == 'WAITING_FOR_CONTACT_RESPONSE'
	 	or self.state == 'ENCHANTED' then
		return 4
	end

	if self.state == 'CONTACTED_TARGET'
	 	or self.state == 'MOVING_TO_TARGET_ZONE' then
		return 3
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'ENCHANTING' then
		return 2
	end

	return 1
end

function EnchantWork:UpdateGather()
	-- Gather Action
	local description = '|c60808080No received reagents|r'
	if not table.isEmpty(self.info.receivedReagents) then
	 	description = '|c60808080Received:|r'
		local isAllUsed = true
		for _, reagent in pairs(self.info.receivedReagents) do
			if reagent.numHave > 0 then
				description = description..'\n|cffffd100'..(reagent.name or '')..'|r|cfffffff0 x '..reagent.numHave..'|r'
				isAllUsed = false
			end
		end

		if isAllUsed then
			description = '|c60808080Used all received reagents|r'
		end
	end
	self.gatherAction:SetDescription(description)

	-- Enchant Actions
	self:UpdateEnchantsNumAvailable()
	for i, enchant in ipairs(self.info.enchants) do
		local action = self.enchantActions[i]
		action:SetCount(enchant.numAvailable)

		local description = self:GetEnchantName(enchant)..'\n\n|c60808080Required:|r'
		for _, reagent in pairs(enchant.reagents) do
			local receivedReagent = self.info.receivedReagents[reagent.name] or {}
			description = description
				..'\n|cffffd100 '
				..(reagent.name or '')
				..'|r|cfffffff0 '
				..(receivedReagent.numHave or 0)
				..'/'
				..reagent.numRequired
				..'|r'
		end
		action:SetDescription(description)
		if enchant.numAvailable > 0 then
			action:Enable()
		else
			action:Disable()
		end
	end
end

function EnchantWork:DeduceReceivedReagents()
	for _, reagent in pairs(self.activeEnchant.reagents) do
		local receivedReagent = self.info.receivedReagents[reagent.name]
		if receivedReagent ~= nil then
			receivedReagent.numHave = receivedReagent.numHave - reagent.numRequired
		end
	end
	self:UpdateGather()
end

function EnchantWork:GatherReagents()
	local isGetSome = false
	for i = 1, MAX_TRADABLE_ITEMS do
		local name, _, quantity = GetTradeTargetItemInfo(i)
		if name ~= nil then
			local receivedReagent = self.info.receivedReagents[name]
			if receivedReagent == nil then
				receivedReagent = {
					name = name,
					numHave = 0
				}
				self.info.receivedReagents[name] = receivedReagent
			end
			receivedReagent.numHave = receivedReagent.numHave + quantity
			isGetSome = true
		end
	end

	if isGetSome and self.state == 'MOVED_TO_TARGET_ZONE' then
		self:SetState('GATHERING_REAGENTS')
	end

	self:UpdateGather()
end

function EnchantWork:UpdateEnchantsNumAvailable()
	for _, enchant in ipairs(self.info.enchants) do
		local numAvailable = nil
		for _, reagent in pairs(enchant.reagents) do
			local receivedReagent = self.info.receivedReagents[reagent.name]
			if receivedReagent ~= nil then
				local newNumAvailable = math.floor(receivedReagent.numHave / reagent.numRequired)
				if numAvailable == nil or newNumAvailable < numAvailable then
					numAvailable = newNumAvailable
				end
			end
		end

		enchant.numAvailable = numAvailable or 0
	end

end

function EnchantWork:GetEnchantName(enchant)
	local name = enchant.name:gsub('Enchant ', '')
	local parts = enchant.name:split(' - ')
	return name
end

function EnchantWork:ReportMissingReagents(enchant)
	if enchant.numAvailable > 0 then
		return
	end
	local messages = {}
	for _, reagent in pairs(enchant.reagents) do
		local receivedReagent = self.info.receivedReagents[reagent.name]
		if receivedReagent == nil then
			table.insert(messages, reagent.itemLink..' x '..reagent.numRequired)
		else
			local numMissing = reagent.numRequired - receivedReagent.numHave
			table.insert(messages, reagent.itemLink..' x '..numMissing)
		end
	end

	if #messages <= 0 then return end
	SendSmartMessage(self.info.targetName, enchant.itemLink, 0)
	SendSmartMessage(self.info.targetName, 'Missing Reagents:', 0)
	for _, message in ipairs(messages) do
		SendSmartMessage(self.info.targetName, message, 0)
	end
end

function EnchantWork:ReturnReagens()
	local work = self
	local receivedReagents = table.deepCopy(self.info.receivedReagents)

	if table.isEmpty(receivedReagents) then
		return
	end

	local returnedReagents = {}
	if not TradeFrame:IsShown() then
		local unitID = GetUnitPartyID(self.info.targetName)
		Trade(
			unitID,
			self.info.targetName,
			function(isSuccess)
				work.info.receivedReagents = receivedReagents
				work:UpdateGather()
			end
		)
	end

	if GetTradeTargetName() ~= self.info.targetName then
		return
	end

	local slotIndex = 1
	for _, reagent in pairs(receivedReagents) do
		if slotIndex < MAX_TRADABLE_ITEMS then
			for bag = 0, NUM_BAG_SLOTS do
		        local numSlots = GetContainerNumSlots(bag)
		        if numSlots > 0 then
		            for slot = 1, numSlots do
 						local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bagID, slot)
		                local _, _, _, _, _, _, _, _, _, _, _, name = GetItemLinkInfo(itemLink)
		                if name == reagent.name then
							local numTake = itemCount > reagent.numHave and reagent.numHave or itemCount
							reagent.numHave = reagent.numHave - numTake
							SplitContainerItem(bagID, slot, numTake)
							ClickTradeButton(slotIndex)
							slotIndex = slotIndex + 1

							if reagent.numHave == 0 then break end
						end
		            end
		        end

				if reagent.numHave == 0 then break end
		    end
		end
	end
	AcceptTrade()
end

function EnchantWork:GetItems()
	local work = self
	local enchants = WorkWorkProfessionScanner:GetData('Enchanting')
	local items = {}
	for i, enchant in pairs(enchants or {}) do
		local checked = false
		local matchedIndex
		for i, matchedEnchant in ipairs(self.info.enchants) do
			if matchedEnchant.name == enchant.name then
				checked = true
				matchedIndex = i
				break
			end
		end
		table.insert(items, {
			name = enchant.name,
			checked = checked,
			func = function(checked)
				local enchants = work.info.enchants
				for _, action in ipairs(work.enchantActions) do
					action:Hide()
				end
				if checked then
					table.insert(enchants, enchant)
				else
					table.remove(enchants, matchedIndex)
				end
				work:UpdateEnchants()
			end
		})
	end

	return items
end

function EnchantWork:UpdateEnchants()
	local work = self
	local enchantActions = {}
	local previousAction = self.gatherAction
	local totalEnchantActionsHeight = 0
	self.activeEnchantAction = nil
	self.activeEnchant = nil

	-- Item
	local itemNames = table.map(self.info.enchants, function(enchant)
		return enchant.name
	end)
	local itemName = table.concat(itemNames,' + ')
	local texture = self.info.enchants[1] and GetSpellTexture(self.info.enchants[1].itemID) or nil
	local itemLink = #self.info.enchants == 1 and self.info.enchants[1].itemLink or nil
	work:SetItem(texture, itemName, itemLink)

	for i, enchant in ipairs(self.info.enchants) do
		local action = CreateAction(
			'Enchant',
			nil,
			self.frame:GetName()..'EnchantAction'..i,
			work.actionListContent,
			previousAction
		)
		previousAction = action
		action:SetItemLink(enchant.itemLink)
		action:SetSpell('Enchanting')
		action:HookScript('OnClick', function(self, button)
			if button == 'LeftButton' then
				work.activeEnchantAction = action
				work.activeEnchant = enchant
				work:SetState('ENCHANTING')
				return
			end
		end)
		action:SetContextMenu({
			{
				text = 'Enchant',
				isTitle = true,
				notCheckable = true
			},
			{
				text = 'Report Missing',
				notCheckable = true,
				func = function()
					work:ReportMissingReagents(enchant)
				end
			},
			{
				text = 'Close',
				notCheckable = true
			}
		})
		action:Disable()
		action:Show()
		totalEnchantActionsHeight = totalEnchantActionsHeight + action.frame:GetHeight()
		table.insert(enchantActions, action)
	end
	work.enchantActions = enchantActions

	 work.actionListContent:SetSize(
		WORK_WIDTH - 30,
		work.contactAction.frame:GetHeight()
		+ work.moveAction.frame:GetHeight()
		+ work.gatherAction.frame:GetHeight()
		+ totalEnchantActionsHeight
	)
	work:UpdateGather()
end

-- Events
function EnchantWork:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
	if self.info == nil
		or GetTradeTargetName() ~= self.info.targetName then
		return
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'GATHERING_REAGENTS' then
		if playerAccepted == 0 and targetAccepted == 1 then
			AcceptTrade()
			return
		end

		if playerAccepted == 1 and targetAccepted == 1 then
			self:GatherReagents()
			return
		end
		return
	end

	if self.state == 'ENCHANTED' then
		if playerAccepted == 0 and targetAccepted == 1 then
			AcceptTrade()
			return
		end

		if playerAccepted == 1 and targetAccepted == 1 then
			self:SetState('DELIVERED')
			local money = GetTargetTradeMoney()
			if money > 0 then
				local message = 'ty'
				if money > 10*100*100 then
					message = 'Wow!! Thank you so much :D'
				end
				SendSmartMessage(self.info.targetName, message)
			end
			return
		end
		return
	end
end

function EnchantWork:CRAFT_SHOW()
	local profession = GetCraftSkillLine(1)
	if profession ~= 'Enchanting' then
		return
	end

	if self.state == 'ENCHANTING' then
		local numberOfCrafts = GetNumCrafts()
		for craftID = 1, numberOfCrafts do
			local craftName, _, craftType = GetCraftInfo(craftID)
			if craftType ~= 'header' and craftName == self.info.enchants[1].name then
				SelectCraft(craftID)
			end
		end
		return
	end
end

function EnchantWork:TRADE_TARGET_ITEM_CHANGED()
	local work = self
	if self.state ~= 'ENCHANTING' then
		return
	end

end

function EnchantWork:CHAT_MSG_SYSTEM(text)
	if text == 'Your group has been disbanded.'
		or text == 'You leave the group.'
		or (self.info ~= nil and text == self.info.targetName..' leaves the party.') then
		self.endButton:Click()
		return
	end
end
