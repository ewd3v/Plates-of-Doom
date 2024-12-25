local Teams = require("server/teams")
local Team = require("shared/team")
local Network = require("server/network")

local Match = {}

function Match:GetPlaying(): { Player }
	return Teams:GetPlayers(Team.Playing)
end

function Match:GetAmountPlaying()
	return Teams:GetAmount(Team.Playing)
end

function Match:IsPlaying(player: Player)
	return Teams:Get(player) == Team.Playing
end

function Match:AssignAll(team: Teams.team)
	for _, player in ipairs(Network:GetConnected()) do
		Teams:Assign(player, team)
	end
end

function Match:AddPlayer(player: Player)
	Teams:Assign(player, Team.Playing)
end

function Match:RemovePlayer(player: Player)
	if Network:IsConnected(player) then
		Teams:Assign(player, Team.Lobby)
	else
		Teams:Assign(player, nil)
	end
end

return Match
