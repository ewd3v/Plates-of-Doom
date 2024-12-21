local Network = require("client/network")
local Signal = require("shared/signal")
local HeadMaid = require("shared/headMaid")

local currentStatus = "..."
local statusChanged = HeadMaid:Add(Signal.new())

local function setStatus(newStatus: string)
	currentStatus = newStatus
	statusChanged:Fire(newStatus)
end

Network.event("SetStatus", setStatus)
task.spawn(function()
	setStatus(Network:InvokeServer("GetStatus"))
end)

local module = {}

function module:Create(maid, screenGui: ScreenGui)
	-- TODO: Actual ui

	local statusHint = Instance.new("Hint")
	statusHint.Text = currentStatus
	statusHint.Parent = screenGui

	maid.StatusChanged = statusChanged:Connect(function(newStatus)
		statusHint.Text = newStatus
	end)
end

return module
