local HeadMaid = require("shared/headMaid")
local Network = require("server/network")
local Game = require("server/game")
local Character = require("server/character")
local Maid = require("shared/maid")
local Scheduler = require("shared/scheduler")

local Players = game:GetService("Players")

-- selene: allow(undefined_variable)
local owner = owner

local function findPlayer(name: string): Player?
	local lowerName = string.lower(name)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.lower(string.sub(player.Name, 1, #lowerName)) == lowerName then
			return player
		end
	end
end

local function runLocal(player: Player)
	if _G.IsGameBuild then
		return
	end

	if Network:IsConnected() then
		Network:Disconnect("You joined again")
	end

	local key = Network:GenerateKey()
	Network:SetKey(player, key)

	local playerGui = player:FindFirstChildOfClass("PlayerGui")

	local hint = Instance.new("Hint")
	hint.Text = "Make sure local script requests are enabled to join!"
	hint.Parent = playerGui
	task.delay(10, game.Destroy, hint)

	local localGui = Instance.new("ScreenGui")
	localGui.ResetOnSpawn = false
	localGui.Name = math.random()
	localGui.Parent = playerGui

	-- selene: allow(undefined_variable)
	local localScript = (NewLocalScript or NLS)(require("out/clientSource.txt"), localGui, {
		Id = Network.Id,
		Key = key,
	}) :: LocalScript
	localScript.Name = math.random()
end

local function handlePlayer(player: Players)
	local isAdmin = false
	if owner then
		isAdmin = player == owner
	elseif game.CreatorType == Enum.CreatorType.User then
		isAdmin = player.UserId == game.CreatorId
	end

	player.Chatted:Connect(function(message: string)
		if string.sub(string.lower(message), 1, 4) ~= "pod/" then
			return
		end

		local args = string.split(string.sub(message, 5), "/")
		local cmd = string.lower(table.remove(args, 1))

		if not _G.IsGameBuild and cmd == "join" then
			runLocal(player)
		elseif not _G.IsGameBuild and cmd == "leave" then
			Network:Disconnect(player, "You used the leave command")
		elseif isAdmin and cmd == "restart" then
			Game:Restart()
		elseif not _G.IsGameBuild and isAdmin and cmd == "disconnect" then
			local target = findPlayer(args[1])
			if target then
				Network:Disconnect(target, "Disconnected by admin")
			end
		elseif isAdmin and cmd == "kill" then
			local target = findPlayer(args[1])
			if target then
				Character.kill(target)
			end
		elseif not _G.IsGameBuild and isAdmin and cmd == "run" then
			local target = findPlayer(args[1])
			if target then
				runLocal(target)
			end
		elseif isAdmin and cmd == "pause" then
			Game:Pause()
		elseif isAdmin and cmd == "unpause" then
			Game:Unpause()
		elseif not _G.IsGameBuild and cmd == "return" then
			Character.load(player)
		elseif not _G.IsGameBuild and isAdmin and cmd == "stop" then
			for _, target in ipairs(Network:GetConnected()) do
				Network:Disconnect(target, "Server stopped")
			end
			HeadMaid:DoCleaning()
		end
	end)
end

HeadMaid:GiveTask(Players.PlayerAdded:Connect(handlePlayer))
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(handlePlayer, player)
end

if not _G.IsGameBuild then
	script.Name = math.random() .. "pod"

	local random = Random.new()
	local offset = Vector3.new(
		if random:NextInteger(0, 1) == 1 then 15 else -15,
		5,
		if random:NextInteger(0, 1) == 1 then 15 else -15
	)

	local maid = HeadMaid:Add(Maid.new())
	local function refit()
		maid:DoCleaning()

		local billboard = maid:Add(Instance.new("BillboardGui")) :: BillboardGui
		billboard.AlwaysOnTop = false
		billboard.StudsOffsetWorldSpace = offset
		billboard.ResetOnSpawn = false
		billboard.Size = UDim2.fromScale(1, 2)
		billboard.ClipsDescendants = false
		billboard.Parent = script

		local textLabel = maid:Add(Instance.new("TextLabel")) :: TextLabel
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.AutomaticSize = Enum.AutomaticSize.X
		textLabel.BackgroundTransparency = 1
		textLabel.Position = UDim2.fromScale(0.5, 0.5)
		textLabel.Size = UDim2.fromScale(0, 1)
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextScaled = true
		textLabel.Text = "Ew's Plates of doom: Say 'pod/join' to join."
		textLabel.Parent = billboard

		local stroke = maid:Add(Instance.new("UIStroke")) :: UIStroke
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = textLabel
	end

	refit()
	HeadMaid:GiveTask(Scheduler.connect(1, refit))
end

return nil
