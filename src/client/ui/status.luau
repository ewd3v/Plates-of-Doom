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
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, 0, 0, 28)
	text.Position = UDim2.fromOffset(0, 12)
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Text = currentStatus
	text.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = text

	maid.StatusChanged = statusChanged:Connect(function(newStatus)
		text.Text = newStatus
	end)
end

return module
