local assets = Instance.new("Folder")
local function add(name: Instance, to: Instance, what: Instance): Instance
	what.Name = name
	what.Parent = to
	return what
end

return assets
