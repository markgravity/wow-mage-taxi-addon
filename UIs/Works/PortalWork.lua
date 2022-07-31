local PortalWork = {}

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

function CreatePortalWork(targetName, message, portal, parent)
	local info = {
		targetName = targetName,
		sellingPortal = portal
	}
	local work = CreateWork('WorkWorkPortalWork'..targetName..portal.name, parent)
	extends(work, PortalWork)

	work.isAutoContact = true
	work.info = info
	work:SetState('INITIALIZED')

	local frame = work.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
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
	work.contactTask = CreateContactTask(
		info.targetName,
		"Hey, please invite me for a portal to "..info.sellingPortal.name,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		taskListContent
	)
	work.contactTask:SetScript('OnStateChange', function(self)
		local state = work.contactTask:GetState()
		if state == 'WAITING_FOR_CONTACT_RESPONSE' or state == 'CONTACTED_TARGET' then
			work:SetState(state)
			return
		end
	end)
	work.contactTask:SetPoint('TOP', taskListContent, 'TOP', 0, 0)

	work.moveTask = CreateMoveTask(
		info.targetName,
		'Move',
		'|c60808080Waiting for contact|r',
		taskListContent,
	 	work.contactTask
	)
	work.moveTask:SetScript('OnStateChange', function(self)
		local state = work.moveTask:GetState()
		if state == 'MOVING_TO_TARGET_ZONE' or state == 'MOVED_TO_TARGET_ZONE' then
			work:SetState(state)
			return
		end
	end)

	work.makeTask = CreateTask(
		'Make',
		'|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r',
		taskListContent,
		work.moveTask
	)
	work.makeTask:SetSpell(info.sellingPortal.portalSpellName)
	work.makeTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishTask = CreateTask(
		'Finish',
		'|c60808080Waiting for |r|cffffd100'..info.targetName..'|r|c60808080 to enter the portal|r',
		taskListContent,
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

function PortalWork:Start()
	PlaySound(5274)
	FlashClientIcon()

	if self.isAutoContact then
		self.contactTask:Begin()
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

	if state == 'CONTACTED_TARGET' then
		self.contactTask:Complete()
		self.moveTask:Enable()
		self.moveTask:Begin()
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

	if state == 'CREATING_PORTAL' then
		return 'Making'
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 'Finishing'
	end

	return ''
end

function PortalWork:GetPriorityLevel()
	if self.state == 'WAITING_FOR_CONTACT_RESPONSE'
	 	or self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		return 4
	end

	if self.state == 'CONTACTED_TARGET'
	 	or self.state == 'MOVING_TO_TARGET_ZONE' then
		return 3
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
	 	or self.state == 'CREATING_PORTAL' then
		return 2
	end

	return 1
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
end

function PortalWork:CHAT_MSG_SYSTEM(text)
	local work = self

	if self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		if text == 'Your group has been disbanded.' then
			self.endButton:Click()
			return
		end
	end
end
