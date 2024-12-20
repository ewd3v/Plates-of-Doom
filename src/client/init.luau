local Network = require("client/network")

if not _G.IsGameBuild then
	-- selene: allow(undefined_variable)
	local network = ...
	Network:SetId(network.Id)
	Network:SetKey(network.Key)
end

-- Check if it failed to connect (meaning we're not the correct client, so we should quit)
if not Network:Init() then
	-- TODO: Cleanup system
	Network:Destroy()
	return
end

local Assets = require("shared/assets")
