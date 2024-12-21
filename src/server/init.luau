local HeadMaid = require("shared/headMaid")
HeadMaid.Script = script

local Assets = require("shared/assets")
local Network = require("server/network")
local Arena = require("server/arena")
local Game = require("server/game")

if not _G.IsGameBuild then
	Network:SetId(game:GetService("HttpService"):GenerateGUID(false))
end

Network:Init()

if not _G.IsGameBuild then
	-- Move to a random location if an sb script
	local random = Random.new()
	local x, xNegative = random:NextNumber(25_000, 100_000), random:NextInteger(0, 1) == 1
	local z, zNegative = random:NextNumber(25_000, 100_000), random:NextInteger(0, 1) == 1

	Arena:SetOrigin(Vector3.new(if xNegative then -x else x, 0, if zNegative then -z else z))
end

Arena:SetSize(100)
Arena:CreateLobby()

Game:Init()
