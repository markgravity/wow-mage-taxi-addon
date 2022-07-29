local WorkListItem = {}
WorkListItem.__index = WorkListItem
WORK_LIST_ITEM_HEIGHT = 18

function CreateWorkListItem(work, parent, columnHeaders, previousItem)
	local item = {}
	setmetatable(item, WorkListItem)

	local frame = CreateFrame('Button', nil, parent)
    frame:SetNormalTexture('Interface\\GuildFrame\\GuildFrame')
    frame:GetNormalTexture():SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688)
    frame:SetHighlightTexture('Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar')
    frame:SetSize(parent:GetWidth(), WORK_LIST_ITEM_HEIGHT)
	if previousItem then
		frame:SetPoint('TOP', previousItem.frame, 'BOTTOM', 0, -4)
	else
		frame:SetPoint('TOP', parent, 'TOP', 0, -4)
	end
	item.frame = frame

	local targetName = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    targetName:SetJustifyH('LEFT')
	targetName:SetPoint('LEFT', frame, 'LEFT', 5, 0)
	targetName:SetWidth(columnHeaders[1]:GetWidth() - 5)
    targetName:SetText(work.targetName)

	local status = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    status:SetJustifyH('LEFT')
    status:SetPoint('LEFT', targetName, 'RIGHT', 5, 0)
	status:SetWidth(columnHeaders[2]:GetWidth() - 5)
    status:SetText(work.status)
	status:SetTextColor(0.8, 0.8, 0.8)

	local type = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    type:SetJustifyH('LEFT')
	type:SetPoint('LEFT', status, 'RIGHT', 5, 0)
	type:SetWidth(columnHeaders[3]:GetWidth() - 5)
    type:SetText(work.typeText)
	type:SetTextColor(0.8, 0.8, 0.8)

	return item
end
