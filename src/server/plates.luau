local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Arena = require("server/arena")
local Character = require("server/character")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Plate = {}
type Plate = typeof(Plate.new())

local Plates = {}

-- @Plate
-- @Plate
-- @Plate
Plate.__index = Plate

function Plate.new(owner: Player?): Plate
	local self = setmetatable({}, Plate)
	self.Maid = Maid.new()
	self.Owners = { owner }
	self.PartMaid = self.Maid:Add(Maid.new())
	self.CFrame = CFrame.identity

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

function Plate:UpdateTags()
	local part = self.Part
	part:SetAttribute("IsPlate", true)

	local userIds = {}
	for _, player in ipairs(self.Owners) do
		table.insert(userIds, player.UserId)
	end

	part:SetAttribute("Owners", table.concat(userIds, ","))
end

function Plate:Reset()
	self.PartMaid:DoCleaning()

	local part = Instance.new("Part")
	part.Parent = assert(Arena.Folder, "No Arena exists yet.")

	self.Part = part
	self.Maid.Removing = part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(Arena.Folder) then
			self:Destroy()
		end
	end)

	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic

	self:SetCFrame(CFrame.new(self.CFrame.Position)) -- Reset rotation
	self:SetSize(Plates.DefaultPlateSize)
	self:UpdateTags()

	self.Maid.Part = part
end

function Plate:Destroy()
	self.Maid:Destroy()
end

function Plate:Kill()
	local killDuration = 15

	local maid = Maid.new()
	self.Maid.Kill = maid

	local sound = maid:Add(Instance.new("Sound"))
	sound.SoundId = "rbxassetid://8863377426" -- "rbxassetid://1034263055"
	sound.Volume = 4
	sound.PlaybackSpeed = Random.new():NextNumber(1.05, 1.175)
	sound.Parent = self.Part
	sound:Play()

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

function Plate:MoveTo(location: Vector3)
	self:SetCFrame(CFrame.new(location) * self.CFrame.Rotation)
end

function Plate:SetSize(size: Vector3)
	self.Part.Size = size
end

function Plate:AddSize(size: Vector3)
	self:SetSize(self.Size + size)
end

function Plate:RemoveSize(size: Vector3)
	self:SetSize(self.Size - size)
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

-- @Plates
-- @Plates
-- @Plates
Plates.DefaultPlateSize = Vector3.new(20, 1, 20)
Plates.List = {} :: { Plate }
Plates.new = Plate.new

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
			plate:Kill()
		end
	end
end

HeadMaid:GiveTask(function()
	Plates:ClearAll()
end)

return Plates
