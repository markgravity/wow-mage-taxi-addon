local EnchantWork = {}

function CreateEnchantWork(targetName, message, enchants, parent)
	local receivedMats = {}
	for _, enchant in ipairs(enchants) do
		for _, reagent in ipairs(enchant.reagents) do
			table.insert(receivedMats, {
				name = reagent.name,
				numRequired = reagent.numRequired,
				numHave = 0
			})
		end
	end

	local info = {
		targetName = targetName,
 		enchants = enchants,
		receivedMats = receivedMats
	}
	local work = CreateWork('WorkWorkEnchantWork'..targetName, parent)
	extends(work, EnchantWork)

	work.isAutoInvite = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:RegisterEvent('TRADE_SHOW')
	frame:RegisterEvent('TRADE_ACCEPT_UPDATE')
	frame:Hide()

    work:SetTitle('Enchant')

	local texture = GetSpellTexture(20014)
	work:SetItem(texture, info.enchants[1].name)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
	end)

	-- Create tasks
	local taskListContent = work.taskListContent
	work.contactTask = CreateTask(
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		taskListContent
	)
	work.contactTask:SetScript('OnClick', function(self)
		work:SetState('WAITING_FOR_INVITE_RESPONSE')
	end)
	work.contactTask:SetPoint('TOP', taskListContent, 'TOP', 0, 0)

	work.moveTask = CreateTask(
		'Move',
		'|c60808080Waiting for contact|r',
		taskListContent,
	 	work.contactTask
	)

	work.gatherTask = CreateTask(
		'Gather',
		nil,
		taskListContent,
		work.moveTask
	)
	work.gatherTask:HookScript('OnClick', function(self)
		work:SetState('GATHERING_MATS')
	end)
	work:UpdateGather()

	work.enchantTask = CreateTask(
		'Enchant',
		'|cffffd100'..info.enchants[1].name..'|r',
		taskListContent,
		work.gatherTask
	)
	work.enchantTask:HookScript('OnClick', function(self)
		work:SetState('ENCHANTING')
	end)

	work.finishTask = CreateTask(
		'Finish',
		'|c60808080Uninvite |r|cffffd100'..info.targetName..'|r|c60808080 to the party|r',
		taskListContent,
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
		for _, keyword in ipairs(enchant.keywords) do
			if message:match(keyword) ~= nil
			 	or message:match(enchant.itemLink) then
				return CreateEnchantWork(targetName, message, { enchant }, parent)
			end
		end
	end
    return nil
end

function EnchantWork:Start()
end

function EnchantWork:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	local work = self

	if state == 'WAITING_FOR_INVITE_RESPONSE' then
		InviteUnit(self.info.targetName)
		return
	end

	if state == 'INVITED_TARGET' then
		SendPartyMessage('Hi, I\'m coming!!')
		self.contactTask:Complete()
		C_Timer.After(1, function() work:DetectTargetZone() end)
		return
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		self.moveTask:Complete()
		self.gatherTask:Enable()
		return
	end

	if state == 'GATHERING_MATS' then

		return
	end

	if state == 'ENCHANTING' then
		return
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		self.makeTask:Complete()
		self.finishTask:Enable()
		self:WaitingForTargetEnterPortal()
		return
	end
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
		description = description..'\n|cffffd100 '..mats.name..'|r|cfffffff0 '..mats.numHave..'/'..mats.numRequired..'|r'
	end
	self.gatherTask:SetDescription(description)
end

function EnchantWork:DetectTargetZone()
	local work = self
	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone == nil then
		C_Timer.After(1, function() work:DetectTargetZone() end)
		return
	end

	local playerZone = GetRealZoneText()
	local work = self

	if playerZone == targetZone then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end

	local portal = self:FindPortal(targetZone)
	if portal == nil then
		self:SetState('MOVING_TO_TARGET_ZONE')
		self.moveTask:SetDescription('|c60808080Move to |r|cffffd100'..targetZone..'|r|c60808080 manually|r')
		self.moveTask:Enable()
		return
	end

	self.info.movingPortal = portal
	self.moveTask:SetSpell(portal.teleportSpellName)
	self.moveTask:HookScript('OnClick', function()
		work:SetState('MOVING_TO_TARGET_ZONE')
	end)
	self.moveTask:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
	self.moveTask:Enable()
end

function EnchantWork:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

-- Events
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
	local work = self
	if self.state == 'WAITING_FOR_INVITE_RESPONSE' then
		if text == self.info.targetName..' is already in a group.' then
			Whisper(self.info.targetName, "Hey, please invite me for enchanting "..self.info.enchants[1].itemLink)
			self.contactTask:SetDescription('|c60808080Waiting for |r|cffffd100'..self.info.targetName..'|r|c60808080 invites you into the party|r')
			WorkWorkAutoAcceptInvite:SetEnabled(true, function ()
				work:SetState('INVITED_TARGET')
			end)
			return
		end

		if text == self.info.targetName..' joins the party.' then
			work:SetState('INVITED_TARGET')
			return
		end
		return
	end
end

function EnchantWork:TRADE_SHOW()
	if TradeFrameRecipientNameText == nil
	 	or TradeFrameRecipientNameText:GetText() ~= self.info.targetName then
		return
	end

	if self.state == 'CONTACTED' then

		return
	end
end
