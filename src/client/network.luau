local Maid = require("shared/maid")
local Signal = require("shared/signal")
local HeadMaid = require("shared/headMaid")

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Methods = require("shared/network/methods")

type Key = { Server: string, Client: string }

local Network = {}
Network.Maid = HeadMaid:Add(Maid.new())
Network.Id = require("shared/network/defaultId")
Network.Key = nil :: Key?
Network.ConnectResult = Network.Maid:Add(Signal.new()) :: Signal.Signal<boolean>
Network.InvokeResults = {} :: { [string]: Signal.Signal }
Network.Remotes = {} :: { RemoteEvent }
Network.Events = {} :: { [string]: (...any) -> () }

local alive = true
Network.Maid:GiveTask(function()
	alive = false
end)

local function send(method, ...)
	if _G.IsGameBuild then
		if Network.Remotes[1] then
			Network.Remotes[1]:FireServer(Network:GetKey(), method, ...)
		end
	else
		task.spawn(function(...)
			local remotes = Network.Remotes
			while true do
				if not alive then
					return
				end

				for index = #remotes, 1, -1 do
					local remote = remotes[index]
					if remote.Parent ~= ReplicatedStorage then
						table.remove(remotes, index)
					end
				end

				if #remotes > 0 then
					break
				end

				task.wait()
			end

			for _, remote in ipairs(remotes) do
				remote:FireServer(Network:GetKey(), method, ...)
			end
		end, ...)
	end
end

function Network:SetId(id: string)
	Network.Id = id
end

function Network:SetKey(key: Key?)
	Network.Key = key
end

function Network:GetKey(): string?
	return Network.Key and Network.Key.Server
end

local function handleRemote(remote: RemoteEvent)
	if remote.ClassName ~= "RemoteEvent" or remote.Name ~= Network.Id then
		return
	end

	remote:FireServer(Network:GetKey(), Methods.Server.Connect)
	remote.OnClientEvent:Connect(function(key: string, method, ...)
		if not _G.IsGameBuild and key ~= Network.Key.Client then
			return
		end

		if method == Methods.Client.ConnectResult then
			Network.ConnectResult:Fire(...)
		elseif method == Methods.Client.Event then
			local event = ...
			local callback = Network.Events[event]
			if callback then
				callback(select(2, ...))
			end
		elseif method == Methods.Client.InvokeResult then
			local id = ...

			local signal = Network.InvokeResults[id]
			if signal then
				Network.InvokeResults[id] = nil

				signal:Fire(select(2, ...))
				signal:Destroy()
			end
		end
	end)

	table.insert(Network.Remotes, remote)
end

function Network:Init(): boolean
	if _G.IsGameBuild then
		handleRemote(ReplicatedStorage:WaitForChild(Network.Id))
	else
		for _, child in ipairs(ReplicatedStorage:GetChildren()) do
			task.spawn(handleRemote, child)
		end

		Network.Maid.RemoteAdded = ReplicatedStorage.ChildAdded:Connect(handleRemote)
	end

	return Network.ConnectResult:Wait()
end

function Network:FireServer(event: string, ...)
	send(Methods.Server.Event, event, ...)
end

function Network:InvokeServer(invoke: string, ...)
	local id = HttpService:GenerateGUID(false)
	local signal = Signal.new()
	Network.InvokeResults[id] = signal

	send(Methods.Server.Invoke, invoke, id, ...)

	return signal:Wait()
end

function Network.event(name: string, callback: (...any) -> ())
	Network.Events[name] = callback
end

return Network
