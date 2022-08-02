local MoveAction = {}

function CreateMoveAction(
	targetName,
	titleText,
	descriptionText,
	parent,
	previousAction
)
	local action = CreateAction(titleText, descriptionText, parent, previousAction)
	extends(action, MoveAction)
	action.info = {
		targetName = targetName
	}
	action.isMessageSent = false
	action:HookScript('OnClick', function()
		C_Timer.After(1, function() action:DetectTargetZone() end)
	end)
	action:SetState('INITIALIZED')

	local frame = action.frame
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:SetScript('OnEvent', function(self, event, ...)
		action[event](action, ...)
	end)

	return action
end

function MoveAction:SetState(state, ...)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	if state == 'MOVING_TO_TARGET_ZONE'
	 	or state == 'READY_TO_MOVE' then
		self:WaitingForTargetInRange()
		return
	end

	if state == 'MOVED_TO_TARGET_ZONE' then
		FlashClientIcon()
		return
	end
end

function MoveAction:GetState()
	return self.state
end

function MoveAction:SetScript(super, event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	super(event, script)
end

function MoveAction:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

function MoveAction:DetectTargetZone()
	if self.state ~= 'INITIALIZED' then
		return
	end

	local action = self
	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone == nil then
		C_Timer.After(1, function() action:DetectTargetZone() end)
		return
	end

	self:SetState('READY_TO_MOVE')
	local portal = self:FindPortal(targetZone)

	local playerZone = GetPlayerZone()
	if playerZone == targetZone then
		self:SetDescription('Waiting for |cffffd100'..self.info.targetName..'|r|c60808080 to come|r')
		action.isMessageSent = true
		Whisper(self.info.targetName, 'can you come to me please? :D')
		return
	end


	if portal == nil then
		self:SetState('MOVING_TO_TARGET_ZONE')
		self:SetDescription('|c60808080Move to |r|cffffd100'..targetZone..'|r|c60808080 manually|r')
		self:Enable()
		return
	end

	self:SetSpell(portal.teleportSpellName)
	self:HookScript('OnClick', function()
		if action.state ~= 'MOVING_TO_TARGET_ZONE' then
			action:SetState('MOVING_TO_TARGET_ZONE')
		end

		if not action.isMessageSent then
			action.isMessageSent = true
			Whisper(action.info.targetName, 'teleporting to u now')
		end
	end)
	self:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
	if GetNumGroupMembers() > 2 and UnitIsGroupLeader('player') then
		Whisper(action.info.targetName, 'wait me a sec, teleport to u rq')
	end
end

function MoveAction:WaitingForTargetInRange()
	local action = self
	if self.isCancel then
		return
	end
	if self.state ~= 'MOVING_TO_TARGET_ZONE'
	 	and self.state ~= 'READY_TO_MOVE' then
		return
	end

	local unitID = GetUnitPartyID(self.info.targetName)
	if unitID == nil or not CheckInteractDistance(unitID, 1) then
		C_Timer.After(1, function() action:WaitingForTargetInRange() end)
		return
	end

	PlaySound(6192)
	self:SetState('MOVED_TO_TARGET_ZONE')
end

-- EVENTS
function MoveAction:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_TARGET_ZONE'
	 	or self.state == 'READY_TO_MOVE' then
		local playerZone = GetPlayerZone()
		local targetZone = GetPartyMemberZone(self.info.targetName)

		if playerZone == targetZone then
			self:SetDescription('Waiting for |cffffd100'..self.info.targetName..'|r|c60808080 to come|r')
			Whisper(self.info.targetName, 'can u come to me please? :D')
		end
	end
end
