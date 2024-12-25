local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Functions = require("shared/Functions")

local mouse = Players.LocalPlayer:GetMouse()

local module = {}

function module:Create(maid, screenGui: ScreenGui)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 1, 0)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
	billboard.ResetOnSpawn = false
	billboard.Size = UDim2.fromScale(1, 2)
	billboard.ClipsDescendants = false
	billboard.Parent = screenGui

	local textLabel = Instance.new("TextLabel")
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0, 1)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = textLabel

	local hovering: BasePart?
	local function hover(part: BasePart?)
		maid.ownersChanged = nil
		hovering = part

		if not part or not part:GetAttribute("IsPlate") then
			billboard.Adornee = nil
			billboard.Enabled = false

			return
		end

		billboard.Adornee = part
		billboard.Enabled = true

		maid.ownersChanged = part:GetAttributeChangedSignal("Owners"):Connect(function()
			hover(part)
		end)

		local userIds = string.split(part:GetAttribute("Owners") or "", ",")
		local owners: { Player } = {}

		for _, userId in ipairs(userIds) do
			local player = Players:GetPlayerByUserId(tonumber(userId) or 0)
			if player then
				table.insert(owners, player)
			end
		end

		textLabel.Text = Functions.formatPlateOwnerName(owners)
	end
	hover(mouse.Target)

	maid.Loop = RunService.RenderStepped:Connect(function()
		if mouse.Target ~= hovering then
			hover(mouse.Target)
		end
	end)
end

return module
