local Assets = {
	Server = nil :: Folder?,
	Client = nil :: Folder?,
	Shared = nil :: Folder,
}

Assets.Shared = require("assets/shared")
if game:GetService("RunService"):IsServer() then
	Assets.Server = require("assets/server")
else
	Assets.Client = require("assets/client")
end

return table.freeze(Assets)
