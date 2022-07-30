local WorkListItem = {}
WorkListItem.__index = WorkListItem
WORK_LIST_ITEM_HEIGHT = 18

function CreateWorkListItem(index, work, parent, columnHeaders, previousItem)
	local item = {}
	setmetatable(item, WorkListItem)
	local frameName = parent:GetName()..'Item'..index
	local frame = _G[frameName] or CreateFrame('Button', parent:GetName()..'Item'..index, parent)
    frame:SetSize(parent:GetWidth(), WORK_LIST_ITEM_HEIGHT)
	frame:ClearAllPoints()
	if previousItem then
		frame:SetPoint('TOP', previousItem.frame, 'BOTTOM', 0, -4)
	else
		frame:SetPoint('TOP', parent, 'TOP', 0, -4)
	end
	frame:SetScript('OnEnter', function()
		item:OnEnter()
	end)
	frame:SetScript('OnLeave', function()
		item:OnLeave()
	end)
	item.frame = frame

	local name = frameName..'Icon'
	local icon = _G[name] or CreateFrame('Button', name, frame)
	icon:ClearAllPoints()
	icon:SetPoint('LEFT', frame, 'LEFT', columnHeaders[1]:GetWidth() / 2 - 5, 0)
	icon:SetSize(10, 10)
	icon:SetNormalTexture('Interface\\ICONS\\Spell_Arcane_PortalShattrath')
	icon:EnableMouse(false)
	icon:Disable()

 	name = frameName..'TargetName'
	local targetName = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    targetName:SetJustifyH('LEFT')
	targetName:ClearAllPoints()
	targetName:SetPoint('LEFT', icon, 'RIGHT', 10, 0)
	targetName:SetWidth(columnHeaders[2]:GetWidth() - 5)
    targetName:SetText(work.targetName)
	item.unhiglightTargetNameColors = { targetName:GetTextColor() }
	item.targetName = targetName

	name = frameName..'Status'
	local status = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    status:SetJustifyH('LEFT')
	status:ClearAllPoints()
    status:SetPoint('LEFT', targetName, 'RIGHT', 5, 0)
	status:SetWidth(columnHeaders[3]:GetWidth() - 5)
    status:SetText(work.status)
	status:SetTextColor(0.8, 0.8, 0.8)
	item.unhiglightStatusColors = { status:GetTextColor() }
	item.status = status

	item:SetSelected(false)
	return item
end

function WorkListItem:SetSelected(isSelected)
	self.isSelected = isSelected
	local colors = { self.targetName:GetTextColor() }
	if isSelected then
		self.frame:SetNormalTexture('Interface\\QuestFrame\\UI-QuestLogTitleHighlight')
		self.frame:GetNormalTexture():SetVertexColor(colors[1], colors[2], colors[3])
		self.frame:SetHighlightTexture('')
		self:SetHighlight(true)
	else
		self.frame:SetNormalTexture('')
	    self.frame:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestLogTitleHighlight')
		self.frame:GetHighlightTexture():SetVertexColor(colors[1], colors[2], colors[3])
	end
end

function WorkListItem:SetHighlight(isHighlight)
	if isHighlight then
		self.targetName:SetTextColor(
			HIGHLIGHT_FONT_COLOR.r,
		 	HIGHLIGHT_FONT_COLOR.g,
			HIGHLIGHT_FONT_COLOR.b
		)
		self.status:SetTextColor(
			0.9,
			0.9,
			0.9
		)
	else
		self.targetName:SetTextColor(
			self.unhiglightTargetNameColors[1],
			self.unhiglightTargetNameColors[2],
			self.unhiglightTargetNameColors[3]
		)
		self.status:SetTextColor(
			self.unhiglightStatusColors[1],
			self.unhiglightStatusColors[2],
			self.unhiglightStatusColors[3]
		)
	end
end

function WorkListItem:SetScript(...)
	self.frame:SetScript(...)
end

function WorkListItem:SetStatus(status)
	self.status:SetText(status)
end

function WorkListItem:Hide()
	self.frame:Hide()
end

function WorkListItem:Show()
	self.frame:Show()
end

function WorkListItem:SetPriorityLevel(level)
	local colors
	if level == 'urgent' then
		colors = { 1, 0.1, 0.1 } -- red
	end

	if level == 'high' then
		colors = { 1, 0.5, 0.25 } -- orange
	end

	if level == 'medium' then
		colors = { 1, 1, 0 } -- yellow
	end

	if level == 'low' then
		colors = { 0.5, 0.5, 0.5 } -- gray
	end
	self.targetName:SetTextColor(colors[1], colors[2], colors[3])
	self.unhiglightTargetNameColors = colors
	self:SetSelected(self.isSelected)
end

function WorkListItem:OnEnter()
	if self.isSelected then
		return
	end

	self:SetHighlight(true)
end

function WorkListItem:OnLeave()
	if self.isSelected then
		return
	end
	self:SetHighlight(false)
end
