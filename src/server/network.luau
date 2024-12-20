local Maid = require("shared/maid")
local Signal = require("shared/signal")
local Scheduler = require("shared/scheduler")
local HeadMaid = require("shared/headMaid")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Methods = require("shared/network/methods")

type Key = { Server: string, Client: string }

local Network = {}
Network.Maid = HeadMaid:Add(Maid.new())
Network.Id = require("shared/network/defaultId")
Network.Connected = Network.Maid:Add(Signal.new()) :: Signal.Signal<Player>
Network.Disconnected = Network.Maid:Add(Signal.new()) :: Signal.Signal<Player>
Network.ConnectedPlayers = {} :: { [Player]: number } -- Players that are "playing", the number is the last time they pinged
Network.ListeningPlayers = (if not _G.IsGameBuild then {} else nil) :: { [Player]: true } -- Players that are listening to the remote, used internally when outside game environment to make sure the real client is connected
Network.PlayerKeys = (if not _G.IsGameBuild then {} else nil) :: { [Player]: Key } -- Holds keys for players, only needed outside of game environment to provide a really basic anti-tamper and to easily let the client know it's supposed to run (in cases where 2 ran at the same time)
Network.Events = {} :: { [string]: (Player, ...any) -> () }
Network.Invokes = {} :: { [string]: (Player, ...any) -> () }

Network.Maid:GiveTask(function()
	table.clear(Network.ConnectedPlayers) -- Force the loop below to quit
end)

local function send(player: Player, method, ...)
	if _G.IsGameBuild then
		Network.Maid.Remote:FireClient(player, Network:GetKey(player), method, ...)
	else
		task.spawn(function(...)
			while true do
				if not Network.ConnectedPlayers[player] then
					return
				end

				if Network.ListeningPlayers[player] then
					break
				end

				task.wait()
			end

			Network.Maid.Remote:FireClient(player, Network:GetKey(player), method, ...)
		end, ...)
	end
end

function Network:SetId(id: string)
	Network.Id = id
end

function Network:GetConnected(): { Players }
	local connected = {}
	for player, _ in Network.ConnectedPlayers do
		table.insert(connected, player)
	end

	return connected
end

function Network:IsConnected(player: Player): boolean
	return Network.ConnectedPlayers[player] ~= nil
end

function Network:SetKey(player: Player, key: Key)
	if _G.IsGameBuild then
		return
	end

	Network.PlayerKeys[player] = key
end

function Network:GetKey(player: Player): string?
	if _G.IsGameBuild then
		return
	end

	local key = Network.PlayerKeys[player]
	return key and key.Client
end

function Network:GenerateKey(): Key
	if _G.IsGameBuild then
		return
	end

	return {
		Server = HttpService:GenerateGUID(false),
		Client = HttpService:GenerateGUID(false),
	}
end

function Network:Connect(player: Player)
	local wasConnected = Network:IsConnected(player)
	Network.ConnectedPlayers[player] = os.clock()

	if not _G.IsGameBuild then
		Network.ListeningPlayers[player] = true
	end

	if not wasConnected then
		Network.Connected:Fire(player)
	end
end

function Network:Disconnect(player: Player)
	if not Network:IsConnected(player) then
		return
	end

	Network.ConnectedPlayers[player] = nil
	if not _G.IsGameBuild then
		Network.ListeningPlayers[player] = nil
		Network.PlayerKeys[player] = nil
	end

	Network.Disconnected:Fire(player)
end

function Network:CreateRemote()
	if not _G.IsGameBuild then
		table.clear(Network.ListeningPlayers)
	end

	local remote = Instance.new("RemoteEvent")
	Network.Maid.Remote = remote

	remote.Name = Network.Id
	remote.Archivable = false
	remote.Parent = ReplicatedStorage

	remote.OnServerEvent:Connect(function(player, key: string, method, ...)
		if method == Methods.Server.Connect and not Network:IsConnected(player) then
			if not _G.IsGameBuild and (key == nil or key ~= Network.PlayerKeys[player].Server) then
				return remote:FireClient(player, Network:GetKey(player), Methods.Client.ConnectResult, false)
			end

			remote:FireClient(player, Network:GetKey(player), Methods.Client.ConnectResult, true)
			Network:Connect(player)

			return
		end

		if not _G.IsGameBuild then
			if key == nil or key ~= Network.PlayerKeys[player].Server then
				return
			end
		end

		Network:Connect(player)

		if method == Methods.Server.Event then
			local event = ...
			local callback = Network.Events[event]
			if callback then
				callback(player, select(2, ...))
			end
		elseif method == Methods.Server.Invoke then
			local invoke, id = ...
			local callback = Network.Invokes[invoke]
			if callback then
				send(player, Methods.Client.InvokeResult, id, callback(player, select(3, ...)))
			end
		end
	end)
end

function Network:IsRemoteOK(): boolean
	local remote = Network.Maid.Remote
	if not remote then
		return false
	end

	return remote.Parent == ReplicatedStorage and remote.Name == Network.Id
end

function Network:Init()
	Network:CreateRemote()

	-- These check's aren't neccesary in a game environment
	if not _G.IsGameBuild then
		-- Remake the remote at intervals to attempt to fix any unexpected removals
		Network.Maid.RefitLoop = Scheduler.connect(5, function()
			Network:CreateRemote()
		end)

		-- If the remote get's tampered with, remake it
		Network.Maid.RefitCheckLooop = RunService.PostSimulation:Connect(function()
			if not Network:IsRemoteOK() then
				Network:CreateRemote()
			end
		end)
	end

	Network.Maid.DisconnectLoop = Scheduler.connect(1, function()
		for player, lastPing in Network.ConnectedPlayers do
			if player.Parent ~= Players then
				Network:Disconnect(player)
				continue
			end

			if not _G.IsGameBuild and os.clock() - lastPing < 15 then
				Network:Disconnect(player)
				continue
			end
		end
	end)
end

function Network:FireClient(player: Player, event: string, ...)
	send(player, Methods.Client.Event, event, ...)
end

function Network:FireAllClients(event: string, ...)
	for player in Network.ConnectedPlayers do
		send(player, Methods.Client.Event, event, ...)
	end
end

function Network.event(name: string, callback: (Player, ...any) -> ())
	Network.Events[name] = callback
end

function Network.invoke(name: string, callback: (Player, ...any) -> ())
	Network.Invokes[name] = callback
end

return Network
