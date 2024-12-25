local HeadMaid = require("shared/headMaid")
HeadMaid:GiveTask(function()
	warn("Client stop!")
	script:Destroy()
end)

local Network = require("client/network")

if not _G.IsGameBuild then
	-- selene: allow(undefined_variable)
	local network = ...
	Network:SetId(network.Id)
	Network:SetKey(network.Key)
end

if not _G.IsGameBuild then
	local thread = coroutine.running()
	task.defer(function()
		script:Destroy()
		task.spawn(thread)
	end)

	coroutine.yield()
end

-- Check if it failed to connect (meaning we're not the correct client, so we should quit)
if not Network:Init() then
	print("Network failed! Did you accidentally run 2 localscripts? (If so run the other one.)")
	return HeadMaid:Destroy()
end

require("shared/assets")
local UI = require("client/ui")
local Teams = require("client/teams")
local Arena = require("client/arena")

UI:Init()
Teams:Init()
Arena:Init()

if not _G.IsGameBuild then
	local leaveHint = Instance.new("Hint")
	leaveHint.Text = "Say 'pod/leave' to leave (please do this before get/noscript)."
	leaveHint.Parent = workspace

	task.delay(10, game.Destroy, leaveHint)
end
