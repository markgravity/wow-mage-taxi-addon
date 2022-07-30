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
	item.frame = frame
	item:SetSelected(false)

	local name = frameName..'TargetName'
	local targetName = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    targetName:SetJustifyH('LEFT')
	targetName:ClearAllPoints()
	targetName:SetPoint('LEFT', frame, 'LEFT', 5, 0)
	targetName:SetWidth(columnHeaders[1]:GetWidth() - 5)
    targetName:SetText(work.targetName)

	name = frameName..'Status'
	local status = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    status:SetJustifyH('LEFT')
	status:ClearAllPoints()
    status:SetPoint('LEFT', targetName, 'RIGHT', 5, 0)
	status:SetWidth(columnHeaders[2]:GetWidth() - 5)
    status:SetText(work.status)
	status:SetTextColor(0.8, 0.8, 0.8)
	item.status = status

	name = frameName..'Type'
	local type = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    type:SetJustifyH('LEFT')
	type:ClearAllPoints()
	type:SetPoint('LEFT', status, 'RIGHT', 5, 0)
	type:SetWidth(columnHeaders[3]:GetWidth() - 5)
    type:SetText(work.typeText)
	type:SetTextColor(0.8, 0.8, 0.8)

	return item
end

function WorkListItem:SetSelected(isSelected)
	if isSelected then
		self.frame:SetNormalTexture('Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar')
	else
		self.frame:SetNormalTexture('Interface\\GuildFrame\\GuildFrame')
	    self.frame:GetNormalTexture():SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688)
	    self.frame:SetHighlightTexture('Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar')
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
