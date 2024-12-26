local Network = require("server/network")

local Status = {}
Status.Current = "..."

Network.invoke("GetStatus", function()
	return Status.Current
end)

function Status:Set(text: string)
	if Status.Current == text then
		return
	end

	Status.Current = text
	Network:FireAllClients("SetStatus", text)
end

return setmetatable(Status, {
	__call = Status.Set,
})
