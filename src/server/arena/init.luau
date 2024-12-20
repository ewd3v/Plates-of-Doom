local HeadMaid = require("shared/headMaid")
local Maid = require("shared/Maid")

local lobbyCreator = require("./lobbyCreator")

local Arena = {}
Arena.Maid = HeadMaid:Add(Maid.new())
Arena.Origin = Vector3.zero
Arena.Size = 0

function Arena:SetOrigin(origin: Vector3)
	Arena.Origin = origin
end

function Arena:SetSize(size: number)
	Arena.Size = size
end

function Arena:ConstructLobby()
	local lobby = lobbyCreator(Arena.Origin, Arena.Size)
	Arena.Maid.Lobby = lobby

	lobby.Parent = workspace
end

function Arena:RemoveLobby()
	Arena.Maid.Lobby = nil
end

return Arena
