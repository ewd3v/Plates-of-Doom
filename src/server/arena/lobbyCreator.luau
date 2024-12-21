return function(origin: Vector3, arenaSize: number, lavaHeight: number): Model
	local lobby = Instance.new("Folder")

	local function newPart(class: string?): BasePart
		local basePart = Instance.new(class or "Part")
		basePart.Anchored = true
		basePart.Material = Enum.Material.SmoothPlastic
		basePart.Parent = lobby

		return basePart
	end

	-- Corners
	do
		local function makeCorner(position: Vector3)
			local corner = newPart()
			corner.Color = Color3.fromRGB(103, 102, 104)
			corner.Size = Vector3.new(24, 1, 24)
			corner.Position = position

			local function createSpawn(x: number, z: number)
				local spawnPart = newPart(if _G.IsGameBuild then "SpawnLocation" else "Part")
				spawnPart.Size = Vector3.new(8, 0.5, 8)
				spawnPart.Position = position + Vector3.new(x, 0.75, z)
				spawnPart.Parent = lobby

				local decal = Instance.new("Decal")
				decal.Texture = "rbxasset://textures/SpawnLocation.png"
				decal.Face = Enum.NormalId.Top
				decal.Parent = spawnPart
			end

			createSpawn(5, 5)
			createSpawn(-5, 5)
			createSpawn(5, -5)
			createSpawn(-5, -5)
		end

		-- 24 / 2 = 12
		-- 12 + 5 = 17
		-- +5 is the gap between arena
		local offset = 17 + arenaSize / 2
		local xOffset = Vector3.xAxis * offset
		local zOffset = Vector3.zAxis * offset

		makeCorner(origin + xOffset + zOffset)
		makeCorner(origin - xOffset + zOffset)
		makeCorner(origin + xOffset - zOffset)
		makeCorner(origin - xOffset - zOffset)
	end

	-- Paths
	do
		local function makePath(position: Vector3, rotation: number)
			local flip = rotation % 180 ~= 0

			local path = newPart()
			path.Size = if flip then Vector3.new(24, 1, arenaSize + 10) else Vector3.new(arenaSize + 10, 1, 24)
			path.Position = position

			local speed1 = newPart()
			speed1.Color = Color3.fromRGB(127, 127, 130)
			speed1.Size = if flip then Vector3.new(6, 0.1, arenaSize + 4) else Vector3.new(arenaSize + 4, 0.1, 6) -- 5 * 2 - 3 * 2 = 4; 5 is the gap between arena, and 3 is the gap between the corners
			speed1.Position = position
				+ Vector3.new(0, 0.55, 0)
				+ if flip then Vector3.new(5, 0, 0) else Vector3.new(0, 0, 5)

			local speed2 = newPart()
			speed2.Color = speed1.Color
			speed2.Size = speed1.Size
			speed2.Position = position
				+ Vector3.new(0, 0.55, 0)
				+ if flip then Vector3.new(-5, 0, 0) else Vector3.new(0, 0, -5)

			local speed = 50
			speed1.AssemblyLinearVelocity = if flip then Vector3.new(0, 0, -speed) else Vector3.new(speed, 0, 0)
			speed2.AssemblyLinearVelocity = -speed1.AssemblyLinearVelocity
		end

		-- 24 / 2 = 12
		-- 12 + 5 = 17
		-- +5 is the gap between arena
		local offset = 17 + arenaSize / 2
		local xOffset = Vector3.xAxis * offset
		local zOffset = Vector3.zAxis * offset

		makePath(origin - zOffset, 0)
		makePath(origin - xOffset, 90)
		makePath(origin + zOffset, 180)
		makePath(origin + xOffset, 270)
	end

	-- Lava
	do
		local width = 5

		local lava = newPart()
		lava.CanCollide = false
		lava.Position = origin + Vector3.yAxis * (lavaHeight - width / 2)
		lava.Size = Vector3.new(arenaSize, width, arenaSize)
		lava.Material = Enum.Material.Neon
		lava.Color = Color3.fromRGB(211, 56, 17)
	end

	return lobby
end
