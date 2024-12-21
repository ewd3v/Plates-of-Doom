local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")

local UI = {}
UI.Maid = HeadMaid:Add(Maid.new())

local function runModule(module: (Maid.Maid, ScreenGui) -> ())
	task.defer(module.Create, module, UI.Maid:Add(Maid.new()), UI.Maid.ScreenGui)
end

local function setScreenGuiProperties(screenGui: ScreenGui)
	screenGui.Archivable = false

	screenGui.Enabled = true
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	screenGui.DisplayOrder = 0x7fffffff
	screenGui.ResetOnSpawn = false
end

function UI:Create()
	UI.Maid:DoCleaning()

	local screenGui = Instance.new("ScreenGui")
	UI.Maid.ScreenGui = screenGui

	screenGui.Name = if _G.IsGameBuild then "UI" else math.random()
	setScreenGuiProperties(screenGui)

	runModule(require("./status"))
	runModule(require("./plateNametag"))

	screenGui.Parent = playerGui
end

function UI:IsOK(): boolean
	local screenGui = UI.Maid.ScreenGui
	if not screenGui then
		return false
	end

	return screenGui.Parent == playerGui
end

function UI:Init()
	if _G.IsGameBuild then
		UI:Create()
		return
	end

	HeadMaid:GiveTask(RunService.RenderStepped:Connect(function()
		if not UI:IsOK() then
			UI:Create()
		end

		setScreenGuiProperties(UI.Maid.ScreenGui)
	end))
end

return UI
