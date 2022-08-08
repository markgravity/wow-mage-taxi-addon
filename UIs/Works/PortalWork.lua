local Eventable = WorkWork.Trails.Eventable
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
		or message:match('free') ~= nil
		or message:match('services') ~= nil then
		return nil
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
			return message:match(keyword) ~= nil and message:match(keyword..'-') == nil
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
		sellingPortal = portal,
		isLazy = WorkWork.charConfigs.lazyMode.portal
	}
	local work = CreateWork('WorkWorkPortalWork'..targetName..(portal and portal.name or ''), parent)
	extends(work, PortalWork, Eventable)

	work.isAutoContact = true
	work.info = info
	work:SetState('INITIALIZED')
	work:RegisterEvents({
		'UNIT_SPELLCAST_SUCCEEDED',
		'CHAT_MSG_SYSTEM',
		'TRADE_ACCEPT_UPDATE',
		'TRADE_MONEY_CHANGED'
	})
	work:SetTitle('Portal')
	work.frame:Hide()

	work:SetMessage(info.targetName, message)

	-- Item List
	work.itemList:SetItems(work:GetItems())

	-- End Button
	work.endButton:SetScript('OnClick', function(self)
		work:End(work.state == 'WAITING_FOR_TARGET_ENTER_PORTAL', true)
	end)

	-- Create actions
	local actionListContent = work.actionListContent
	work.contactAction = CreateContactAction(
		info.targetName,
		info.sellingPortal and 'inv me for a portal to '..info.sellingPortal.name or 'inv me for the portal',
		30,
		info.isLazy,
		'Contact',
		'|c60808080Invite |r|cffffd100'..info.targetName..'|r|c60808080 into the party|r',
		work.frame:GetName()..'ContactAction',
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
		WORK_INTERECT_DISTANCE_INSPECT,
		'Move',
		'|c60808080Waiting for contact|r',
		work.frame:GetName()..'MoveAction',
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
		info.sellingPortal and '|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r' or nil,
		work.frame:GetName()..'MakeAction',
		actionListContent,
		work.moveAction
	)
	work.makeAction:SetSpell(info.sellingPortal and info.sellingPortal.portalSpellName or '')
	work.makeAction:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.finishAction = CreateAction(
		'Finish',
		'|c60808080Waiting for |r|cffffd100'..info.targetName..'|r|c60808080 to enter the portal|r',
		work.frame:GetName()..'FinishAction',
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

	work:UpdateSellingPortal()
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

function PortalWork:GetItems()
	local work = self
	local portals = WorkWork.portals
	local items = {}
	for i, portal in ipairs(portals or {}) do
		local checked = self.info.sellingPortal and portal.name == self.info.sellingPortal.name or false
		table.insert(items, {
			name = portal.name,
			checked = checked,
			func = function(checked)
				if checked then
					work.info.sellingPortal = portal
					work:UpdateSellingPortal()
					return
				end

				if not checked
					and work.info.sellingPortal ~= nil
				 	and work.info.sellingPortal.name == portal.name then
					work.info.sellingPortal = nil
					work:UpdateSellingPortal()
					return
				end
			end
		})
	end

	return items
end

function PortalWork:UpdateSellingPortal()
	local info = self.info

	-- Item
	local texture = info.sellingPortal and GetSpellTexture(info.sellingPortal.portalSpellID) or nil
	local itemLink = info.sellingPortal and GetSpellLink(info.sellingPortal.portalSpellID) or nil
	local name = info.sellingPortal and info.sellingPortal.name or buk
	self:SetItem(texture, name, itemLink)

	--  Make Action
	if info.sellingPortal then
		self.makeAction:Show()
		self.finishAction:Show()
		self.makeAction:SetDescription('|c60808080Create a |r|cffffd100'..info.sellingPortal.name..'|r|c60808080 portal|r')
		self.makeAction:SetSpell(info.sellingPortal.portalSpellName)
	else
		self.makeAction:Hide()
		self.finishAction:Hide()
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
