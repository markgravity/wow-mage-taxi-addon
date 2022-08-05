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
				text = 'Lazy',
				checked = WorkWork.charConfigs.isLazy or false,
				func = function(self)
					WorkWork.charConfigs.isLazy = not self.checked
					WorkWorkMinimapButton:UpdateIcon()
				end
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
	if WorkWork.charConfigs.isLazy then
		name = 'PeonLazy'
	end
	if WorkWorkPeon.isOn then
		dbIconData.icon = 'Interface\\AddOns\\WorkWork\\Resources\\'..name..'On'
	else
		dbIconData.icon = 'Interface\\AddOns\\WorkWork\\Resources\\'..name..'Off'
	end
end
