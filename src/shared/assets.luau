local Assets = {
	Server = nil :: Folder?,
	Client = nil :: Folder?,
	Shared = nil :: Folder,
}

if _G.IsGameBuild then
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")

	if RunService:IsServer() then
		Assets.Server = ServerStorage:WaitForChild("Assets")
	else
		Assets.Client = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Client")
	end

	Assets.Shared = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shared")
else
	-- TODO: Support LoadAssets (and somehow send client them)
	warn("SB Build's dont have assets yet.")
	Assets.Server = Instance.new("Folder")
	Assets.Client = Instance.new("Folder")
	Assets.Shared = Instance.new("Folder")
end

return table.freeze(Assets)
