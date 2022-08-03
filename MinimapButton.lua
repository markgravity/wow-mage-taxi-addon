WorkWorkMinimapButton = {}

function WorkWorkMinimapButton:Init()
	-- Initialize LibDB
	dbIcon = LibStub("LibDBIcon-1.0");
	---@diagnostic disable-next-line: lowercase-global
	dataBroker = LibStub("LibDataBroker-1.1");

	-- Create minimap button config
	dbIconData = dataBroker:NewDataObject(
		"WorkWork",
		{
			type = "data source",
			text = "WorkWork",
			icon = "Interface\\AddOns\\WorkWork\\Resources\\PeonOff",
			iconR = 1,
			iconG = 1,
			iconB =  1,
			OnClick = self.OnClick,
			OnTooltipShow = function (tooltip)
				tooltip:AddLine("WorkWork", 1, 1, 1);
			end,
		}
	);

	-- Add button
	dbIcon:Register("WorkWork", dbIconData, WorkWorkConfigCharacter);
end

function WorkWorkMinimapButton:OnClick()
	WorkWorkPeon:Toggle()

	if WorkWorkPeon.isOn then
		dbIconData.icon = "Interface\\AddOns\\WorkWork\\Resources\\PeonOn"
	else
		dbIconData.icon = "Interface\\AddOns\\WorkWork\\Resources\\PeonOff"
	end
end
