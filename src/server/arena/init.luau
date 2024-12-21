local HeadMaid = require("shared/headMaid")
local Maid = require("shared/Maid")
local Network = require("server/network")

local lobbyCreator = require("./lobbyCreator")

local Arena = {}
Arena.Maid = HeadMaid:Add(Maid.new())
Arena.ArenaMaid = Arena.Maid:Add(Maid.new())
Arena.Folder = nil :: Folder?
Arena.Origin = Vector3.zero
Arena.Size = 0
Arena.LavaHeight = -100

function Arena:SetOrigin(origin: Vector3)
	Arena.Origin = origin
	Network:FireAllClients("SetArenaOrigin", origin)
end

function Arena:SetSize(size: number)
	Arena.Size = size
	Network:FireAllClients("SetArenaSize", size)
end

function Arena:SetLavaHeight(height: number)
	Arena.LavaHeight = height
end

function Arena:Create()
	Arena:Remove()
	Arena:CreateLobby()

	local arena = Arena.ArenaMaid:Add(Instance.new("Folder"))

	Arena.Folder = arena
	Arena.ArenaMaid:GiveTask(function()
		Arena.Arena = nil
	end)

	arena.Parent = workspace
end

function Arena:Remove()
	Arena.ArenaMaid:DoCleaning()
end

function Arena:CreateLobby()
	Arena.Maid.Lobby = lobbyCreator(Arena.Origin, Arena.Size, Arena.LavaHeight)
	Arena.Maid.Lobby.Parent = workspace

	Network:FireAllClients("SetArenaLobby", Arena.Maid.Lobby)
end

Network.invoke("GetArenaSettings", function()
	return Arena.Origin, Arena.Size, Arena.Maid.Lobby
end)

return Arena
