local ItemList = {}
WorkWork.UIs.ItemList = ItemList

function CreateItemList(parent)
	local itemList = {}
	extends(itemList, ItemList)
	itemList.info = {
		items = {},
		allowsMultipleSelection = false
	}

	local frame = CreateFrame(
		'Frame',
		parent:GetName()..'ItemList',
		parent,
		BackdropTemplateMixin and 'BackdropTemplate' or nil
	)
	frame:SetWidth(WORK_LIST_WIDTH)
    frame:SetHeight(WORK_LIST_HEIGHT)
    frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	itemList.frame = frame

	local bg = frame:CreateTexture(nil, 'ARTWORK')
    bg:SetPoint('TOPLEFT', 12, -12)
    bg:SetPoint('BOTTOMRIGHT', -12, 12)
    bg:SetTexture('Interface\\FrameGeneral\\UI-Background-Rock')

	local searchInput = CreateFrame('EditBox', nil, frame, 'InputBoxTemplate')
	searchInput:SetPoint('LEFT', 22, 0)
	searchInput:SetPoint('RIGHT', -16, 0)
	searchInput:SetPoint('TOP', 0, -16)
	searchInput:SetAutoFocus(false)
	searchInput:SetHeight(20)
	searchInput:SetScript('OnEscapePressed', function()
		searchInput:ClearFocus()
	end)
	searchInput:SetScript('OnEnterPressed', function()
		searchInput:ClearFocus()
	end)
	searchInput:SetScript('OnTextChanged', function()
		itemList:FilterItems(searchInput:GetText())
	end)
	itemList.searchInput = searchInput

	local checkColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'CheckColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	checkColumnHeader:SetPoint('LEFT', 13, -12)
	checkColumnHeader:SetPoint('TOP', searchInput, 'BOTTOM', 0, -4)
    checkColumnHeader:SetText('')
    WhoFrameColumn_SetWidth(checkColumnHeader, 30)

	local nameColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'NameColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	nameColumnHeader:SetPoint('LEFT', checkColumnHeader, 'RIGHT', 0, 0)
    nameColumnHeader:SetText('Name')
    WhoFrameColumn_SetWidth(nameColumnHeader, frame:GetWidth() - 50)
	itemList.columnHeaders = {
		checkColumnHeader,
		nameColumnHeader
	}

	local tableBody = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	tableBody:SetPoint('LEFT', 13, -12)
	tableBody:SetPoint('TOP', nameColumnHeader, 'BOTTOM', 0, 0)
    tableBody:SetPoint('BOTTOMRIGHT', -10, 10)

	local scrollFrame = CreateFrame(
		'ScrollFrame',
		frame:GetName()..'ScrollFrame',
		tableBody,
		'UIPanelScrollFrameTemplate'
	)
	scrollFrame:SetPoint('LEFT', 5, 0)
	scrollFrame:SetPoint('TOP', 0, -6)
	scrollFrame:SetPoint('BOTTOM', 0, 4)
	scrollFrame:SetPoint('RIGHT', -26, 0)

	local scrollContent = CreateFrame(
		'Frame',
		scrollFrame:GetName()..'Content',
		scrollFrame
	)
	scrollContent:SetPoint('TOPLEFT', scrollFrame, 0, 0)
	itemList.scrollContent = scrollContent

	scrollFrame:SetScrollChild(scrollContent)
	return itemList
end

function ItemList:SetItems(items)
	self.info.items = items
	self.info.filteredItems = items
	self.searchInput:SetText('')
end

function ItemList:Reload()
	local itemList = self
	local items = self.info.filteredItems
	self.scrollContent:SetSize(self.frame:GetWidth() - 40, ITEM_LIST_ITEM_HEIGHT * #items)

	for _, frame in ipairs(self.info.itemFrames or {}) do
		frame:Hide()
	end

	local previousItem
	local itemFrames = {}
	for i, item in ipairs(items) do
		local item = CreateItemListItem(
			i,
			item,
			self.scrollContent,
			self.columnHeaders,
			previousItem
		)
		previousItem = item
		item:Show()
		item.onSelect = function()
			itemList.searchInput:ClearFocus()
			if not itemList.info.allowsMultipleSelection then
				for _, frame in ipairs(itemList.info.itemFrames or {}) do
					if frame ~= item then
						frame:SetChecked(false)
					end
				end
			end
		end
		table.insert(itemFrames, item)
	end
	self.info.itemFrames = itemFrames
end

function ItemList:FilterItems(keyword)
	if keyword == nil or keyword == '' then
		self.info.filteredItems = self.info.items
		self:Reload()
		return
	end

	local filteredItems = {}
	for _, item in ipairs(self.info.items) do
		if string.lower(item.name):match(keyword) then
			table.insert(filteredItems, item)
		end
	end

	self.info.filteredItems = filteredItems
	self:Reload()
end

function ItemList:SetAllowsMultipleSelection(allows)
	self.info.allowsMultipleSelection = allows
end

function ItemList:Show()
	self.frame:Show()
end

function ItemList:Hide()
	self.frame:Hide()
end
