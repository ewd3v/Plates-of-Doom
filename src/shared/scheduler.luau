local Signal = require("shared/signal")

local RunService = game:GetService("RunService")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(rate: number, fixed: boolean?)
	local self = setmetatable({
		Signal = Signal.new() :: Signal.Signal<number>,
		Active = false,

		rate = rate or 1 / 60,
		fixed = fixed or false,

		dt = 0,
		dtOffset = 0,

		durationThread = nil :: thread?,
	}, Scheduler)

	self:Start()
	return self
end

function Scheduler.fixed(rate: number)
	return Scheduler.new(rate, true)
end

function Scheduler.connect(rate: number, callback: (number) -> ())
	local self = Scheduler.new(rate)
	local connection = self:Connect(callback)

	return self, connection
end

function Scheduler.connectFixed(rate: number, callback: (number) -> ())
	local self = Scheduler.fixed(rate)
	local connection = self:Connect(callback)

	return self, connection
end

function Scheduler:Destroy()
	self:Stop()
	self.Signal:Destroy()
end

function Scheduler:Connect(callback: (number) -> ())
	return self.Signal:Connect(callback)
end

function Scheduler:Wait(): number
	return self.Signal:Wait()
end

function Scheduler:Step(dt: number?)
	self.Signal:Fire(dt or self.rate)
end

local scheduled = {}
function Scheduler:Start(duration: number?)
	if not self.Active then
		self.Active = true

		local index = table.find(scheduled, self)
		if not index then
			table.insert(scheduled, self)
		end
	end

	if self.durationThread then
		task.cancel(self.durationThread)
		self.durationThread = nil
	end

	if duration then
		self.durationThread = task.delay(duration, function()
			self.durationThread = nil
			self:Stop()
		end)
	end
end

function Scheduler:Stop(duration: number?)
	if self.Active then
		self.Active = false

		local index = table.find(scheduled, self)
		if index then
			table.remove(scheduled, index)
		end
	end

	if self.durationThread then
		task.cancel(self.durationThread)
		self.durationThread = nil
	end

	if duration then
		self.durationThread = task.delay(duration, function()
			self.durationThread = nil
			self:Start()
		end)
	end
end

--@native
local function update(dtUpdate)
	debug.profilebegin("SchedulerUpdate")

	for _, scheduler in ipairs(scheduled) do
		local dt = scheduler.dt
		local rate = scheduler.rate

		dt += dtUpdate

		if scheduler.fixed then
			while dt >= rate do
				scheduler.Signal:Fire(rate)
				dt -= rate
			end
		elseif dt >= rate then
			scheduler.Signal:Fire(dt - scheduler.dtOffset)

			-- Clamp the max value to v.rate, so that v.dt doesn't increase forever if it can't catch up, but also allow for cathing up
			dt = math.min(dt - rate, rate)
			scheduler.dtOffset = dt
		end

		scheduler.dt = dt
	end

	debug.profileend()
end

RunService.Heartbeat:Connect(update)

return Scheduler
