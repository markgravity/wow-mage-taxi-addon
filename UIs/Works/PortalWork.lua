local PortalWork = {}
PortalWork.__index = PortalWork

function CreatePortalWork(targetName, message, portal, parent)
	local info = {
		targetName = targetName,
		sellingPortal = portal
	}
	local work = CreateWork('WorkWorkPortalWork'..targetName..portal.name, parent)
	setmetatables(work, PortalWork)

	work.isAutoInvite = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:Hide()

    work:SetTitle('Portal')

	local texture = GetSpellTexture(info.sellingPortal.portalSpellID)
	work:SetItem(texture, info.sellingPortal.name)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
		work:Complete()
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

	work.makeTask = CreateWorkTask(
		taskListContent,
		'Make',
		'|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r',
		work.moveTask
	)
	work.makeTask:SetSpell(info.sellingPortal.portalSpellName)
	work.makeTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishTask = CreateWorkTask(
		taskListContent,
		'Finish',
		'|c60808080Waiting for |r|cffffd100'..info.targetName..'|r|c60808080 to enter the portal|r',
		work.makeTask
	)

	taskListContent:SetSize(
		WORK_WIDTH - 30,
		work.moveTask.frame:GetHeight()
		+ work.makeTask.frame:GetHeight()
		+ work.finishTask.frame:GetHeight()
		+ work.contactTask.frame:GetHeight()
	)
	work.moveTask:Disable()
	work.makeTask:Disable()
	work.finishTask:Disable(true)
	work.contactTask:Enable()

	frame:SetScript('OnEvent', function(self, event, ...)
		work[event](work, ...)
	end)

	return work
end

function DetectPortalWork(playerName, guid, message, parent)
	if not WorkWork.isDebug then
		if playerName == UnitName('player') then
			return nil
		end

		local _, playerClass = GetPlayerInfoByGUID(guid)
		if playerClass == 'MAGE' then
			return nil
		end
	end

	local message = string.lower(message)
	if message:match('wts') ~= nil then
		return
	end

    if message:match('port') == nil and message:match('portal') == nil then
		return nil
	end


	for _, portal in ipairs(WorkWork.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if message:match('to '..keyword) ~= nil
				or message:match('> '..keyword) ~= nil
				or message:match(keyword..' port') ~= nil
				or (message:match('port '..keyword) ~= nil and message:match('from') == nil) then
				if not IsSpellKnown(portal.portalSpellID) then
					return nil
				end
				return CreatePortalWork(playerName, message, portal, parent)
			end
		end
	end
    return nil
end

function PortalWork:Start()
	PlaySound(5274)
	FlashClientIcon()
	if self.isAutoInvite then
		self.contactTask:Run()
	end
end

function PortalWork:Complete()
	if UnitIsGroupLeader('player') then
		UninviteUnit(self.info.targetName)
	else
		LeaveParty()
	end

	self.info = nil
	self:SetState('ENDED')
	self.frame:Hide()

	if self.onComplete then
		self.onComplete()
	end
end

function PortalWork:SetState(state)
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
		self.makeTask:Enable()
		return
	end

	if state == 'CREATING_PORTAL' then
		return
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		self.makeTask:Complete()
		self.finishTask:Enable()
		self:WaitingForTargetEnterPortal()
		return
	end
end

function PortalWork:GetState()
	return self.state
end

function PortalWork:GetStateText()
	local state = self.state
	if state == 'WAITING_FOR_INVITE_RESPONSE' then
		return 'Contacting'
	end

	if state == 'INVITED_TARGET' then
		return 'Contacted'
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		return 'Moving'
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		return 'Moved'
	end

	if state == 'CREATING_PORTAL' then
		return 'Making'
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 'Finishing'
	end

	return ''
end

function PortalWork:GetPriorityLevel()
	if self.state == 'WAITING_FOR_INVITE_RESPONSE'
	 	or self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 4
	end

	if self.state == 'INVITED_TARGET'
	 	or self.state == 'MOVING_TO_TARGET_ZONE' then
		return 3
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'CREATING_PORTAL' then
		return 2
	end

	return 1
end

function PortalWork:SendWho(command)
	C_FriendList.SetWhoToUi(true)
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	C_FriendList.SendWho(command);
end

function PortalWork:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

function PortalWork:DetectTargetZone()
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

function PortalWork:WaitingForTargetEnterPortal()
	if self.info == nil then
		return
	end

	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone ~= self.info.sellingPortal.zoneName then
		local work = self
		C_Timer.After(1, function() work:WaitingForTargetEnterPortal() end)
		return
	end
	self.endButton:Click()
end

function PortalWork:SetScript(event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	if event == 'OnComplete' then
		self.onComplete = script
		return
	end
end

-- EVENTS
function PortalWork:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'CREATING_PORTAL'
		and spellID == self.info.sellingPortal.portalSpellID then
		self:SetState('WAITING_FOR_TARGET_ENTER_PORTAL')
		return
	end

	if self.state == 'MOVING_TO_TARGET_ZONE'
		and spellID == self.info.movingPortal.teleportSpellID then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end
end

function PortalWork:CHAT_MSG_SYSTEM(
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
			Whisper(self.info.targetName, "Hey, please invite me for a portal to "..self.info.sellingPortal.name)
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


	if self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		if text == 'Your group has been disbanded.' then
			self.endButton:Click()
			return
		end
	end
end

function PortalWork:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_TARGET_ZONE'
	 	or self.state == 'INVITED_TARGET' then
		local playerZone = GetRealZoneText()
		local targetZone = GetPartyMemberZone(self.info.targetName)

		if playerZone == targetZone then
			self:SetState('MOVED_TO_TARGET_ZONE')
		end
	end
end
