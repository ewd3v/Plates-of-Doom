local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Arena = require("server/arena")
local Character = require("server/character")
local Assets = require("shared/assets")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Plate = {}
export type Plate = typeof(Plate.new())
export type PlatePart = MeshPart

local Plates = {}

-- @Plate
-- @Plate
-- @Plate
Plate.__index = Plate

function Plate.new(owner: (Player | { Player })?): Plate
	local self = setmetatable({}, Plate)
	self.Maid = Maid.new()
	self.Owners = if type(owner) == "table" then owner else { owner }
	self.Part = nil :: PlatePart?
	self.PartMaid = self.Maid:Add(Maid.new())
	self.CFrame = CFrame.identity
	self.Move = Vector3.zero
	self.Rotate = Vector3.zero
	self.SizeChange = Vector3.zero
	self.LinearVelocity = Vector3.zero
	self.AngularVelocity = Vector3.zero

	table.insert(Plates.List, self)
	self.Maid:GiveTask(function()
		local index = table.find(Plates.List, self)
		if index then
			table.remove(Plates.List, index)
		end
	end)

	self:Reset()
	return self
end

function Plate:Destroy()
	self.Maid:Destroy()
end

function Plate.from(plate: Plate): Plate
	local self = Plate.new(plate.Owners)
	self:Reset(plate.Part)

	return self
end

function Plate:UpdateTags()
	local part = self.Part
	part:SetAttribute("IsPlate", true)

	local userIds = {}
	for _, player in ipairs(self.Owners) do
		table.insert(userIds, player.UserId)
	end

	part:SetAttribute("Owners", table.concat(userIds, ","))
end

function Plate:Reset(clone: MeshPart?)
	self.PartMaid:DoCleaning()

	self.Move = Vector3.zero
	self.Rotate = Vector3.zero
	self.SizeChange = Vector3.zero
	self.LinearVelocity = Vector3.zero
	self.AngularVelocity = Vector3.zero

	local part = Instance.fromExisting(clone or Assets.Server.PlateMesh.Block)
	part.Name = "Plate"
	part.Anchored = true
	part.CFrame = self.CFrame
	part.Parent = assert(Arena.Folder, "No Arena exists yet.")

	self.Part = part
	if not clone then
		part.Material = Enum.Material.SmoothPlastic
		self:SetSize(Plates.DefaultPlateSize)
	end

	self.Maid.Removing = part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(Arena.Folder) then
			self:Destroy()
		end
	end)

	local minSize = 0.0011 -- Basically what you get if you set the size of a part to zero (i.e minimum size of parts), plus a little more to account for rounding errors
	self.PartMaid:GiveTask(part:GetPropertyChangedSignal("Size"):Connect(function()
		local aboveMinSize = 0

		if part.Size.X > minSize then
			aboveMinSize += 1
		end
		if part.Size.Y > minSize then
			aboveMinSize += 1
		end
		if part.Size.Z > minSize then
			aboveMinSize += 1
		end

		-- Part is collidable if at least 2 axis are above min size
		part.CanCollide = aboveMinSize >= 2
	end))

	local movePerSecond = 2.5
	local rotatePerSecond = 20
	local sizePerSecond = 3
	self.PartMaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero

		if self.Move ~= Vector3.zero then
			local move: Vector3

			local dtMove = movePerSecond * dt
			if self.Move.Magnitude < dtMove then
				move = self.Move
				self.Move = Vector3.zero
			else
				move = self.Move.Unit * dtMove
				self.Move -= move
			end

			part.Position += move
			--part.AssemblyLinearVelocity += move -- TODO: Fix?
		end

		if self.Rotate ~= Vector3.zero then
			local rotate: Vector3

			local dtRotate = rotatePerSecond * dt
			if self.Rotate.Magnitude < dtRotate then
				rotate = self.Rotate
				self.Rotate = Vector3.zero
			else
				rotate = self.Rotate.Unit * dtRotate
				self.Rotate -= rotate
			end

			part.Rotation += rotate
			--part.AssemblyAngularVelocity += rotate -- TODO: Fix?
		end

		if self.SizeChange ~= Vector3.zero then
			local size: Vector3

			local dtSize = sizePerSecond * dt
			if self.SizeChange.Magnitude < dtSize then
				size = self.SizeChange
				self.SizeChange = Vector3.zero
			else
				size = self.SizeChange.Unit * dtSize
				self.SizeChange -= size
			end

			part.Size += size
		end

		self.CFrame = part.CFrame

		part.AssemblyLinearVelocity += self.LinearVelocity
		part.AssemblyAngularVelocity += self.AngularVelocity
	end))

	self:UpdateTags()
	self.Maid.Part = part
end

function Plate:Kill()
	local killDuration = 15

	local maid = Maid.new()
	self.Maid.Kill = maid

	local sound = maid:Add(Instance.new("Sound")) :: Sound
	sound.SoundId = "rbxassetid://8863377426" -- "rbxassetid://1034263055"
	sound.Volume = 4
	sound.PlaybackSpeed = Random.new():NextNumber(1.05, 1.175)
	sound.Parent = self.Part
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)

	local oldTransparency = self.Part.Transparency
	self.Part.Transparency = 0.25

	local tween = TweenService:Create(self.Part, TweenInfo.new(killDuration), {
		Transparency = 1,
	})
	tween:Play()

	maid.CancelTween = function()
		tween:Cancel()
		self.Part.Transparency = oldTransparency
	end

	maid.Thread = task.delay(killDuration, function()
		self:Destroy()
		maid:Destroy()
	end)
