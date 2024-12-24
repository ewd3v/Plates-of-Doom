local Functions = {}

function Functions.formatPlayerName(player: Player): string
	if player.DisplayName == player.Name then
		return player.DisplayName
	end

	return `{player.DisplayName} (@{player.Name})`
end

function Functions.formatPlateOwnerName(owners: { Player }): string
	if #owners == 0 then
		return "No one"
	end

	local names = table.create(#owners)
	for index, player in ipairs(owners) do
		names[index] = Functions.formatPlayerName(player)
	end

	return table.concat(names, " + ")
end

return table.freeze(Functions)
