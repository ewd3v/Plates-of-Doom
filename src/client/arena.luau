local Network = require("client/network")
local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Teams = require("client/teams")
local Team = require("shared/team")

local Arena = {}
Arena.Maid = HeadMaid:Add(Maid.new())
Arena.Origin = Vector3.new(0, math.huge, 0)
Arena.Size = 0
Arena.Lobby = nil :: Folder?

function Arena:CreateWalls()
	local maid = Maid.new()
	Arena.Maid.Walls = maid

	local maxPartSize = 2048
	local height = maxPartSize
	local function createWall(position: Vector3?, size: Vector3): Part
		local wall = maid:Add(Instance.new("Part")) :: Part
		wall.Anchored = true
		wall.Transparency = 1

		if position then
			wall.Position = position
		end

		if size then
			wall.Size = size
		end

		wall.Parent = Arena.Lobby
		return wall
	end

	local origin = Arena.Origin
	local size = Arena.Size

	local currentTeam = Teams:Get()
	if currentTeam == Team.Lobby then
		createWall(origin, Vector3.new(size + 10, height, size + 10)) -- 5 * 2 = 10; 5 is the gap between arena
	elseif currentTeam == Team.Playing then
		local width = maxPartSize / 3 -- Width of walls

		local offset = size / 2 + width / 2
		local xOffset = Vector3.xAxis * offset
		local zOffset = Vector3.zAxis * offset

		createWall(origin + xOffset, Vector3.new(width, height, width * 3))
		createWall(origin + zOffset, Vector3.new(width * 3, height, width))
		createWall(origin - xOffset, Vector3.new(width, height, width * 3))
		createWall(origin - zOffset, Vector3.new(width * 3, height, width))
	end
end

task.spawn(function()
	local origin, size, lobby = Network:InvokeServer("GetArenaSettings")
	Arena.Origin = origin
	Arena.Size = size
	Arena.Lobby = lobby

	Arena:CreateWalls()
end)

Network.event("SetArenaOrigin", function(origin)
	Arena.Origin = origin
	Arena:CreateWalls()
end)

Network.event("SetArenaSize", function(size)
	Arena.Size = size
	Arena:CreateWalls()
end)

Network.event("SetArenaLobby", function(lobby)
	Arena.Lobby = lobby
	Arena:CreateWalls()
end)

Teams.TeamChanged:Connect(function()
	Arena:CreateWalls()
end)

function Arena:Init()
	Arena:CreateWalls()
end

return Arena
