local Eventable = {}
WorkWork.Trails.Eventable = Eventable

function Eventable:RegisterEvents(events)
	local this = self
	self.registeredEvents = events or (self.registeredEvents or {})
	for _, event in ipairs(events) do
		self.frame:RegisterEvent(event)
	end

	self.frame:SetScript('OnEvent', function(self, event, ...)
		this[event](this, ...)
	end)
end

function Eventable:UnregisterEvents()
	for _, event in ipairs(self.registeredEvents or {}) do
		self.frame:UnregisterEvent(event)
	end
end
