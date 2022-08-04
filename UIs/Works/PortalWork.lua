local PortalWork = {}

local function MatchPortal(matcher)
	for _, portal in ipairs(WorkWork.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if matcher(keyword) then
				return portal
			end
		end
	end

	return nil
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

	local originalMessage = message
	local message = string.lower(message)
	if message:match('wts') ~= nil
	 	or message:match('selling') ~= nil
		or message:match('anywhere') ~= nil
		or message:match('you') ~= nil
		or message:match('services') ~= nil then
		return
	end

    if message:match(' port') == nil
		and message:match(' ports') == nil
		and message:match(' portal' ) == nil
		and message:match(' por') == nil then
		return nil
	end
	local matchers = {
		function(keyword)
			return message:match('to '..keyword)
		end,
		function(keyword)
			return message:match('>'..keyword)
		end,
		function(keyword)
			return message:match('> '..keyword)
		end,
		function(keyword)
			return message:match(keyword..' port')
		end,
		function(keyword)
			return message:match('port '..keyword) ~= nil and message:match('from') == nil
		end,
		function(keyword)
			return message:match(keyword) ~= nil
		end
	}
	for _, matcher in ipairs(matchers) do
		local portal = MatchPortal(matcher)

		if portal ~= nil then
			if not IsSpellKnown(portal.portalSpellID) then
				return nil
			end

			return CreatePortalWork(playerName, originalMessage, portal, parent)
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
	frame:RegisterEvent('TRADE_ACCEPT_UPDATE')
	frame:RegisterEvent('TRADE_MONEY_CHANGED')
	frame:Hide()

    work:SetTitle('Portal')

	local texture = GetSpellTexture(info.sellingPortal.portalSpellID)
	work:SetItem(texture, info.sellingPortal.name)
	work:SetMessage(info.targetName, message)

	work.endButton:SetScript('OnClick', function(self)
		work:End(work.state == 'WAITING_FOR_TARGET_ENTER_PORTAL', true)
	end)


	-- Create actions
	local actionListContent = work.actionListContent
	work.contactAction = CreateContactAction(
		info.targetName,
		'invite me for a portal to '..info.sellingPortal.name,
		30,
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
		true,
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

	work.makeAction = CreateAction(
		'Make',
		'|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r',
		actionListContent,
		work.moveAction
	)
	work.makeAction:SetSpell(info.sellingPortal.portalSpellName)
	work.makeAction:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishAction = CreateAction(
		'Finish',
		'|c60808080Waiting for |r|cffffd100'..info.targetName..'|r|c60808080 to enter the portal|r',
		actionListContent,
		work.makeAction
	)

	actionListContent:SetSize(
		WORK_WIDTH - 30,
		work.moveAction.frame:GetHeight()
		+ work.makeAction.frame:GetHeight()
		+ work.finishAction.frame:GetHeight()
		+ work.contactAction.frame:GetHeight()
	)
	work.moveAction:Disable()
	work.makeAction:Disable()
	work.finishAction:Disable(true)
	work.contactAction:Enable()

	frame:SetScript('OnEvent', function(self, event, ...)
		work[event](work, ...)
	end)

	return work
end

function PortalWork:Start(super)
	super()

	if self.isAutoContact then
		self.contactAction:Excute()
	end
end

function PortalWork:SetState(super, state)
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
		self.makeAction:Enable()
		return
	end

	if state == 'CREATING_PORTAL' then
		return
	end

	if state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		self.makeAction:Complete()
		self.finishAction:Enable()
		self:WaitingForTargetEnterPortal()
		return
	end
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
	self:End(true, true)
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
			self:End(true, true)
			return
		end
	end
end

function PortalWork:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
	if self.info == nil
		or GetTradeTargetName() ~= self.info.targetName then
		return
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
		or self.state == 'CREATING_PORTAL'
		or self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		if playerAccepted == 0 and targetAccepted == 1 then
			AcceptTrade()
			PlaySound(891)
			FlashClientIcon()
			return
		end
		if playerAccepted == 1 and targetAccepted == 1 then
			local money = GetTargetTradeMoney()
			local message = 'ty'
			if money > 10*100*100 then
				message = 'Wow!! Thank you so much :D'
			end
			SendSmartMessage(self.info.targetName, message)
		end
		return
	end
end

function PortalWork:TRADE_MONEY_CHANGED()
	if self.info == nil
		or GetTradeTargetName() ~= self.info.targetName then
		return
	end

	if self.state == 'MOVED_TO_TARGET_ZONE'
		or self.state == 'CREATING_PORTAL'
		or self.state == 'WAITING_FOR_TARGET_ENTER_PORTAL' then
		-- AcceptTrade()
		return
	end
end
