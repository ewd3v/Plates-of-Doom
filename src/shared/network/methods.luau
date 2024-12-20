local Enum = require("shared/enum")

return table.freeze({
	Server = Enum({
		"Connect",
		"Event",
		"Invoke",
	}),
	Client = Enum({
		"ConnectResult",
		"Event",
		"InvokeResult",
	}),
})
