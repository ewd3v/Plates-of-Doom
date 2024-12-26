local Arena = require("server/arena")

local Players = game:GetService("Players")
local Character = {}

export type CharacterTarget = Model | Player | any

function Character.get(target: CharacterTarget): Model?
	if typeof(target) ~= "Instance" then
		return
	end

	if target:IsA("Player") then
		return target.Character
	elseif target:IsA("Model") then
		return target
	end
end

function Character.getRoot(target: CharacterTarget): BasePart?
	local character = Character.get(target)
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
end

function Character.getPart(target: CharacterTarget): BasePart?
	local character = Character.get(target)
	if not character then
		return
	end

	local part = character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Head")

	if part and part:IsA("BasePart") then
		return part
	end

	return character:FindFirstChildWhichIsA("BasePart", true)
end

function Character.getHumanoid(target: CharacterTarget): Humanoid?
	local character = Character.get(target)
	if character then
		return character:FindFirstChildOfClass("Humanoid")
	end
end

function Character.isReady(target: CharacterTarget): boolean
	local character = Character.get(target)
	return Character.getRoot(character) and character:IsDescendantOf(workspace)
end

function Character.getCFrame(target: CharacterTarget): CFrame?
	local root = Character.getRoot(target)
	if root then
		return root.CFrame
	end
end

function Character.teleport(
	target: CharacterTarget,
	location: CFrame | Vector3 | CharacterTarget | Instance,
	preventClipping: boolean
)
	local character = Character.get(target)
	if not character then
		return
	end

	local root = Character.getRoot(character)
	if not root then
		return
	end

	local locationCharacter = Character.get(location)
	if locationCharacter then
		local locationRoot = Character.getRoot(locationCharacter)
		if not locationRoot then
			return
		end

		location = locationRoot.CFrame
	elseif typeof(location) == "Instance" and location:IsA("BasePart") then
		location = location.CFrame
	elseif typeof(location) == "Vector3" then
		location = CFrame.new(location) * root.CFrame.Rotation
	elseif typeof(location) ~= "CFrame" then
		return
	end

	-- Root should be the instance that lines up with the location
	character.PrimaryPart = root

	if not preventClipping then
		return character:PivotTo(location)
	end

	local humanoid = Character.getHumanoid(character)
	local hipHeight = if humanoid then humanoid.HipHeight else 2

	-- :MoveTo() moves the target out of any obstruction, preventing clipping
	Arena.moveTo(character, location.Position)

	-- Then use :PivotTo() to apply rotation and move upwards (to offset for hipheight)
	character:PivotTo(CFrame.new(root.Position + Vector3.yAxis * hipHeight) * location.Rotation)
end

function Character.freeze(target: CharacterTarget)
	local character = Character.get(target)
	if not character then
		return
	end

	local root = Character.getRoot(character)
	if root then
		root.Anchored = true
	end
end

function Character.unfreeze(target: CharacterTarget)
	local character = Character.get(target)
	if not character then
		return
	end

	local root = Character.getRoot(character)
	if root then
		root.Anchored = false
	end
end

function Character.load(player: Player)
	return pcall(player.LoadCharacter, player)
end

function Character.refresh(player: Player)
	local cframe = Character.getCFrame(player)
	while not Character.load(player) do
		task.wait()
	end

	while not Character.isReady(player) do
		task.wait()
	end

	Character.teleport(player, cframe)
end

function Character.kill(target: CharacterTarget)
	local humanoid = Character.getHumanoid(target)
	if humanoid then
		humanoid.Health = 0
	end
end

function Character.remove(target: CharacterTarget)
	local character = Character.get(target)
	if character then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			player.Character = nil
		end

		character:Destroy()
	end
end

function Character.damage(target: CharacterTarget, damage: number)
	local humanoid = Character.getHumanoid(target)
	if humanoid then
		humanoid:TakeDamage(damage)
	end
end

return table.freeze(Character)
