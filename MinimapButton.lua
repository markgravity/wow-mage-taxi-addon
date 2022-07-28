MinimapButton = {}

function MinimapButton:Init()
	-- Initialize LibDB
	dbIcon = LibStub("LibDBIcon-1.0");
	---@diagnostic disable-next-line: lowercase-global
	dataBroker = LibStub("LibDataBroker-1.1");

	-- Create minimap button config
	dbIconData = dataBroker:NewDataObject(
		"MageTaxi",
		{
			type = "data source",
			text = "MageTaxi",
			icon = "Interface\\MINIMAP\\TRACKING\\FlightMaster",
			iconR = 1,
			iconG = 1,
			iconB = 1,
			OnClick = self.OnClick,
			OnTooltipShow = function (tooltip)
				tooltip:AddLine("MageTaxi", 1, 1, 1);
			end,
		}
	);

	-- Add button
	dbIcon:Register("MageTaxi", dbIconData, MageTaxiConfigCharacter);
end

function MinimapButton:OnClick()
	MageTaxi:Toggle()

	if MageTaxi.isOn then
		dbIconData.iconR = 0.2;
		dbIconData.iconG = 1;
		dbIconData.iconB = 0.2;
	else
		dbIconData.iconR = 1;
		dbIconData.iconG = 1;
		dbIconData.iconB = 1;
	end
end
