local WorkList = {}
WorkList.__index = WorkList

function CreateWorkList(parent)
	local workList = {
		works = {}
	}
	setmetatable(workList, WorkList)

	local frame = CreateFrame(
		'Frame',
		'WorkWorkWorkList',
		parent,
		BackdropTemplateMixin and 'BackdropTemplate' or nil
	)
    frame:SetWidth(WORK_LIST_WIDTH)
    frame:SetHeight(WORK_LIST_HEIGHT)
    frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetPoint('TOPLEFT', 0, 0)
	workList.frame = frame

	local bg = frame:CreateTexture(nil, 'ARTWORK')
    bg:SetPoint('TOPLEFT', 12, -12)
    bg:SetPoint('BOTTOMRIGHT', -12, 12)
    bg:SetTexture('Interface\\FrameGeneral\\UI-Background-Rock')

	local columnHeaderWidth = frame:GetWidth() / 3 - 9
	local targetNameColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'TargetNameColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
    targetNameColumnHeader:SetPoint('TOPLEFT', 13, -12)
    targetNameColumnHeader:SetText('Target Name')
    WhoFrameColumn_SetWidth(targetNameColumnHeader, columnHeaderWidth)

	local statusColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'StatusColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	statusColumnHeader:SetPoint("LEFT", targetNameColumnHeader, "RIGHT", 0, 0)
    statusColumnHeader:SetText('Status')
    WhoFrameColumn_SetWidth(statusColumnHeader, columnHeaderWidth)

	local typeColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'TypeColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	typeColumnHeader:SetPoint("LEFT", statusColumnHeader, "RIGHT", 0, 0)
    typeColumnHeader:SetText('Type')
    WhoFrameColumn_SetWidth(typeColumnHeader, columnHeaderWidth)
	workList.columnHeaders = {
		targetNameColumnHeader,
		statusColumnHeader,
		typeColumnHeader
	}

	local tableBody = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
    tableBody:SetPoint('TOPLEFT', 10, -33)
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
	workList.scrollContent = scrollContent

	scrollFrame:SetScrollChild(scrollContent)

	return workList
end

function WorkList:TryAdd(targetName, guid, text)
	local work = DetectPortalWork(targetName, guid, text, self.frame:GetParent(), self)
	if work then
		work:Start()
		self:Add({
			id = targetName,
			targetName = targetName,
			status = work:GetStateText(),
			typeText = 'Portal',
			controller = work
		})
		return
	end
end

function WorkList:Add(work)
	table.insert(self.works, work)
	self:Reload()
	self:AutoAssign()
end

function WorkList:Remove(work)
	local foundIndex
	for i, v in ipairs(self.works) do
		if work.id == v.id then
			foundIndex = i
		end
	end

	if foundIndex == nil then
		return
	end

	work.item:Hide()
	table.remove(self.works, foundIndex)
	
	self:Reload()
	self:AutoAssign()
end

function WorkList:AutoAssign()
	if #self.works == 0 then
		return
	end

	if self.selectedWork == nil then
		self:Select(self.works[1])
		return
	end
end

function WorkList:Select(work)
	if self.selectedWork ~= nil then
		self.selectedWork.controller:Hide()
		self.selectedWork.item:SetSelected(false)
	end

	self.selectedWork = work
	work.item:SetSelected(true)
	work.controller:Show()
end

function WorkList:Reload()
	local workList = self
	self.scrollContent:SetSize(self.frame:GetWidth() - 40, WORK_LIST_ITEM_HEIGHT * #self.works)

	local previousItem
	for i, work in ipairs(self.works) do
		local item = CreateWorkListItem(
			i,
			work,
			self.scrollContent,
			self.columnHeaders,
			previousItem
		)
		item:Show()
		item:SetScript('OnClick', function()
			workList:Select(work)
		end)
		work.item = item
		work.controller:SetScript('OnStateChange', function()
			item:SetStatus(work.controller:GetStateText())
		end)
		work.controller:SetScript('OnComplete', function()
			workList:Remove(work)
		end)
		previousItem = item
	end

	if self.selectedWork ~= nil then
		self.selectedWork.item:SetSelected(true)
	end
end
