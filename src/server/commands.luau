local HeadMaid = require("shared/headMaid")
local Network = require("server/network")

local Players = game:GetService("Players")

-- selene: allow(undefined_variable)
local owner = owner

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

		if not _G.IsGameBuild then
			if cmd == "join" then
				local localGui = Instance.new("ScreenGui")
				localGui.ResetOnSpawn = false
				localGui.Name = math.random()
				localGui.Parent = player:FindFirstChildOfClass("PlayerGui")

				local key = Network:GenerateKey()
				Network:SetKey(player, key);

				-- selene: allow(undefined_variable)
				(NewLocalScript or NLS)(require("out/clientSource.txt"), localGui, {
					Id = Network.Id,
					Key = key,
				}).Name =
					math.random()

				return
			elseif cmd == "leave" then
				Network:Disconnect(player, "You used the leave command")
			end
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
