MinimapButton = {}

function MinimapButton:Init()
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
			icon = "Interface\\ICONS\\RACIAL_ORC_BERSERKERSTRENGTH",
			iconR = 1,
			iconG = 1,
			iconB = 1,
			OnClick = self.OnClick,
			OnTooltipShow = function (tooltip)
				tooltip:AddLine("WorkWork", 1, 1, 1);
			end,
		}
	);

	-- Add button
	dbIcon:Register("WorkWork", dbIconData, WorkWorkConfigCharacter);
end

function MinimapButton:OnClick()
	WorkWork:Toggle()

	if WorkWork.isOn then
		dbIconData.iconR = 1;
		dbIconData.iconG = 1;
		dbIconData.iconB = 1;
	else
		dbIconData.iconR = 0.7;
		dbIconData.iconG = 0.7;
		dbIconData.iconB = 0.7;
	end
end
