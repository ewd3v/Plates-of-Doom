local Team = require("shared/team")

return table.freeze({
	[Team.Playing] = {
		TeamName = "Playing",
		TeamColor = BrickColor.new(Color3.fromRGB(212, 44, 44)),
	},
	[Team.Lobby] = {
		TeamName = "Lobby",
		TeamColor = BrickColor.new(Color3.fromRGB(112, 113, 116)),
	},
})
