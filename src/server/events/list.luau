local Selector = require("./selector")

return table.freeze({
	{
		1,
		{ "This is a test event", "lol" },
		{ 1, Selector.Player },
		function(context, ...)
			print(context, ...)
		end,
	},
})
