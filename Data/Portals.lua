WorkWork.portals = {
	{
		name = 'Stormwind',
		zoneName = 'Stormwind City',
		keywords = { 'sw', 'stormwind' },
		portalSpellName = 'Portal: Stormwind',
		portalSpellID = 10059,
		teleportSpellName = 'Teleport: Stormwind',
		teleportSpellID = 3561,
	},
	{
		name = 'Stonard',
		zoneName = 'Swamp of Sorrows',
		keywords = { 'stonard' },
		portalSpellName = 'Portal: Stonard',
		portalSpellID = 49361,
		teleportSpellName = 'Teleport: Stonard',
		teleportSpellID = 49358,
	},
	{
		name = 'Theramore',
		zoneName = 'Dustwallow Marsh',
		keywords = { 'thera', 'theremore', 'teramore', 'thara', 'Theramore' },
		portalSpellName = 'Portal: Theramore',
		portalSpellID = 49360,
		teleportSpellName = 'Teleport: Theramore',
		teleportSpellID = 49359,
	},
	{
		name = 'Undercity',
		zoneName = 'Undercity',
		keywords = { 'under', 'undercity' },
		portalSpellName = 'Portal: Undercity',
		portalSpellID = 11418,
		teleportSpellName = 'Teleport: Undercity',
		teleportSpellID = 3563,
	},
	{
		name = 'Exodar',
		zoneName = 'The Exodar',
		keywords = { 'exo', 'exodar' },
		portalSpellName = 'Portal: Exodar',
		portalSpellID = 32266,
		teleportSpellName = 'Teleport: Exodar',
		teleportSpellID = 32271,
	},
	{
		name = 'Orgrimmar',
		zoneName = 'Orgrimmar',
		keywords = { 'org', 'orgim', 'Orgrimmar' },
		portalSpellName = 'Portal: Orgrimmar',
		portalSpellID = 11417,
		teleportSpellName = 'Teleport: Orgrimmar',
		teleportSpellID = 3567,
	},
	{
		name = 'Thunder Bluff',
		zoneName = 'Thunder Bluff',
		keywords = { 'bluff', 'thunder bluff' },
		portalSpellName = 'Portal: Thunder Bluff',
		portalSpellID = 11420,
		teleportSpellName = 'Teleport: Thunder Bluff',
		teleportSpellID = 3566,
	},
	{
		name = 'Silvermoon',
		zoneName = 'Silvermoon',
		keywords = { 'silver', 'silvermoon' },
		portalSpellName = 'Portal: Silvermoon',
		portalSpellID = 32267,
		teleportSpellName = 'Teleport: Silvermoon',
		teleportSpellID = 32272,
	},
	{
		name = 'Darnassus',
		zoneName = 'Darnassus',
		keywords = { 'darns', 'darn', 'darnassus' },
		portalSpellName = 'Portal: Darnassus',
		portalSpellID = 11419,
		teleportSpellName = 'Teleport: Darnassus',
		teleportSpellID = 3565,
	},
	{
		name = 'Ironforge',
		zoneName = 'Ironforge',
		keywords = { 'if', 'ironforge' },
		portalSpellName = 'Portal: Ironforge',
		portalSpellID = 11416,
		teleportSpellName = 'Teleport: Ironforge',
		teleportSpellID = 3562,
	}
}

local Portals = CreateFrame('Frame')
Portals:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)
Portals:RegisterEvent('PLAYER_ENTERING_WORLD')

function Portals:PLAYER_ENTERING_WORLD()
	local faction = UnitFactionGroup('player')
	local portal = {
		name = 'Shattrath',
		zoneName = 'Shattrath City',
		keywords = { 'shatt', 'shat', 'shattrath' },
		portalSpellName = 'Portal: Shattrath',
		teleportSpellName = 'Teleport: Shattrath'
	}
	if faction == 'Alliance' then
		portal.portalSpellID = 33691
		portal.teleportSpellID = 33690
		table.insert(WorkWork.portals, portal)
		return
	end

	if faction == 'Horde' then
		portal.portalSpellID = 35717
		portal.teleportSpellID = 35715
		table.insert(WorkWork.portals, portal)
		return
	end
end
