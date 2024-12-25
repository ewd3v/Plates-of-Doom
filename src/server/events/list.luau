local RunService = game:GetService("RunService")
local Character = require("server/character")
local Plates = require("server/plates")
local Arena = require("server/arena")
local Maid = require("shared/maid")
local Scheduler = require("shared/scheduler")

local Selector = require("./selector")

local random = Random.new()
local function randomBoolean(): boolean
	return random:NextInteger(0, 1) == 1
end

local function get2RandomPlates(): (Plates.Plate?, Plates.Plate?)
	local availablePlates = table.clone(Plates:GetPlates())
	if #availablePlates < 2 then
		return nil, nil
	end

	local plate1Index = random:NextInteger(1, #availablePlates)
	local plate2Index = random:NextInteger(1, #availablePlates - 1)

	return table.remove(availablePlates, plate1Index), availablePlates[plate2Index]
end

return table.freeze({
	--[[{
		1, -- Weight of the event, i.e chances of it getting run (higher is more likely).
		function() -- The Init function, 1st arg is the event to display, the rest will be sent to the Selector and Run function
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will do something`, targets
		end,
		function(targets: number) -- The Selector function, returns how many things to select, and what. It gets sent all args passed by the Init function.
			-- 3rd argument is if by default the game should "show" what players got selected, if you set it to false you have to do it manually
			-- Setting 4th argument to true will run the Run function with all selected players & plates at the same time (read context.Players & context.Plates).
			return targets, Selector.Plate
		end,
		function(context) -- The Run function, 1st arg is always "context", and the rest are args passed from the Init function.
			-- context.Player -- The player that got selected
			-- context.Plate -- The plate that got selected (note: Plate.Owners may be empty or have multiple owners)
			-- context.Players -- All selected players (as of running, not future selected players)
			-- context.Plates -- All selected plates (as of running, not future selected plates)
			-- context.Amount -- The amount that was selected (if you want to get it this way)
			-- context.Selector -- The type of selector used
			-- context.Event -- The event object for our data, Event.Data is referring to this event table
			-- context.Status -- The status displayed by the Init function
			-- context.ShowSelected -- 3rd argument by the Selector function
			-- context.CombineSelected -- 4th argument by the Selector function
		end,

		-- The Init and Selector function doesn't have to be a function, if it always returns static things you may just make it an array with all the return args.
		-- It is also possible to set the Init and Selector function to any value (other than a table),
		-- in which case it will act the first argument (only really viable in the Init function, as the Selector has to return at minimum 2 things).
	},]]

	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will return to normal`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			context.Plate:Reset()
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} players(s) will return to normal`, targets
		end,
		function(targets: number)
			return targets, Selector.Player
		end,
		function(context)
			Character.refresh(context.Player)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 3)
			local amount = random:NextInteger(2, 6)

			return `{targets} plate(s) will grow by {amount} studs`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context, _, amount: number)
			context.Plate:Grow(amount)
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 3)
			local amount = random:NextInteger(2, 6)

			return `{targets} plate(s) will shrink by {amount} studs`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context, _, amount: number)
			context.Plate:Shrink(amount)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 3)

			return `{targets} plate(s) will change color`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			context.Plate.Part.Color = Color3.new(random:NextNumber(), random:NextNumber(), random:NextNumber())
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 3)

			return `{targets} plate(s) will change material`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local materials = {
				Enum.Material.Brick,
				Enum.Material.Cobblestone,
				Enum.Material.Concrete,
				Enum.Material.CorrodedMetal,
				Enum.Material.DiamondPlate,
				Enum.Material.Fabric,
				Enum.Material.Foil,
				Enum.Material.ForceField,
				Enum.Material.Glass,
				Enum.Material.Granite,
				Enum.Material.Grass,
				Enum.Material.Ice,
				Enum.Material.Marble,
				Enum.Material.Metal,
				Enum.Material.Neon,
				Enum.Material.Pebble,
				Enum.Material.Plastic,
				Enum.Material.Sand,
				Enum.Material.Slate,
				Enum.Material.SmoothPlastic,
				Enum.Material.Wood,
				Enum.Material.WoodPlanks,
			}

			context.Plate.Part.Material = materials[random:NextInteger(1, #materials)]
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 3)

			return `{targets} plate(s) will become a disco plate`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local part = context.Plate.Part

			context.Plate.PartMaid.DiscoThread = task.defer(function()
				while true do
					part.Color = Color3.new(random:NextNumber(), random:NextNumber(), random:NextNumber())
					task.wait(0.5)
				end
			end)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 2)
			local amount = random:NextInteger(10, 25)

			return `{targets} plate(s) will ascend {amount} studs`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context, _, amount)
			context.Plate.Move += Vector3.yAxis * amount
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)
			local amount = random:NextInteger(10, 25)

			return `{targets} plate(s) will descend {amount} studs`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context, _, amount)
			context.Plate.Move -= Vector3.yAxis * amount
		end,
	},
	{
		1,
		function()
			return `1 plate will return to normal height`
		end,
		function()
			return 1, Selector.Plate
		end,
		function(context)
			context.Plate:MoveTo(context.Plate.Part.Position * Vector3.new(1, 0, 1) + Vector3.yAxis * Arena.Origin.Y)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will be split in half`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local plate = context.Plate
			local half = Plates.from(plate)

			if #plate.Owners > 1 then
				local owners = plate.Owners
				local transferAmount = math.floor(#owners / 2)

				-- Remove half of all players from the main plate
				for _ = 1, transferAmount do
					local owner = owners[#owners]
					plate:RemoveOwner(owner)
				end

				-- Then remove the remaining players of the main plate from the half
				for _, owner in ipairs(plate.Owners) do
					half:RemoveOwner(owner)
				end
			end

			local splitX = randomBoolean()

			local size = plate.Part.Size
			local cframe = plate.CFrame

			plate.Part.Size = if splitX
				then Vector3.new(size.X / 2, size.Y, size.Z)
				else Vector3.new(size.X, size.Y, size.Z / 2)
			half.Part.Size = plate.Part.Size

			plate:SetCFrame(cframe * if splitX then CFrame.new(size.X / 4, 0, 0) else CFrame.new(0, 0, size.Z / 4))
			half:SetCFrame(cframe * if splitX then CFrame.new(-size.X / 4, 0, 0) else CFrame.new(0, 0, -size.Z / 4))

			context:Highlight(half.Part)
		end,
	},
	{
		1,
		"2 plates will merge together",
		nil,
		function(context)
			local plate1, plate2 = get2RandomPlates()
			if not plate1 or not plate2 then
				return
			end

			local plate1Position = plate1.Part.Position :: Vector3
			local plate2Position = plate2.Part.Position :: Vector3

			-- TODO: In the future we should calculate mergeOnX and plate1Positive by checking what side is actually closest
			local mergeOnX = randomBoolean()

			local plate1Positive = if mergeOnX
				then (plate1Position.X > plate2Position.X)
				else (plate1Position.Z > plate2Position.Z)
			-- TODO: Above doesn't take rotation in account (:Dot()?), but it's a good estimate.

			local maid = Maid.new()

			plate1.PartMaid.MergeMaid = maid
			plate2.PartMaid.MergeMaid = maid

			local function merge()
				plate1.PartMaid.MergeMaid = nil
				plate2.PartMaid.MergeMaid = nil
				maid:DoCleaning()

				local part1 = plate1.Part
				local part2 = plate2.Part

				local size1 = part1.Size
				local size2 = part2.Size

				local add = if mergeOnX
					then Vector3.new(size2.X, size1.Y - (size1.Y + size2.Y) / 2, size1.Z - (size1.Z + size2.Z) / 2)
					else Vector3.new(size1.X - (size1.X + size2.X) / 2, size1.Y - (size1.Y + size2.Y) / 2, size2.Z)

				plate1.Part.Size += add
				plate1:SetCFrame(plate1.CFrame * CFrame.new((if plate1Positive then -add else add) / 2))

				for _, owner in ipairs(plate2.Owners) do
					plate1:AddOwner(owner)
				end

				plate1.LinearVelocity = plate1.LinearVelocity:Lerp(plate2.LinearVelocity, 0.5)
				plate1.AngularVelocity = plate1.AngularVelocity:Lerp(plate2.AngularVelocity, 0.5)
				part1.Color = part1.Color:Lerp(part2.Color, 0.5)

				-- If both parts don't match in shape, then it's safest to just make it a block
				if plate1:GetShape() ~= plate2:GetShape() then
					plate1:SetShape(Enum.PartType.Block)
				end

				plate2:Destroy()
			end

			local function updateMove()
				local plate1Target = plate1:GetCFrameTarget() :: CFrame
				local plate2Target = plate2:GetCFrameTarget() :: CFrame

				local plate1Size = plate1.Part.Size :: Vector3
				local plate2Size = plate2.Part.Size :: Vector3

				local middle = plate1Target:Lerp(plate2Target, 0.5)

				local offset = if mergeOnX then (plate1Size.X + plate2Size.X) / 4 else (plate1Size.Z + plate2Size.Z) / 4
				local plate1Offset = if plate1Positive then offset else -offset
				local plate2Offset = if plate1Positive then -offset else offset

				plate1:CFrameTo(
					middle * if mergeOnX then CFrame.new(plate1Offset, 0, 0) else CFrame.new(0, 0, plate1Offset)
				)
				plate2:CFrameTo(
					middle * if mergeOnX then CFrame.new(plate2Offset, 0, 0) else CFrame.new(0, 0, plate2Offset)
				)

				local size1 = plate1:GetSizeTarget() :: Vector3
				local size2 = plate2:GetSizeTarget() :: Vector3

				plate1:SizeTo(
					if mergeOnX
						then Vector3.new(size1.X, (size1.Y + size2.Y) / 2, (size1.Z + size2.Z) / 2)
						else Vector3.new((size1.X + size2.X) / 2, (size1.Y + size2.Y) / 2, size1.Z)
				)
				plate2:SizeTo(
					if mergeOnX
						then Vector3.new(size2.X, (size1.Y + size2.Y) / 2, (size1.Z + size2.Z) / 2)
						else Vector3.new((size1.X + size2.X) / 2, (size1.Y + size2.Y) / 2, size2.Z)
				)
			end
			updateMove()

			maid.loop = Scheduler.connect(0.1, function()
				updateMove()

				local totalMagnitude = plate1.Move.Magnitude
					+ plate1.Rotate.Magnitude
					+ plate1.SizeChange.Magnitude
					+ plate2.Move.Magnitude
					+ plate2.Rotate.Magnitude
					+ plate2.SizeChange.Magnitude

				if totalMagnitude < 0.01 then
					merge()
				end
			end)

			context:ShowPlate(plate1)
			context:ShowPlate(plate2)
		end,
	},

	{
		1,
		"A bridge will be constructed between 2 plates",
		nil,
		function(context)
			local plate1, plate2 = get2RandomPlates()
			if not plate1 or not plate2 then
				return
			end

			local part1: Part = plate1.Part
			local part2: Part = plate2.Part

			local position1 = part1.Position + Vector3.yAxis * 1
			local position2 = part2.Position + Vector3.yAxis * 1

			local distance = (position1 - position2).Magnitude

			local bridge = Instance.new("Part")
			bridge.Anchored = false
			bridge.CanCollide = true
			bridge.Size = Vector3.new(5, distance, 0.75)
			bridge.CFrame = CFrame.lookAt(position1, position2)
				* CFrame.new(0, 0.6, -distance * 0.5)
				* CFrame.Angles(math.rad(90), 0, 0)

			bridge.Parent = Arena.Folder
			bridge:SetNetworkOwner(nil)

			context:ShowPlate(plate1)
			context:ShowPlate(plate2)
		end,
	},
	{
		1,
		"1 plate will recieve a ball",
		{ 1, Selector.Plate },
		function(context)
			local model = Instance.new("Model")

			local ball = Instance.new("Part")
			ball.Material = Enum.Material.SmoothPlastic
			ball.Size = Vector3.one * 5
			ball.Shape = Enum.PartType.Ball
			ball.Parent = model

			model.Parent = Arena.Folder
			model:MoveTo(context.Plate.Part.Position)
		end,
	},
	{
		1,
		"1 plate will get a laser spinner",
		{ 1, Selector.Plate },
		function(context)
			local plate = context.Plate
			local part = plate.Part

			local maid = plate.PartMaid:Add(Maid.new())

			local laser = maid:Add(Instance.new("Part"))
			laser.Anchored = true
			laser.CanCollide = false
			laser.Material = Enum.Material.Neon
			laser.Color = Color3.fromRGB(255, 0, 0)
			laser.Parent = part

			-- Give a 1 second grace period
			maid.TouchedThread = task.delay(1, function()
				maid.Touched = laser.Touched:Connect(function(hit)
					Character.damage(hit.Parent, 15)
				end)
			end)

			local rotationPerSec = 30
			local rotation = random:NextNumber(0, 360)
			maid.Loop = RunService.Heartbeat:Connect(function(dt)
				local maxSize = math.max(part.Size.X, part.Size.Z)
				laser.Size = Vector3.new((2 ^ 0.5) * maxSize, 1, 1)

				rotation += rotationPerSec * dt
				laser.CFrame = CFrame.new(part.Position + Vector3.yAxis * (part.Size.Y / 2 + 0.5))
					* CFrame.Angles(0, math.rad(rotation), 0)
			end)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will become a treadmill`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local speed = random:NextNumber(8, 12)
			local dir = random:NextInteger(1, 4)

			if dir == 1 then
				context.Plate.LinearVelocity += Vector3.new(speed, 0, 0)
			elseif dir == 2 then
				context.Plate.LinearVelocity -= Vector3.new(speed, 0, 0)
			elseif dir == 3 then
				context.Plate.LinearVelocity += Vector3.new(0, 0, speed)
			else
				context.Plate.LinearVelocity -= Vector3.new(0, 0, speed)
			end
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will become a trampoline`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local power = random:NextNumber(50, 80)
			context.Plate.LinearVelocity = Vector3.new(
				context.Plate.LinearVelocity.X,
				math.max(context.Plate.LinearVelocity.Y, power),
				context.Plate.LinearVelocity.Z
			)
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will become a cube`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local size = context.Plate:GetSizeTarget()
			local maxSize = math.max(size.X, size.Y, size.Z)

			context.Plate:SizeTo(Vector3.one * maxSize)
			context.Plate:SetShape(Enum.PartType.Block)
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will become a sphere`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local size = context.Plate:GetSizeTarget()
			local maxSize = math.max(size.X, size.Y, size.Z)

			context.Plate:SizeTo(Vector3.one * maxSize)
			context.Plate:SetShape(Enum.PartType.Ball)
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will become a cylinder`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			local size = context.Plate:GetSizeTarget()
			local maxSize = math.max(size.X, size.Z)

			context.Plate:SizeTo(Vector3.new(maxSize, size.Y, maxSize))
			context.Plate:SetShape(Enum.PartType.Cylinder)
		end,
	},

	{
		991,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will flip`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			context.Plate.Rotate += if randomBoolean() then Vector3.new(180, 0, 0) else Vector3.new(0, 0, 180)
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will rotate`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			context.Plate.Rotate += Vector3.new(0, (if randomBoolean() then 90 else -90) * random:NextNumber(2, 4), 0)
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 2)

			return `{targets} plate(s) will move`, targets
		end,
		function(targets: number)
			return targets, Selector.Plate
		end,
		function(context)
			-- Will probably favor going diagonally more
			local direction = Vector3.new(random:NextNumber(-1, 1), 0, random:NextNumber(-1, 1)).Unit
			local distance = random:NextNumber(15, 30)

			context.Plate.Move += direction * distance
		end,
	},

	{
		1,
		function()
			local targets = random:NextInteger(1, 3)
			local amount = random:NextInteger(3, 7)

			return `{targets} player(s) will gain {amount} walkspeed`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Player
		end,
		function(context, _, amount: number)
			local humanoid = Character.getHumanoid(context.Player) :: Humanoid
			if humanoid then
				humanoid.WalkSpeed += amount
			end
		end,
	},
	{
		1,
		function()
			local targets = random:NextInteger(1, 3)
			local amount = random:NextInteger(3, 7)

			return `{targets} player(s) will lose {amount} walkspeed`, targets, amount
		end,
		function(targets: number)
			return targets, Selector.Player
		end,
		function(context, _, amount: number)
			local humanoid = Character.getHumanoid(context.Player) :: Humanoid
			if humanoid then
				humanoid.WalkSpeed -= amount
			end
		end,
	},
})
