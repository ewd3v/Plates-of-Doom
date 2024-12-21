local Network = require("client/network")
local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Signal = require("shared/signal")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeamsService = game:GetService("Teams")

type team = any

local TeamList = require("shared/team/list") :: {
	[team]: {
		TeamName: string,
		TeamColor: BrickColor,
	},
}

local Teams = {}
Teams.Maid = HeadMaid:Add(Maid.new())
Teams.TeamMaid = Teams.Maid:Add(Maid.new())
Teams.TeamChanged = Teams.Maid:Add(Signal.new())
Teams.List = {} :: { [Player]: team }

function Teams:Update(list: { [Player]: team })
	table.clear(Teams.List)

	for userId, team in list do
		local player = Players:GetPlayerByUserId(tonumber(userId))
		if not player then
			continue
		end

		if player == Players.LocalPlayer and team ~= Teams.List[player] then
			Teams.TeamChanged:FireDeferred(team)
		end

		Teams.List[player] = team
	end
end

Network.event("UpdateTeams", function(list)
	Teams:Update(list)
end)

task.spawn(function()
	Teams:Update(Network:InvokeServer("GetTeams"))
end)

function Teams:Get(player: Player?): team?
	return Teams.List[player or Players.LocalPlayer]
end

function Teams:Init()
	Teams.Maid.RenderStepped = RunService.RenderStepped:Connect(function()
		local amounts: { [team]: number } = {}
		for _, teamId in Teams.List do
			amounts[teamId] = (amounts[teamId] or 0) + 1
		end

		for teamId, data in TeamList do
			local team = Teams.TeamMaid[teamId]
			if not team or team.Parent ~= TeamsService then
				team = Instance.new("Team")
				Teams.TeamMaid[teamId] = team
			end

			team.AutoAssignable = false
			team.Name = `{data.TeamName} ({amounts[teamId] or 0})`
			team.TeamColor = data.TeamColor
			team.Parent = TeamsService
		end

		for player, teamId in Teams.List do
			local team = Teams.TeamMaid[teamId]

			if player == Players.LocalPlayer and team ~= player.Team then
				-- Prevent the player number from showing up in the chat (by quickly renaming it to the real name)
				local oldName = team.Name
				team.Name = TeamList[teamId].TeamName

				player.Team = team
				team.Name = oldName
			else
				player.Team = team
			end
		end
	end)
end

return Teams
