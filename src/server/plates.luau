local Maid = require("shared/maid")
local HeadMaid = require("shared/headMaid")
local Arena = require("server/arena")
local Character = require("server/character")

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
	self.Size = Vector3.zero

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
	part.CFrame = self.CFrame
	part.Material = Enum.Material.SmoothPlastic

	self:SetSize(Plates.DefaultPlateSize)
	self.Maid.Part = part
end

function Plate:Destroy()
	self.Maid:Destroy()
end

function Plate:Kill()
	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(1, 0, 0)
	highlight.OutlineTransparency = 0
	highlight.Parent = self.Part

	task.delay(5, function()
		self:Destroy()
	end)
end

function Plate:SetCFrame(cframe: CFrame)
	self.CFrame = cframe
	self.Part.CFrame = cframe
end

function Plate:SetSize(size: Vector3)
	self.Size = size
	self.Part.Size = size
end

function Plate:MoveTo(location: Vector3)
	self:SetCFrame(CFrame.new(location) * self.CFrame.Rotation)
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

HeadMaid:GiveTask(function()
	Plates:ClearAll()
end)

return Plates
