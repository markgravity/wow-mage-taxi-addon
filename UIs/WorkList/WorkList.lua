local WorkList = {}
WorkList.__index = WorkList

function CreateWorkList()
	local works = {
		{
			targetName = 'Davidsnake',
			status = 'Contacting',
			typeText = 'Portal'
		},
		{
			targetName = 'Tobiz',
			status = 'Trading',
			typeText = 'Enchant'
		}
	}
	local workList = {}
	setmetatable(workList, WorkList)

	local frame = CreateFrame(
		'Frame',
		'WorkWorkWorkList',
		UIParent,
		BackdropTemplateMixin and 'BackdropTemplate' or nil
	)
    frame:SetWidth(260)
    frame:SetHeight(220)
    frame:SetBackdrop(BACKDROP_DIALOG_32_32)
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
	scrollContent:SetSize(frame:GetWidth() - 40, WORK_LIST_ITEM_HEIGHT * #works)
	scrollFrame:SetScrollChild(scrollContent)

	local previousItem
	for _, work in ipairs(works) do
		local item = CreateWorkListItem(
			work,
			scrollContent,
			{ targetNameColumnHeader, statusColumnHeader, typeColumnHeader },
			previousItem
		)
		previousItem = item
	end

	return workList
end
