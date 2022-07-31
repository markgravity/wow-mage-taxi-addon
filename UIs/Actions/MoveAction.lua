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
	action:HookScript('OnClick', function()
		C_Timer.After(1, function() action:DetectTargetZone() end)
	end)
	action:SetState('INITIALIZED')

	local frame = action.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:SetScript('OnEvent', function(self, event, ...)
		action[event](action, ...)
	end)

	return action
end

function MoveAction:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	if state == 'MOVING_TO_TARGET_ZONE' then
		SendPartyMessage('Hi, I\'m coming to you!!')
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

	local playerZone = GetRealZoneText()
	if playerZone == targetZone then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end

	local portal = self:FindPortal(targetZone)
	if portal == nil then
		self:SetState('MOVING_TO_TARGET_ZONE')
		self:SetDescription('|c60808080Move to |r|cffffd100'..targetZone..'|r|c60808080 manually|r')
		self:Enable()
		return
	end

	self.info.teleportSpellID = portal.teleportSpellID
	self:SetSpell(portal.teleportSpellName)
	self:HookScript('OnClick', function()
		action:SetState('MOVING_TO_TARGET_ZONE')
	end)
	self:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
end

-- EVENTS
function MoveAction:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'MOVING_TO_TARGET_ZONE'
		and spellID == self.info.teleportSpellID then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end
end

function MoveAction:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_TARGET_ZONE' then
		local playerZone = GetRealZoneText()
		local targetZone = GetPartyMemberZone(self.info.targetName)

		if playerZone == targetZone then
			self:SetState('MOVED_TO_TARGET_ZONE')
		end
	end
end
