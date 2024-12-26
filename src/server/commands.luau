local HeadMaid = require("shared/headMaid")
local Network = require("server/network")
local Game = require("server/game")
local Character = require("server/character")

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
		end
	end)
end

HeadMaid:GiveTask(Players.PlayerAdded:Connect(handlePlayer))
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(handlePlayer, player)
end

if not _G.IsGameBuild then
	local joinHint = Instance.new("Hint")
	joinHint.Text = "Ew's Plates of Doom loaded! Say 'pod/join' to join."
	joinHint.Parent = workspace

	task.delay(10, game.Destroy, joinHint)
end

return nil
