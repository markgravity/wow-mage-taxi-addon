local MoveTask = {}

function CreateMoveTask(
	targetName,
	titleText,
	descriptionText,
	parent,
	previousTask
)
	local task = CreateTask(titleText, descriptionText, parent, previousTask)
	extends(task, MoveTask)
	task.info = {
		targetName = targetName
	}
	task:HookScript('OnClick', function()
		C_Timer.After(1, function() task:DetectTargetZone() end)
	end)
	task:SetState('INITIALIZED')

	local frame = task.frame
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	frame:SetScript('OnEvent', function(self, event, ...)
		task[event](task, ...)
	end)

	return task
end

function MoveTask:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end
end

function MoveTask:GetState()
	return self.state
end

function MoveTask:SetScript(super, event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	super(event, script)
end

function MoveTask:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

function MoveTask:DetectTargetZone()
	local task = self
	local targetZone = GetPartyMemberZone(self.info.targetName)
	if targetZone == nil then
		C_Timer.After(1, function() task:DetectTargetZone() end)
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
		task:SetState('MOVING_TO_TARGET_ZONE')
	end)
	self:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
end

-- EVENTS
function MoveTask:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'MOVING_TO_TARGET_ZONE'
		and spellID == self.info.teleportSpellID then
		self:SetState('MOVED_TO_TARGET_ZONE')
		return
	end
end

function MoveTask:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_TARGET_ZONE' then
		local playerZone = GetRealZoneText()
		local targetZone = GetPartyMemberZone(self.info.targetName)

		if playerZone == targetZone then
			self:SetState('MOVED_TO_TARGET_ZONE')
		end
	end
end
