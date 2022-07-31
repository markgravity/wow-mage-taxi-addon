local EnchantWork = {}
EnchantWork.__index = EnchantWork

function CreateEnchantWork(targetName, message, enchant, parent)
	local receivedMats = {}
	for _, reagent in ipairs(enchant.reagents) do
		table.insert(receivedMats, {
			itemID = reagent.itemID,
			requiredQuantity = reagent.requiredQuantity,
			quantity = 0
		})
	end

	local info = {
		targetName = targetName,
 		enchant = enchant,
		receivedMats = receivedMats
	}
	local work = CreateWork('WorkWorkEnchantWork'..targetName..enchant.name, parent)
	setmetatables(work, EnchantWork)

	work.isAutoInvite = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:Hide()

    work:SetTitle('Enchant')

	local texture = GetSpellTexture(info.enchant.spellID)
	work:SetItem(texture, info.enchant.name)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
	end)


	-- Create tasks
	local taskListContent = work.taskListContent
	work.contactTask = CreateWorkTask(
		taskListContent,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r'
	)
	work.contactTask:SetScript('OnClick', function(self)
		work:SetState('WAITING_FOR_INVITE_RESPONSE')
	end)
	work.contactTask:SetPoint('TOP', taskListContent, 'TOP', 0, 0)

	work.moveTask = CreateWorkTask(
		taskListContent,
		'Move',
		'|c60808080Waiting for contact|r',
	 	work.contactTask
	)
	work.moveTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.gatherTask = CreateWorkTask(
		taskListContent,
		'Gather',
		nil,
		work.moveTask
	)
	work.gatherTask:SetSpell(info.enchant.spellID)
	work.gatherTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)
	work:UpdateGather()

	work.enchantTask = CreateWorkTask(
		taskListContent,
		'Enchant',
		'|cffffd100'..info.enchant.name..'|r',
		work.gatherTask
	)
	work.enchantTask:SetSpell(info.enchant.spellID)
	work.enchantTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishTask = CreateWorkTask(
		taskListContent,
		'Finish',
		'|c60808080Uninvite |r|cffffd100'..info.targetName..'|r|c60808080 to the party|r',
		work.enchantTask
	)

	taskListContent:SetSize(
		WORK_WIDTH - 30,
		work.moveTask.frame:GetHeight()
		+ work.gatherTask.frame:GetHeight()
		+ work.enchantTask.frame:GetHeight()
		+ work.finishTask.frame:GetHeight()
		+ work.contactTask.frame:GetHeight()
	)
	work.moveTask:Disable()
	work.gatherTask:Disable()
	work.enchantTask:Disable()
	work.finishTask:Disable(true)
	work.contactTask:Enable()
	work.frame:Show()
	return work
end

function DetectEnchantWork(targetName, guid, message, parent)
	local message = string.lower(message)
	if message:match('wts') ~= nil then
		return
	end

    if message:match('lf') == nil and message:match('wtb') == nil then
		return nil
	end

	for _, enchant in ipairs(WorkWork.enchants) do
		for _, keyword in ipairs(enchant.keywords) do
			if message:match(keyword) ~= nil
			 	or message:match('|Henchant:'..enchant.spellID..'|h') then
				-- TODO: Check enchant learned?
				return CreateEnchantWork(targetName, message, enchant, parent)
			end
		end
	end
    return nil
end

function EnchantWork:Start()
end

function EnchantWork:SetState(state)
end

function EnchantWork:GetStateText(state)
end

function EnchantWork:GetPriorityLevel()
	return 4
end

function EnchantWork:SetScript()

end

function EnchantWork:UpdateGather()
	local description = '|c60808080Received Mats:|r'
	for _, mats in ipairs(self.info.receivedMats) do
		description = description..'\n|cffffd100 '..GetItemInfo(mats.itemID)..'|r|cfffffff0 '..mats.quantity..'/'..mats.requiredQuantity..'|r'
	end
	self.gatherTask:SetDescription(description)
end

function EnchantWork:CHAT_MSG_SYSTEM(
	text,
	playerName,
	languageName,
	channelName,
	playerName2,
	specialFlags,
	zoneChannelID,
	channelIndex,
	channelBaseName,
	languageID,
	lineID,
	guid,
	bnSenderID,
	isMobile,
	isSubtitle,
	hideSenderInLetterbox,
	supressRaidIcons
)
	-- print(text)
end
