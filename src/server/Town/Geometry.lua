local Geometry = {}

Geometry.Colors = {
	road = Color3.fromRGB(47, 50, 51),
	roadLine = Color3.fromRGB(244, 220, 139),
	crosswalk = Color3.fromRGB(237, 232, 212),
	paving = Color3.fromRGB(183, 177, 159),
	curb = Color3.fromRGB(205, 198, 178),
	trim = Color3.fromRGB(245, 229, 193),
	wood = Color3.fromRGB(100, 61, 39),
	glass = Color3.fromRGB(117, 178, 190),
	leaf = Color3.fromRGB(58, 120, 65),
}

function Geometry.Facing(position, forward)
	return CFrame.lookAt(position, position + forward, Vector3.yAxis)
end

function Geometry.Part(parent, name, size, cframe, color, material, options)
	options = options or {}
	local part = Instance.new(options.className or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(180, 180, 180)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = options.collide ~= false
	part.CanTouch = options.canTouch == true
	part.CanQuery = options.canQuery ~= false
	part.CastShadow = options.castShadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if options.shape then
		part.Shape = options.shape
	end
	if options.transparency ~= nil then
		part.Transparency = options.transparency
	end
	if options.reflectance ~= nil then
		part.Reflectance = options.reflectance
	end
	part.Parent = parent
	return part
end

function Geometry.Box(parent, name, size, position, forward, color, material, options)
	return Geometry.Part(parent, name, size, Geometry.Facing(position, forward), color, material, options)
end

function Geometry.Cylinder(parent, name, position, diameter, height, color, material, options)
	-- Roblox cylinders run along local X; rotate that axis to world Y.
	local cframe = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	options = options or {}
	options.shape = Enum.PartType.Cylinder
	return Geometry.Part(parent, name, Vector3.new(height, diameter, diameter), cframe, color, material, options)
end

function Geometry.Sign(parent, name, position, forward, width, height, text, boardColor, textColor, material)
	local board = Geometry.Box(parent, name, Vector3.new(width, height, 0.8), position, forward,
		boardColor, material or Enum.Material.WoodPlanks, { collide = false, canTouch = false, canQuery = false })
	local surface = Instance.new("SurfaceGui")
	surface.Name = "SignFace"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 28
	surface.LightInfluence = 0
	surface.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = boardColor
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 247, 221)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = surface
	return board
end

return Geometry
