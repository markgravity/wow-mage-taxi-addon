local ItemListItem = {}
WorkWork.UIs.WorkList.ItemListItem = ItemListItem

ITEM_LIST_ITEM_HEIGHT = 25

function CreateItemListItem(index, info, parent, columnHeaders, previousItem)
	local item = {}
	extends(item, ItemListItem)
	item.info = info

	local frameName = parent:GetName()..'Item'..index
	local frame = _G[frameName] or CreateFrame('Button', parent:GetName()..'Item'..index, parent)
    frame:SetSize(parent:GetWidth(), ITEM_LIST_ITEM_HEIGHT)
	frame:ClearAllPoints()
	if previousItem then
		frame:SetPoint('TOP', previousItem.frame, 'BOTTOM', 0, -4)
	else
		frame:SetPoint('TOP', parent, 'TOP', 0, -4)
	end
	item.frame = frame

	local name = frameName..'Checked'
	local checkButton = _G[name] or CreateFrame('CheckButton', name, frame, 'ChatConfigCheckButtonTemplate')
	checkButton:ClearAllPoints()
	checkButton:SetPoint('LEFT', frame, 'LEFT', columnHeaders[1]:GetWidth() / 2 - 12, 0)
	checkButton:SetSize(20, 20)
	checkButton:SetChecked(info.checked)
	checkButton:SetScript('OnClick', function()
		item.info.checked = not item.info.checked
		if item.info.func then
			item.info.func(item.info.checked)

			if item.onSelect then
				item.onSelect(item.info.checked)
			end
			return
		end
	end)
	item.checkButton = checkButton

 	name = frameName..'Name'
	local nameText = _G[name] or frame:CreateFontString(name, 'ARTWORK', 'GameFontNormalSmall')
    nameText:SetJustifyH('LEFT')
	nameText:ClearAllPoints()
	nameText:SetPoint('LEFT', checkButton, 'RIGHT', 10, 0)
	nameText:SetWidth(columnHeaders[2]:GetWidth() - 35)
    nameText:SetText(info.name)
	nameText:SetTextColor(1, 1, 1)
	item.name = nameText
	return item
end

function ItemListItem:Show()
	self.frame:Show()
end

function ItemListItem:Hide()
	self.frame:Hide()
end

function ItemListItem:SetScript(event, script)
	if event == 'OnSelect' then
		self.onSelect = script
		return
	end
end

function ItemListItem:SetChecked(checked)
	self.info.checked = checked
	self.checkButton:SetChecked(checked)
	if self.info.func then
		self.info.func(checked)
	end
end
