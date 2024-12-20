local lobbyCreator = require("./lobbyCreator")

local Arena = {}
Arena.Origin = Vector3.zero
Arena.Size = 0
Arena.Lobby = nil :: Model?

function Arena:SetOrigin(origin: Vector3)
	Arena.Origin = origin
end

function Arena:SetSize(size: number)
	Arena.Size = size
end

function Arena:ConstructLobby()
	Arena:RemoveLobby()

	local lobby = lobbyCreator(Arena.Origin, Arena.Size)
	Arena.Lobby = lobby

	lobby.Parent = workspace
end

function Arena:RemoveLobby()
	if not Arena.Lobby then
		return
	end

	Arena.Lobby:Destroy()
	Arena.MLobbyodel = nil
end

return Arena
