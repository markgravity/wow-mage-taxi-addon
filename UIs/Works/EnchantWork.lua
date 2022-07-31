local EnchantWork = {}

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
				receivedReagent.numRequired = receivedReagent.numRequired
					+ reagent.numRequired
			else
				table.insert(receivedReagents, {
					name = reagent.name,
					numRequired = reagent.numRequired,
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

	work.isAutoInvite = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('TRADE_SHOW')
	frame:RegisterEvent('TRADE_ACCEPT_UPDATE')
	frame:RegisterEvent('CRAFT_SHOW')
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:Hide()

    work:SetTitle('Enchant')

	local texture = GetSpellTexture(20014)
	work:SetItem(texture, info.enchants[1].name)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
		work:Complete()
	end)

	-- Create actions
	local actionListContent = work.actionListContent
	work.contactAction = CreateContactAction(
		info.targetName,
		"Hey, please invite me for enchanting "..info.enchants[1].itemLink,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		actionListContent
	)
	work.contactAction:SetScript('OnStateChange', function(self)
		local state = work.contactAction:GetState()
		if state == 'WAITING_FOR_CONTACT_RESPONSE' or state == 'CONTACTED_TARGET' then
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
		work:SetState('GATHERING_MATS')
	end)

	work.enchantActions = {
		CreateAction(
			'Enchant',
			'|cffffd100'..info.enchants[1].name..'|r',
			actionListContent,
			work.gatherAction
		)
	}
	-- work.enchantActions[1]:SetMarcro('/cast Enchanting\n/run local s for i=1,GetNumCrafts() do s=GetCraftInfo(i) if (s=="'..info.enchants[1].name..'") then print("xxx") SelectCraft(i) end end\n/click CraftCreateButton')
	work.enchantActions[1]:SetSpell('Enchanting')
	CraftCreateButton.IsForbidden = function() return true end
	work.enchantActions[1]:HookScript('OnClick', function(self)
		work.activeEnchant = work.info.enchants[1]
		work:SetState('ENCHANTING')
	end)

	work.finishAction = CreateAction(
		'Finish',
		'|c60808080Uninvite |r|cffffd100'..info.targetName..'|r|c60808080 to the party|r',
		actionListContent,
		work.enchantActions[1]
	)

	actionListContent:SetSize(
		WORK_WIDTH - 30,
		work.contactAction.frame:GetHeight()
		+ work.moveAction.frame:GetHeight()
		+ work.gatherAction.frame:GetHeight()
		+ work.enchantActions[1].frame:GetHeight()
		+ work.finishAction.frame:GetHeight()
	)
	work.moveAction:Disable()
	work.gatherAction:Disable()
	work.enchantActions[1]:Disable()
	work.finishAction:Disable(true)
	work.contactAction:Enable()
	work.frame:Show()

	work:UpdateGather()
	frame:SetScript('OnEvent', function(self, event, ...)
		work[event](work, ...)
	end)
	return work
end

function DetectEnchantWork(targetName, guid, message, parent)
	if targetName ~= UnitName('player') then
		return nil
	end

	local message = string.lower(message)
	if message:match('wts') ~= nil then
		return
	end

    if message:match('lf') == nil
		and message:match('wtb') == nil
		and message:match('looking for') == nil then
		return nil
	end

	local enchants = WorkWorkProfessionScanner:GetData('Enchanting')
	for _, enchant in ipairs(enchants) do
		if message:match(enchant.itemLink) then
			return CreateEnchantWork(targetName, message, { enchant }, parent)
		end

		for _, keyword in ipairs(enchant.keywords or {}) do
			if message:match(keyword) ~= nil then
				return CreateEnchantWork(targetName, message, { enchant }, parent)
			end
		end
	end
    return nil
end

function EnchantWork:Start()
	PlaySound(5274)
	FlashClientIcon()

	if self.isAutoContact then
		self.contactAction:Excute()
	end
end

function EnchantWork:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	local work = self

	if state == 'CONTACTED_TARGET' then
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

	if state == 'GATHERING_MATS' then

		return
	end

	if state == 'READY_TO_ENCHANT' then
		self.gatherAction:Complete()
		self.enchantActions[1]:Enable()
		return
	end

	if state == 'ENCHANTING' then
		local unitID = GetUnitPartyID(self.info.targetZone)
		TargetUnit(unitID);
		InitiateTrade('target')
		return
	end

	if state == 'ENCHANTED' then
		AcceptTrade()
		return
	end

	if state == 'DELIVERED' then
		self.enchantActions[1]:Complete()
		self.finishAction:Enable()
		return
	end

	if state == 'FINISHING' then
		self:Complete()
		return
	end
end

function EnchantWork:GetStateText(state)
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

	if state == 'GATHERING_MATS' then
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

function EnchantWork:SetScript(event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	if event == 'OnComplete' then
		self.onComplete = script
		return
	end
end

function EnchantWork:GetPriorityLevel()
	if self.state == 'WAITING_FOR_CONTACT_RESPONSE'
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
	local description = '|c60808080Received Mats:|r'
	for _, reagent in ipairs(self.info.receivedReagents) do
		description = description..'\n|cffffd100 '..reagent.name..'|r|cfffffff0 '..reagent.numHave..'/'..reagent.numRequired..'|r'
	end
	self.gatherAction:SetDescription(description)

	local isGatherActionCompleted = true
	for _, receivedReagent in ipairs(self.info.receivedReagents) do
		if receivedReagent.numHave < receivedReagent.numRequired then
			isGatherActionCompleted = false
		end
	end
	if isGatherActionCompleted then
		self:SetState('READY_TO_ENCHANT')
	end

	-- Enchant Actions
	-- for i, enchant in ipairs(self.info.enchants) do
	-- 	local hasAllReagentsRequired = true
	-- 	for _, reagent in ipairs(enchant.reagents) do
	-- 		local receivedReagent = self:GetReagentByName(
	-- 			reagent.name,
	-- 			self.info.receivedReagents
	-- 		)
	-- 		if receivedReagent.numHave < reagent.numRequired then
	-- 			hasAllReagentsRequired = false
	-- 		end
	-- 	end
	--
	-- 	if hasAllReagentsRequired then
	-- 		self.enchantActions[i]:Enable()
	-- 	else
	-- 		self.enchantActions[i]:Disable()
	-- 	end
	-- end
end

function EnchantWork:GatherReagents()
	for i = 1, 7 do
		local name, _, quantity = GetTradeTargetItemInfo(i)
		for _, mat in ipairs(self.info.receivedReagents) do
			if mat.name == name then
				mat.numHave = mat.numHave + quantity
			end
		end
	end

	self:UpdateGatherAndEnchantActions()
end

function EnchantWork:GetTradeTargetName()
	if TradeFrameRecipientNameText == nil then
		return TradeFrameRecipientNameText:GetText()
	end
	return nil
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
function EnchantWork:TRADE_SHOW()
	if self:GetTradeTargetName() ~= self.info.targetName then
		return
	end

	if self.state == 'ENCHANTING' then
		return
	end
end

function EnchantWork:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'GATHERING_MATS' then
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

	if self.state == 'ENCHANTED'
	 	and playerAccepted == 1 and targetAccepted == 1 then
		self:SetState('DELIVERED')
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

function EnchantWork:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'ENCHANTING' then
		local spellName = GetSpellInfo(spellID)
		if spellName == self.info.enchants[1].name then
			self:SetState('ENCHANTED')
			return
		end
		return
	end
end
