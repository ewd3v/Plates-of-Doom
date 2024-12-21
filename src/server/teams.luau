local Network = require("server/network")
local Maid = require("shared/maid")
local Signal = require("shared/signal")
local HeadMaid = require("shared/headMaid")

type team = any?

local Teams = {}
Teams.Maid = HeadMaid:Add(Maid.new())
Teams.List = {} :: { [Player]: team }
Teams.Updated = Teams.Maid:Add(Signal.new()) :: Signal.Signal<Player, team>

local function mapTeamsList(): table
	local mapped = {}
	for player, team in Teams.List do
		-- Keys must be tables when sent via remotes
		mapped[tostring(player.UserId)] = team
	end

	return mapped
end

Teams.Maid:GiveTask(Teams.Updated:Connect(function()
	-- Bulk send updates
	Teams.Maid.UpdateThread = task.defer(function()
		Network:FireAllClients("UpdateTeams", mapTeamsList())
	end)
end))

Network.invoke("GetTeams", function()
	return mapTeamsList()
end)

function Teams:Assign(player: Player, team: team)
	Teams.List[player] = team
	Teams.Updated:Fire(player, team)
end

function Teams:Get(player: Player): team?
	return Teams.List[player]
end

function Teams:GetPlayers(team: team)
	local players = {}
	for player, playerTeam in Teams.List do
		if playerTeam == team then
			table.insert(players, player)
		end
	end

	return players
end

function Teams:GetAmount(team: team): number
	return #Teams:GetPlayers(team)
end

return Teams
