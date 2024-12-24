local Status = require("server/status")
local Network = require("server/network")
local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Teams = require("server/teams")
local Team = require("shared/team")
local Arena = require("server/arena")
local Plates = require("server/plates")
local Character = require("server/character")
local Events = require("server/events")
local EventSelector = require("server/events/selector")
local Functions = require("shared/functions")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Game = {}
Game.HeadMaid = HeadMaid:Add(Maid.new())
Game.Maid = Game.HeadMaid:Add(Maid.new())

local function assignAllTeam(team)
	for _, player in ipairs(Network:GetConnected()) do
		Teams:Assign(player, team)
	end
end

function Game:GetPlaying(): { Player }
	return Teams:GetPlayers(Team.Playing)
end

function Game:GetAmountPlaying()
	return Teams:GetAmount(Team.Playing)
end

function Game:Intermission()
	local duration = if RunService:IsStudio() then 5 else 15
	local playersNeeded = if RunService:IsStudio() then 1 else 2

	local function hasPlayers(): boolean
		return #Network:GetConnected() >= playersNeeded
	end

	while true do
		if not hasPlayers() then
			Status(`Waiting for {playersNeeded - #Network:GetConnected()} more player(s)...`)
			task.wait()

			continue
		end

		for left = duration, 1, -1 do
			if not hasPlayers() then
				-- Break loop early and restart if players leave
				break
			end

			Status(`Intermission - {left}`)
			task.wait(1)
		end

		if hasPlayers() then
			break
		end
	end
end

function Game:StartGame()
	Status("Starting game...")

	assignAllTeam(Team.Playing)

	local playerAmount = Game:GetAmountPlaying()
	for _, player in ipairs(Game:GetPlaying()) do
		Character.remove(player)
	end

	-- Setup arena & spawn plates
	local plateSize = math.max(Plates.DefaultPlateSize.X, Plates.DefaultPlateSize.Z)
	local gap = 5

	local gridSize = math.ceil(math.sqrt(playerAmount + 5)) -- The + 5 in turn basically allows for some empty to guaranteed
	Arena:SetSize((plateSize + gap) * (gridSize + 1))
	Arena:Create()

	Plates:ClearAll()

	local random = Random.new()
	local takenSpots: { [string]: true } = {}
	local gridMax = gridSize - 1 -- Coordinates starts at 0

	for _, player in ipairs(Game:GetPlaying()) do
		if player.Parent ~= Players then
			continue
		end

		local x: number
		local z: number

		while true do
			x, z = random:NextInteger(0, gridMax), random:NextInteger(0, gridMax)

			local coordinate = `{x},{z}`
			if takenSpots[coordinate] then
				continue
			end

			takenSpots[coordinate] = true
			break
		end

		local plate = Plates.new(player)
		plate:MoveTo(Arena.Origin + Vector3.new(x - gridMax / 2, 0, z - gridMax / 2) * (plateSize + gap))

		while not Character.load(player) do
			task.wait()
		end

		while not Character.getRoot(player) or not player.Character:IsDescendantOf(workspace) do
			task.wait()
		end

		Character.freeze(player)
		plate:Bring(player)

		-- Move player up in air by 3 studs (by default just standing on the plate)
		local root = Character.getRoot(player)
		if root then
			Character.teleport(player, root.Position + Vector3.yAxis * 3)
		end
	end

	task.wait(3)

	for _, player in ipairs(Game:GetPlaying()) do
		Character.unfreeze(player)
	end

	task.wait(1)
end

local eventContext = {}
eventContext.__index = eventContext

function eventContext:Show(name: string, instance: Instance)
	-- 6380285152 sfx
	table.insert(self.Names, name)
	Status(`{self.Status} - {table.concat(self.Names, " ")}`)
end

function Game:RunEvent(possibleEvents)
	local event = Events:Get(possibleEvents)
	assert(event, "Unable to find an event!")

	local args = table.pack(event:Init())

	local status = args[1]
	for left = 5, 0, -0.1 do
		Status(`{status} - {math.round(left * 10) / 10}`)
		task.wait(0.1)
	end

	local amount, selector, showSelected = event:Selector(unpack(args, 2, args.n))
	amount = amount or 1
	selector = selector or EventSelector.None
	showSelected = showSelected or true

	local context = setmetatable({}, eventContext)
	context.Event = event
	context.Status = status
	context.Names = {}
	context.Amount = amount
	context.Selector = selector
	context.ShowSelected = showSelected

	for index = 1, amount do
		context.Player = nil
		context.Plate = nil

		local random = Random.new()
		if selector == EventSelector.Player then
			local playing = Game:GetPlaying()
			context.Player = playing[random:NextInteger(1, #playing)]
		elseif selector == EventSelector.Plate then
			local plates = Plates:GetPlates()
			context.Plate = plates[random:NextInteger(1, #plates)]
		end

		event:Run(context, unpack(args, 2, args.n))

		if showSelected then
			if selector == EventSelector.Player then
				context:Show(Functions.formatPlayerName(context.Player), context.Player.Character)
			elseif selector == EventSelector.Plate then
				context:Show(Functions.formatPlateOwnerName(context.Plate.Owners), context.Plate.Part)
			end
		end

		if index ~= amount then
			task.wait(1)
		end
	end

	task.wait(3)
end

function Game:EndGame()
	for _, player in ipairs(Game:GetPlaying()) do
		Character.freeze(player)
		task.defer(Character.load, player)

		Teams:Assign(player, Team.Lobby)
	end
end

function Game:RunCycle()
	assignAllTeam(Team.Lobby)
	Plates:ClearAll()
	Arena:Remove()

	Game:Intermission()
	Game:StartGame()

	local possibleEvents = Events:GetPossible(Game)
	while Game:GetAmountPlaying() > (if RunService:IsStudio() then 0 else 1) do
		Game:RunEvent(possibleEvents)
	end

	Game:EndGame()

	task.wait(2)
end

function Game:PlayerDied(player: Player)
	if Network:IsConnected(player) then
		Teams:Assign(player, Team.Lobby)
	end

	Plates:PlayerDied(player)
end

function Game:Init()
	Game.HeadMaid.GameLoop = task.defer(function()
		while true do
			local success, err = pcall(function()
				Game.Maid:DoCleaning()
				Game:RunCycle()

				Status("Game cycle end")
				task.wait(1)
			end)

			if success then
				continue
			end

			Status("An unexpected error occured!")
			warn(err)

			task.wait(5)
		end
	end)

	local playerMaid = Game.HeadMaid:Add(Maid.new())
	Game.HeadMaid.PlayerConnected = Network.Connected:Connect(function(player)
		Teams:Assign(player, Team.Lobby)

		local maid = Maid.new()
		playerMaid[player] = maid

		maid.CharacterAdded = player.CharacterAdded:Connect(function(character)
			local humanoid
			while true do
				humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					break
				end

				task.wait()
			end

			humanoid.Died:Connect(function()
				Game:PlayerDied(player)
			end)
		end)
	end)

	Game.HeadMaid.PlayerDisconnected = Network.Disconnected:Connect(function(player)
		playerMaid[player] = nil
		Game:PlayerDied(player)
	end)
end

return Game
