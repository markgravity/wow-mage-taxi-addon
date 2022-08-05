WorkWorkMinimapButton = {}

function WorkWorkMinimapButton:Init()
	-- Initialize LibDB
	dbIcon = LibStub('LibDBIcon-1.0');
	---@diagnostic disable-next-line: lowercase-global
	dataBroker = LibStub('LibDataBroker-1.1');

	-- Create minimap button config
	dbIconData = dataBroker:NewDataObject(
		'WorkWork',
		{
			type = 'data source',
			text = 'WorkWork',
			icon = 'Interface\\AddOns\\WorkWork\\Resources\\PeonOff',
			iconR = 1,
			iconG = 1,
			iconB =  1,
			OnClick = self.OnClick,
			OnTooltipShow = function (tooltip)
				tooltip:AddLine('WorkWork', 1, 1, 1);
			end,
		}
	);

	-- Add button
	dbIcon:Register('WorkWork', dbIconData, WorkWorkConfigCharacter);
end

function WorkWorkMinimapButton:OnClick(button)
	if button == nil or button == 'LeftButton' then
		WorkWorkPeon:Toggle()
		WorkWorkMinimapButton:UpdateIcon()
		return
	end

	if button == 'RightButton' then
		local menu = {
			{ text = 'WorkWork', isTitle = true },
			{
				text = 'Lazy Mode:',
				hasArrow = true,
				notCheckable = true,
				menuList = {
					{
						text = 'Portal',
						keepShownOnClick = true,
						checked = function()
							return WorkWork.charConfigs.lazyMode.portal
						end,
						func = function()
							WorkWork.charConfigs.lazyMode.portal = not WorkWork.charConfigs.lazyMode.portal
							WorkWorkMinimapButton:UpdateIcon()
						end
					},
					{
						text = 'Enchant',
						keepShownOnClick = true,
						checked = function()
							return WorkWork.charConfigs.lazyMode.enchant
						end,
						func = function()
							WorkWork.charConfigs.lazyMode.enchant = not WorkWork.charConfigs.lazyMode.enchant
							WorkWorkMinimapButton:UpdateIcon()
						end
					}
				}
			},
			{
				text = 'Close',
				notCheckable = true
			}
		}
		local menuFrame = CreateFrame(
			'Frame',
			'WorkWorkMinimapButtonMenu',
			 UIParent,
			 'UIDropDownMenuTemplate'
		)
		EasyMenu(menu, menuFrame, 'cursor', 0 , 0, 'MENU');
		return
	end
end

function WorkWorkMinimapButton:UpdateIcon()
	local name = 'Peon'
	local isLazy = WorkWork.charConfigs.lazyMode.portal or WorkWork.charConfigs.lazyMode.enchant
	if isLazy then
		name = 'PeonLazy'
	end
	if WorkWorkPeon.isOn then
		dbIconData.icon = 'Interface\\AddOns\\WorkWork\\Resources\\'..name..'On'
	else
		dbIconData.icon = 'Interface\\AddOns\\WorkWork\\Resources\\'..name..'Off'
	end
end
