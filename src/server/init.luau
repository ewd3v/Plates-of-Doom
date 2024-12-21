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

local fallenPartsDestroyHeight = -100
local yPosition = workspace.FallenPartsDestroyHeight - fallenPartsDestroyHeight

if _G.IsGameBuild then
	Arena:SetOrigin(Vector3.new(0, yPosition, 0))
else
	-- Move to a random location if an sb script
	local random = Random.new()
	local x, xNegative = random:NextNumber(25_000, 100_000), random:NextInteger(0, 1) == 1
	local z, zNegative = random:NextNumber(25_000, 100_000), random:NextInteger(0, 1) == 1

	Arena:SetOrigin(Vector3.new(if xNegative then -x else x, yPosition, if zNegative then -z else z))
end

Arena:SetSize(100)
Arena:SetLavaHeight(fallenPartsDestroyHeight)
Arena:CreateLobby()

Game:Init()