end

function Plate:SetCFrame(cframe: CFrame)
	self.CFrame = cframe
	self.Part.CFrame = cframe
end

function Plate:SetPosition(position: Vector3)
	self:SetCFrame(CFrame.new(position) * self.CFrame.Rotation)
end

function Plate:GetMoveTarget(): Vector3
	return self.Part.Position + self.Move
end

function Plate:GetRotateTarget(): Vector3
	return self.Part.Rotation + self.Rotate
end

function Plate:GetCFrameTarget(): CFrame
	local targetPosition = self:GetMoveTarget()
	local targetRotation = self:GetRotateTarget()
	return CFrame.new(targetPosition)
		* CFrame.fromOrientation(math.rad(targetRotation.X), math.rad(targetRotation.Y), math.rad(targetRotation.Z))
end

function Plate:GetSizeTarget(): Vector3
	return self.Part.Size + self.SizeChange
end

function Plate:MoveTo(position: Vector3)
	self.Move = position - self.Part.Position
end

function Plate:RotateTo(rotation: Vector3)
	self.Rotate = rotation - self.Part.Rotation
end

function Plate:CFrameTo(cframe: CFrame)
	local rx, ry, rz = cframe:ToOrientation()
	local x, y, z = math.deg(rx), math.deg(ry), math.deg(rz)

	self:MoveTo(cframe.Position)
	self:RotateTo(Vector3.new(x, y, z))
end

function Plate:SizeTo(size: Vector3)
	self.SizeChange = size - self.Part.Size
end

function Plate:SetSize(size: Vector3)
	self.Part.Size = size
end

function Plate:AddSize(size: Vector3)
	self:SizeTo(self.Part.Size + size)
end

function Plate:RemoveSize(size: Vector3)
	self:SizeTo(self.Part.Size - size)
end

function Plate:Grow(amount: number)
	return self:AddSize(Vector3.new(amount, if self:GetShape() == Enum.PartType.Ball then amount else 0, amount))
end

function Plate:Shrink(amount: number)
	return self:RemoveSize(Vector3.new(amount, if self:GetShape() == Enum.PartType.Ball then amount else 0, amount))
end

function Plate:Bring(target: Character.CharacterTarget)
	Character.teleport(target, self.CFrame.Position + Vector3.yAxis * 1, true)
end

function Plate:IsOwner(player: Player): boolean
	return table.find(self.Owners, player) ~= nil
end

function Plate:AddOwner(player: Player)
	if not self:IsOwner(player) then
		table.insert(self.Owners, player)
		self:UpdateTags()
	end
end

function Plate:RemoveOwner(player: Player)
	if self:IsOwner(player) then
		table.remove(self.Owners, table.find(self.Owners, player))
		self:UpdateTags()
	end
end

function Plate:SetShape(shape: Enum.PartType)
	local part = self.Part :: PlatePart
	local plateMesh = Assets.Server.PlateMesh :: { [string]: MeshPart }

	if shape == Enum.PartType.Ball then
		part:ApplyMesh(plateMesh.Ball)
	elseif shape == Enum.PartType.Block then
		part:ApplyMesh(plateMesh.Block)
	elseif shape == Enum.PartType.Cylinder then
		part:ApplyMesh(plateMesh.Cylinder)
	end
end

function Plate:GetShape(): Enum.PartType
	local meshId = self.Part.MeshId :: string
	local plateMesh = Assets.Server.PlateMesh :: { [string]: MeshPart }

	if meshId == plateMesh.Ball.MeshId then
		return Enum.PartType.Ball
	elseif meshId == plateMesh.Block.MeshId then
		return Enum.PartType.Block
	elseif meshId == plateMesh.Cylinder.MeshId then
		return Enum.PartType.Cylinder
	end
end

-- @Plates
-- @Plates
-- @Plates
Plates.DefaultPlateSize = Vector3.new(20, 1, 20)
Plates.List = {} :: { Plate }
Plates.new = Plate.new
Plates.from = Plate.from

function Plates:GetPlates()
	return Plates.List
end

function Plates:ClearAll()
	local list = table.clone(Plates.List)
	table.clear(Plates.List) -- Prevent each :Destroy() call from doing a table.remove by clearing table here

	for _, plate in ipairs(list) do
		plate:Destroy()
	end
end

function Plates:PlayerDied(player: Player)
	for _, plate in ipairs(Plates:GetPlates()) do
		if not plate:IsOwner(player) then
			continue
		end

		plate:RemoveOwner(player)
		if #plate.Owners <= 0 then
			task.defer(function()
				plate:Kill()
			end)
		end
	end
end

HeadMaid:GiveTask(function()
	Plates:ClearAll()
end)

return Plates
