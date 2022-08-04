local AceEvent = LibStub('AceEvent-3.0')
WorkWork = LibStub('AceAddon-3.0'):NewAddon('WorkWork', 'AceConsole-3.0')
WorkWork.Trails = {}
WorkWork.isDebug = true

WORK_LIST_WIDTH = 200
WORK_LIST_HEIGHT = 400
WORK_WIDTH = 210
WORK_HEIGHT = 400

function WorkWork:OnInitialize()
	WorkWorkProfessionScanner:Init()
	WorkWorkMinimapButton:Init()
	WorkWorkPeon:Init()
	WorkWorkProfessionScanner:SetAutoScan(true)
end
