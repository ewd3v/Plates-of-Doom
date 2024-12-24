local List = require("./list")

local Event = {}
Event.__index = Event

function Event.new(data)
	local self = setmetatable({}, Event)
	self.Data = data

	return self
end

function Event:RunFunc(index: number, ...)
	local value = self.Data[index]
	if type(value) == "function" then
		return value(...)
	elseif type(value) == "table" then
		return unpack(value)
	end
end

function Event:Init()
	return self:RunFunc(2)
end

function Event:Selector(...)
	return self:RunFunc(3, ...)
end

function Event:Run(context, ...)
	self.Data[4](context, ...)
end

local Events = {}

function Events:GetPossible(Game): table
	local possible = table.clone(List)

	local totalWeight = 0
	for _, data in ipairs(possible) do
		totalWeight += data[1]
	end

	possible.totalWeight = totalWeight
	return possible
end

function Events:Get(possible: table): typeof(Event.new())?
	local random = Random.new()
	local targetWeight = random:NextInteger(1, possible.totalWeight)

	local weightCounter = 0
	for _, data in ipairs(possible) do
		weightCounter += data[1]

		if weightCounter <= targetWeight then
			return Event.new(data)
		end
	end
end

return Events
