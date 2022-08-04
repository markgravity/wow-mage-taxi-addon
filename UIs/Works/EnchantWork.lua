local EnchantWork = {}

function DetectEnchantWork(targetName, guid, message, parent)
	local begin = GetTime()
	if targetName == 'Magemagic' then
		return
	end

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
	 	or message:match('lfw') ~= nil then
		return
	end

    if message:match('lf') == nil
		and message:match('wtb') == nil
		and message:match('looking for') == nil then
		return nil
	end

	local enchants = WorkWorkProfessionScanner:GetData('Enchanting')
	for _, enchant in ipairs(enchants) do
		local numNeeds = 1
		if message:match('x2') ~= nil
			or message:match('2x') ~= nil
			or message:match('2 x') ~= nil
			or message:match('x 2') ~= nil then
			numNeeds = 2
		end
		enchant.numNeeds = numNeeds

		if message:match('henchant:'..enchant.itemID) ~= nil then
			local clearedMessage = ClearItemLink(originalMessage)
			return CreateEnchantWork(targetName, clearedMessage, { enchant }, parent)
		end

		for _, keyword in ipairs(enchant.keywords or {}) do
			if message:match(keyword) ~= nil then
				return CreateEnchantWork(targetName, originalMessage, { enchant }, parent)
			end
		end
	end
    return nil
end

