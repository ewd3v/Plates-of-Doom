local Network = require("server/network")

local Status = {}
Status.Current = "..."

Network.invoke("GetStatus", function()
	return Status.Current
end)

function Status:Set(text: string)
	Status.Current = text
	Network:FireAllClients("SetStatus", text)
end

return Status
