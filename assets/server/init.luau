local assets = Instance.new("Folder")
local function add(name: Instance, to: Instance, what: Instance): Instance
	what.Name = name
	what.Parent = to
	return what
end

local InsertService = game:GetService("InsertService")
local function insertMesh(
	meshId: string,
	collisionFidelity: Enum.CollisionFidelity,
	renderFidelity: Enum.RenderFidelity
): MeshPart
	while true do
		local success, mesh = pcall(
			InsertService.CreateMeshPartAsync,
			InsertService,
			meshId,
			collisionFidelity or Enum.CollisionFidelity.Default,
			renderFidelity or Enum.RenderFidelity.Automatic
		)

		if not success then
			warn(`Failed to create mesh "{meshId}": {mesh}`)
			task.wait(0.5)

			continue
		end

		return mesh
	end
end

do
	local meshFolder = add("PlateMesh", assets, Instance.new("Folder"))

	add("Block", meshFolder, insertMesh("rbxassetid://13307406342"))
	add("Ball", meshFolder, insertMesh("rbxassetid://11640745670"))
    add("Cylinder", meshFolder, insertMesh("rbxassetid://18406029582"))
end

return assets
