local HeadMaid = require("shared/headMaid")
local Maid = require("shared/Maid")
local Network = require("server/network")

local lobbyCreator = require("./lobbyCreator")

local Arena = {}
Arena.Maid = HeadMaid:Add(Maid.new())
Arena.ArenaMaid = Arena.Maid:Add(Maid.new())
Arena.Folder = nil :: Folder?
Arena.Lobby = nil :: Folder?
Arena.Wall = nil :: Part?
Arena.Origin = Vector3.zero
Arena.Size = 0
Arena.LavaHeight = -100

local root = if _G.IsGameBuild then workspace else script
if not _G.IsGameBuild and script.Parent ~= workspace then
	task.defer(function()
		script.Parent = workspace
	end)
end

local maxPartSize = 2048
local function createWall(position: Vector3?, size: Vector3): Part
	local wall = Arena.Maid.Lobby:Add(Instance.new("Part")) :: Part
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

	arena.Parent = root
end

function Arena:Remove()
	Arena.ArenaMaid:DoCleaning()
end

function Arena:CreateLobby()
	local origin, size = Arena.Origin, Arena.Size

	local maid = Maid.new()
	Arena.Maid.Lobby = maid

	Arena.Lobby = lobbyCreator(origin, size, Arena.LavaHeight)
	Arena.Lobby.Parent = root

	maid.Lobby = Arena.Lobby

	local height = maxPartSize
	Arena.Wall = createWall(origin, Vector3.new(size + 10, height, size + 10)) -- 5 * 2 = 10; 5 is the gap between arena
	do
		local width = maxPartSize / 3 -- Width of walls

		local offset = size / 2 + width / 2 + 5 + 24
		local xOffset = Vector3.xAxis * offset
		local zOffset = Vector3.zAxis * offset

		createWall(origin + xOffset, Vector3.new(width, height, width * 3))
		createWall(origin + zOffset, Vector3.new(width * 3, height, width))
		createWall(origin - xOffset, Vector3.new(width, height, width * 3))
		createWall(origin - zOffset, Vector3.new(width * 3, height, width))
	end

	Network:FireAllClients("SetArenaLobby", Arena.Lobby)
end

local function removeCollision(part: BasePart | Instance)
	if not part:IsA("BasePart") then
		return
	end

	local noCollisionConstraint = Instance.new("NoCollisionConstraint")
	noCollisionConstraint.Part0 = part
	noCollisionConstraint.Part1 = Arena.Wall
	noCollisionConstraint.Parent = part
end

function Arena:Allow(instance: Instance)
	removeCollision(instance)
	instance.DescendantAdded:Connect(removeCollision)
	for _, descendant in ipairs(instance:GetDescendants()) do
		removeCollision(descendant)
	end
end

function Arena.moveTo(model: Model, position: Vector3)
	local wall = Arena.Wall
	if not wall then
		return model:MoveTo(position)
	end

	wall.CanCollide = false
	model:MoveTo(position)
	wall.CanCollide = true
end

Network.invoke("GetArenaSettings", function()
	return Arena.Origin, Arena.Size, Arena.Lobby
end)

return Arena