function CreateEnchantWork(targetName, message, enchants, parent)
	local work = CreateWork('WorkWorkEnchantWork'..targetName, parent)
	extends(work, EnchantWork)

	-- Setup default receivedReagents
	local receivedReagents = {}
	for _, enchant in ipairs(enchants) do
		for _, reagent in ipairs(enchant.reagents) do
			local receivedReagent = work:GetReagentByName(
				reagent.name,
				receivedReagents
			)

			if receivedReagent ~= nil then
				receivedReagent.numRequired = receivedReagent.numRequired * enchant.numNeeds
					+ reagent.numRequired
			else
				table.insert(receivedReagents, {
					name = reagent.name,
					numRequired = reagent.numRequired * enchant.numNeeds,
					numHave = 0
				})
			end
		end
	end

	local info = {
		targetName = targetName,
		enchants = enchants,
		receivedReagents = receivedReagents
	}

	work.isAutoContact = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('TRADE_ACCEPT_UPDATE')
	frame:RegisterEvent('CRAFT_SHOW')
	frame:RegisterEvent('TRADE_TARGET_ITEM_CHANGED')
	frame:Hide()

    work:SetTitle('Enchant')

	local texture = GetSpellTexture(info.enchants[1].itemID)
	work:SetItem(texture, info.enchants[1].name, info.enchants[1].itemLink)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
		work:End(work.state == 'FINISHING', true)
	end)

	-- Create actions
	local actionListContent = work.actionListContent
	work.contactAction = CreateContactAction(
		info.targetName,
		"i can come and do "..info.enchants[1].itemLink..'',
		120,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		actionListContent
	)
	work.contactAction:SetScript('OnStateChange', function(self)
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
		'Move',
		'|c60808080Waiting for contact|r',
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
		actionListContent,
		work.moveAction
	)
	work.gatherAction:SetScript('OnClick', function(self)
		work:SetState('GATHERING_REAGENTS')
	end)

	local enchantActions = {}
	local previousAction = work.gatherAction
	local totalEnchantActionsHeight = 0
	for i, enchant in ipairs(info.enchants) do
		local name = 'Enchant'
		if #info.enchants > 1 then
			name = name..' '..i
		end
		local action = CreateAction(
			name,
			'|cffffd100'..info.enchants[1].name..'|r',
			actionListContent,
			previousAction
		)
		previousAction = action
		action:SetSpell('Enchanting')
		action:HookScript('OnClick', function(self)
			work.activeEnchantAction = action
			work.activeEnchant = enchant
			work:SetState('ENCHANTING')
		end)
		action:Disable()
		totalEnchantActionsHeight = totalEnchantActionsHeight + action.frame:GetHeight()
		table.insert(enchantActions, action)
	end
	work.enchantActions = enchantActions

	work.finishAction = CreateAction(
		'Finish',
		'|c60808080Uninvite |r|cffffd100'..info.targetName..'|r|c60808080 to the party|r',
		actionListContent,
		enchantActions[#enchantActions]
	)
	work:SetScript('OnClick', function()
		work.endButton:Click()
	end)
	actionListContent:SetSize(
		WORK_WIDTH - 30,
		work.contactAction.frame:GetHeight()
		+ work.moveAction.frame:GetHeight()
		+ work.gatherAction.frame:GetHeight()
		+ work.finishAction.frame:GetHeight()
		+ totalEnchantActionsHeight
	)
	work.moveAction:Disable()
	work.gatherAction:Disable()
	work.finishAction:Disable(true)
	work.contactAction:Enable()

	work:UpdateGather()
	frame:SetScript('OnEvent', function(self, event, ...)
		work[event](work, ...)
	end)
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
		self:End(false, false)
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
				-- C_Timer.After(1, function()
				-- 	local _, _, _, _, enchantment = GetTradeTargetItemInfo(TRADE_ENCHANT_SLOT)
				-- 	print("logging", enchant, GetTradeTargetName() ~= work.info.targetName)
				-- 	if enchantment and GetTradeTargetName() ~= work.info.targetName then
				--
				-- 	end
				-- end)
				work:SetState('ENCHANTED')
			end)
		end
		return
	end

	if state == 'ENCHANTED' then
		return
	end

	if state == 'DELIVERED' then
		self.activeEnchantAction:Complete()
		self:DeduceReceivedReagents()
		for _, action  in ipairs(self.enchantActions) do
			if not action:IsCompleted() then
				return
			end
		end
		self.finishAction:Enable()
		return
	end

	if state == 'FINISHING' then
		self:End(true, true)
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
		return 'GATHERING'
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
	local description = '|c60808080Received Reagents:|r'
	for _, reagent in ipairs(self.info.receivedReagents) do
		description = description..'\n|cffffd100 '..(reagent.name or '')..'|r|cfffffff0 '..reagent.numHave..'/'..reagent.numRequired..'|r'
	end
	self.gatherAction:SetDescription(description)

	local isGatherActionCompleted = true
	for _, receivedReagent in ipairs(self.info.receivedReagents) do
		if receivedReagent.numHave < receivedReagent.numRequired then
			isGatherActionCompleted = false
		end
	end
	if isGatherActionCompleted then
		self.gatherAction:Complete()
	end

	-- Enchant Actions
	for i, enchant in ipairs(self.info.enchants) do
		local action = self.enchantActions[i]
		local hasAllReagentsRequired = true
		for _, reagent in ipairs(enchant.reagents) do
			local receivedReagent = self:GetReagentByName(
				reagent.name,
				self.info.receivedReagents
			)
			if receivedReagent.numHave < reagent.numRequired then
				hasAllReagentsRequired = false
			end
		end

		if hasAllReagentsRequired then
			if action:IsCompleted() then
				action:Uncomplete()
			end
			self.enchantActions[i]:Enable()
		else
			if not action:IsCompleted() then
				self.enchantActions[i]:Disable()
			end
		end
	end
end

function EnchantWork:DeduceReceivedReagents()
	for _, reagent in ipairs(self.activeEnchant.reagents) do
		local receivedReagent = self:GetReagentByName(reagent.name, self.receivedReagents)
		if receivedReagent ~= nil then
			receivedReagent.numHave = receivedReagent.numHave - reagent.numRequired
			eceivedReagent.numRequired = receivedReagent.numRequired - reagent.numRequired
		end
	end
	self:UpdateGather()
end

function EnchantWork:GatherReagents()
	local isGatherSome = false
	for i = 1, MAX_TRADABLE_ITEMS do
		local name, _, quantity = GetTradeTargetItemInfo(i)
		for _, mat in ipairs(self.info.receivedReagents) do
			if mat.name == name then
				mat.numHave = mat.numHave + quantity
				isGatherSome = true
			end
		end
	end

	if isGatherSome and self.state == 'MOVED_TO_TARGET_ZONE' then
		self:SetState('GATHERING_REAGENTS')
	end

	self:UpdateGather()
end


function EnchantWork:GetReagentByName(name, reagents)
	for _, reagent in ipairs(reagents) do
		if reagent.name == name then
			return reagent
		end
	end

	return nil
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
