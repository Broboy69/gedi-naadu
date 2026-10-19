-- Gedi Nadu: procedural first-playable town prototype.
-- All geometry is built from inexpensive, anchored Roblox Parts at server startup.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ROOT_NAME = "GediNaduGenerated"
local oldTown = Workspace:FindFirstChild(ROOT_NAME)
if oldTown then
	oldTown:Destroy()
end

local town = Instance.new("Folder")
town.Name = ROOT_NAME
town.Parent = Workspace

local COLORS = {
	road = Color3.fromRGB(48, 51, 52),
	roadLine = Color3.fromRGB(244, 220, 139),
	crosswalk = Color3.fromRGB(236, 232, 211),
	paving = Color3.fromRGB(183, 177, 159),
	curb = Color3.fromRGB(207, 199, 178),
	trim = Color3.fromRGB(248, 231, 190),
	wood = Color3.fromRGB(99, 57, 35),
	glass = Color3.fromRGB(115, 177, 190),
	leaf = Color3.fromRGB(55, 113, 62),	
}

local function newPart(name, size, cframe, color, material, parent, shape, collide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent or town
	return part
end

local function cfFacing(position, forward)
	return CFrame.lookAt(position, position + forward, Vector3.yAxis)
end

local function addLabel(board, text, textColor, backgroundColor)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = backgroundColor or board.Color
	label.BackgroundTransparency = 0
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 247, 221)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = gui
end

local function addSign(position, forward, width, height, text, boardColor, textColor, parent)
	local boardCF = cfFacing(position, forward)
	local board = newPart("Signboard - " .. text, Vector3.new(width, height, 0.8), boardCF,
		boardColor, Enum.Material.WoodPlanks, parent or town, nil, false)
	addLabel(board, text, textColor, boardColor)
	return board
end

local function addRoad(axis, centerX, centerZ, length, width, name, dashedCenter)
	local horizontal = axis == "X"
	local roadSize = horizontal and Vector3.new(length, 0.35, width) or Vector3.new(width, 0.35, length)
	local roadCF = CFrame.new(centerX, 0.025, centerZ)
	newPart(name .. " - asphalt", roadSize, roadCF, COLORS.road, Enum.Material.Asphalt)

	local sidewalkWidth = 8
	local curbWidth = 0.8
	for _, side in ipairs({ -1, 1 }) do
		local offset = side * (width / 2 + sidewalkWidth / 2)
		local curbOffset = side * (width / 2 + curbWidth / 2)
		local sidewalkPos = horizontal and Vector3.new(centerX, 0.19, centerZ + offset)
			or Vector3.new(centerX + offset, 0.19, centerZ)
		local curbPos = horizontal and Vector3.new(centerX, 0.32, centerZ + curbOffset)
			or Vector3.new(centerX + curbOffset, 0.32, centerZ)
		local sidewalkSize = horizontal and Vector3.new(length, 0.42, sidewalkWidth)
			or Vector3.new(sidewalkWidth, 0.42, length)
		local curbSize = horizontal and Vector3.new(length, 0.66, curbWidth)
			or Vector3.new(curbWidth, 0.66, length)
		newPart(name .. " - sidewalk", sidewalkSize, CFrame.new(sidewalkPos), COLORS.paving, Enum.Material.Concrete)
		newPart(name .. " - curb", curbSize, CFrame.new(curbPos), COLORS.curb, Enum.Material.Concrete)
	end

	if dashedCenter then
		local count = math.floor(length / 22)
		for i = 0, count do
			local along = -length / 2 + i * 22
			-- Keep the junction clear for the crosswalks and turning traffic.
			local crosses = math.abs(along) < 35
			if not crosses then
				local p = horizontal and Vector3.new(centerX + along, 0.215, centerZ)
					or Vector3.new(centerX, 0.215, centerZ + along)
				local size = horizontal and Vector3.new(9, 0.035, 0.34) or Vector3.new(0.34, 0.035, 9)
				newPart(name .. " - center dash", size, CFrame.new(p), COLORS.roadLine, Enum.Material.SmoothPlastic, town, nil, false)
			end
		end
	end
end

local function addCrosswalk(axis, centerX, centerZ, crossingAt, roadWidth, name)
	for stripe = -4, 4 do
		local offset = stripe * 2.3
		local position
		local size
		if axis == "X" then
			position = Vector3.new(centerX + crossingAt + offset, 0.218, centerZ)
			size = Vector3.new(1.25, 0.04, roadWidth - 5)
		else
			position = Vector3.new(centerX, 0.218, centerZ + crossingAt + offset)
			size = Vector3.new(roadWidth - 5, 0.04, 1.25)
		end
		newPart(name .. " - zebra stripe", size, CFrame.new(position), COLORS.crosswalk, Enum.Material.SmoothPlastic, town, nil, false)
	end
end

local function addWindow(center, forward, width, height, parent, withShutters)
	local frameColor = Color3.fromRGB(246, 227, 183)
	local frame = newPart("Window frame", Vector3.new(width + 1.4, height + 1.4, 0.65),
		cfFacing(center, forward), frameColor, Enum.Material.Wood, parent, nil, false)
	local pane = newPart("Blue-green glass", Vector3.new(width, height, 0.38),
		cfFacing(center + forward * 0.42, forward), COLORS.glass, Enum.Material.Glass, parent, nil, false)
	pane.Transparency = 0.12
	newPart("Window sill", Vector3.new(width + 2.5, 0.65, 1.2),
		cfFacing(center + forward * 0.42 + Vector3.new(0, -height / 2 - 0.55, 0), forward),
		frameColor, Enum.Material.Wood, parent, nil, false)
	newPart("Window mullion", Vector3.new(0.42, height, 0.48),
		cfFacing(center + forward * 0.67, forward), frameColor, Enum.Material.Wood, parent, nil, false)
	newPart("Window crossbar", Vector3.new(width, 0.38, 0.48),
		cfFacing(center + forward * 0.68, forward), frameColor, Enum.Material.Wood, parent, nil, false)
	if withShutters then
		for _, side in ipairs({ -1, 1 }) do
			newPart("Timber shutter", Vector3.new(1.3, height + 0.3, 0.7),
				cfFacing(center + forward * 0.46 + Vector3.new(0, 0, 0), forward)
					* CFrame.new(side * (width / 2 + 1.15), 0, 0),
					COLORS.wood, Enum.Material.WoodPlanks, parent, nil, false)
		end
	end
end

local function addCylinder(name, position, diameter, height, color, material, parent)
	local cylinderCF = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	-- Roblox cylinders run along local X, so the longest dimension becomes vertical.
	return newPart(name, Vector3.new(height, diameter, diameter), cylinderCF, color, material, parent, Enum.PartType.Cylinder)
end

local function addBuilding(spec)
	local center = Vector3.new(spec.x, 0, spec.z)
	local forward = spec.forward
	local right = forward:Cross(Vector3.yAxis).Unit
	local width = spec.width
	local depth = spec.depth
	local height = spec.height
	local group = Instance.new("Model")
	group.Name = spec.name
	group.Parent = town

	local foundationCenter = center + Vector3.new(0, 0.33, 0)
	newPart("Stone foundation", Vector3.new(width + 2, 0.66, depth + 2),
		cfFacing(foundationCenter, forward), Color3.fromRGB(139, 132, 116), Enum.Material.Slate, group)
	local bodyBottom = 0.66
	local bodyCenter = center + Vector3.new(0, bodyBottom + height / 2, 0)
	newPart("Plastered exterior", Vector3.new(width, height, depth),
		cfFacing(bodyCenter, forward), spec.wallColor, Enum.Material.SmoothPlastic, group)

	-- Layered wall bands and corner pilasters make each facade read as a building, not a box.
	local facadeBase = center + forward * (depth / 2 + 0.08) + Vector3.new(0, bodyBottom, 0)
	newPart("Lower wall band", Vector3.new(width + 0.6, 1.1, 0.7),
		cfFacing(facadeBase + Vector3.new(0, 1.05, 0), forward), spec.trimColor, Enum.Material.Concrete, group, nil, false)
	newPart("Cornice", Vector3.new(width + 2.2, 1.25, depth + 2.2),
		cfFacing(center + Vector3.new(0, bodyBottom + height - 0.5, 0), forward),
		spec.trimColor, Enum.Material.Concrete, group)
	for _, side in ipairs({ -1, 1 }) do
		newPart("Facade pilaster", Vector3.new(1.8, height - 1.1, 1.1),
			cfFacing(facadeBase + right * (side * (width / 2 - 1.3)) + Vector3.new(0, (height - 1.1) / 2 + 1.1, 0), forward),
			spec.trimColor, Enum.Material.Concrete, group)
	end

	-- Front door, surround, steps, and a covered entry porch.
	local doorWidth = spec.special and 8 or 6.5
	local doorHeight = spec.special and 12 or 10
	local doorY = bodyBottom + doorHeight / 2
	local doorCenter = facadeBase + Vector3.new(0, doorY, 0) + forward * 0.45
	newPart("Door surround", Vector3.new(doorWidth + 2.5, doorHeight + 2, 0.8),
		cfFacing(doorCenter, forward), spec.trimColor, Enum.Material.Wood, group, nil, false)
	newPart("Entry door", Vector3.new(doorWidth, doorHeight, 0.55),
		cfFacing(doorCenter + forward * 0.48, forward), spec.doorColor or COLORS.wood, Enum.Material.WoodPlanks, group, nil, false)
	newPart("Door glass panel", Vector3.new(doorWidth - 2, 3.4, 0.25),
		cfFacing(doorCenter + Vector3.new(0, 2.3, 0) + forward * 0.82, forward),
		COLORS.glass, Enum.Material.Glass, group, nil, false).Transparency = 0.12
	addCylinder("Door handle", doorCenter + right * (doorWidth / 2 - 1) + Vector3.new(0, -1.2, 0) + forward * 1.02,
		0.55, 0.65, Color3.fromRGB(205, 166, 83), Enum.Material.Metal, group)
	for step = 1, 2 do
		newPart("Entry step", Vector3.new(doorWidth + 5, 0.55, 2.6),
			cfFacing(center + forward * (depth / 2 + step * 1.15) + Vector3.new(0, step * 0.25, 0), forward),
			Color3.fromRGB(181, 173, 153), Enum.Material.Concrete, group)
	end
	local porchPosition = center + forward * (depth / 2 + 5.2) + Vector3.new(0, bodyBottom + math.min(height - 4, 13), 0)
	newPart("Entry canopy", Vector3.new(math.min(width - 8, 22), 1.1, 11),
		cfFacing(porchPosition, forward), spec.roofColor, Enum.Material.WoodPlanks, group)
	for _, side in ipairs({ -1, 1 }) do
		addCylinder("Porch column", center + forward * (depth / 2 + 9) + right * side * (math.min(width - 8, 22) / 2 - 1)
			+ Vector3.new(0, (bodyBottom + math.min(height - 4, 13)) / 2, 0),
			1.25, bodyBottom + math.min(height - 4, 13), spec.trimColor, Enum.Material.Marble, group)
	end

	-- Front windows are arranged from the actual facade width.
	local windowWidth = spec.special and 10 or 8
	local windowHeight = spec.special and 9 or 8
	local windowY = bodyBottom + math.min(height * 0.60, height - 6)
	local windowOffsets = { -width * 0.31, width * 0.31 }
	for _, offset in ipairs(windowOffsets) do
		addWindow(facadeBase + right * offset + Vector3.new(0, windowY, 0) + forward * 0.05,
			forward, windowWidth, windowHeight, group, spec.style == "house")
	end
	if height > 25 then
		for _, offset in ipairs({ -width * 0.31, 0, width * 0.31 }) do
			addWindow(facadeBase + right * offset + Vector3.new(0, bodyBottom + height * 0.83, 0) + forward * 0.3,
				forward, windowWidth - 1, 7, group, false)
		end
	end

	-- A deep awning identifies shops and softens the street-facing elevation.
	if spec.style == "shop" then
		local awningY = bodyBottom + height * 0.48
		local awning = newPart("Striped shop awning", Vector3.new(width - 12, 1.1, 6),
			cfFacing(center + forward * (depth / 2 + 3.5) + Vector3.new(0, awningY, 0), forward),
			spec.awningColor, Enum.Material.Fabric, group)
		awning.CanCollide = false
		for stripe = -2, 2 do
			newPart("Awning stripe", Vector3.new(0.45, 1.15, 6.1),
				cfFacing(center + forward * (depth / 2 + 3.5) + right * stripe * ((width - 12) / 5)
					+ Vector3.new(0, awningY, 0), forward), Color3.fromRGB(244, 229, 196), Enum.Material.Fabric, group, nil, false)
		end
	end

	-- Kerala-inspired sloped tiled roofs for homes and shops; civic buildings get a parapet roof.
	local roofY = bodyBottom + height + 0.55
	if spec.roofStyle == "flat" then
		newPart("Flat roof deck", Vector3.new(width + 5, 1.3, depth + 5),
			cfFacing(center + Vector3.new(0, roofY, 0), forward), spec.roofColor, Enum.Material.Concrete, group)
		for _, edge in ipairs({ -1, 1 }) do
			newPart("Roof parapet", Vector3.new(width + 5, 3.2, 1.1),
				cfFacing(center + right * edge * (width / 2 + 2.5) + Vector3.new(0, roofY + 2, 0), forward),
				spec.trimColor, Enum.Material.Concrete, group)
		end
	else
		local rise = spec.style == "house" and 9 or 6
		local halfWidth = width / 2 + 1.5
		local panelWidth = math.sqrt(halfWidth * halfWidth + rise * rise)
		local angle = math.atan(rise / halfWidth)
		local panelY = bodyBottom + height + rise / 2
		for _, side in ipairs({ -1, 1 }) do
			local panelPos = center + right * side * (halfWidth / 2) + Vector3.new(0, panelY, 0)
			local panelCF = cfFacing(panelPos, forward) * CFrame.Angles(0, 0, -side * angle)
			newPart("Terracotta roof slope", Vector3.new(panelWidth, 1.25, depth + 5), panelCF,
				spec.roofColor, Enum.Material.RoofShingles, group)
		end
		addCylinder("Ridge cap", center + Vector3.new(0, bodyBottom + height + rise, 0),
			1.2, depth + 5, spec.roofColor, Enum.Material.RoofShingles, group)
	end

	-- Signboards are mounted above the entry and face the public street.
	local signY = bodyBottom + height - (spec.style == "shop" and 7 or 5)
	local signPosition = facadeBase + Vector3.new(0, signY, 0) + forward * 0.55
	local signWidth = math.min(width - 10, spec.style == "civic" and 42 or 34)
	local signColor = spec.signColor or Color3.fromRGB(106, 65, 39)
	local signTextColor = spec.signTextColor or Color3.fromRGB(255, 244, 212)
	local signBoard = newPart("Facade sign - " .. spec.sign, Vector3.new(signWidth, 4.5, 0.8),
		cfFacing(signPosition, forward), signColor, Enum.Material.WoodPlanks, group, nil, false)
	addLabel(signBoard, spec.sign, signTextColor, signColor)

	if spec.style == "civic" then
		-- A small flagstaff and flag distinguish the public-service buildings.
		addCylinder("Flagpole", center + Vector3.new(width / 2 - 4, bodyBottom + height + 7, 0),
			0.55, 14, Color3.fromRGB(190, 190, 182), Enum.Material.Metal, group)
		newPart("Civic flag", Vector3.new(7, 3.5, 0.35),
			CFrame.new(center + Vector3.new(width / 2, bodyBottom + height + 9, 0)),
			spec.flagColor or Color3.fromRGB(29, 111, 73), Enum.Material.Fabric, group, nil, false)
	end
	return group
end

local function addTree(x, z, style, scale)
	scale = scale or 1
	local base = Vector3.new(x, 0, z)
	local trunkHeight = (style == "palm" and 19 or 10) * scale
	local trunkDiameter = (style == "palm" and 1.4 or 2.1) * scale
	addCylinder(style == "palm" and "Coconut palm trunk" or "Shade tree trunk",
		base + Vector3.new(0, trunkHeight / 2, 0), trunkDiameter, trunkHeight,
		style == "palm" and Color3.fromRGB(122, 83, 47) or Color3.fromRGB(111, 76, 48), Enum.Material.Wood)
	if style == "palm" then
		local crown = base + Vector3.new(0, trunkHeight, 0)
		for i = 0, 6 do
			local angle = i * math.pi * 2 / 7
			local outward = Vector3.new(math.cos(angle), -0.44, math.sin(angle))
			local frond = newPart("Palm frond", Vector3.new(1.6 * scale, 0.28 * scale, 12 * scale),
				CFrame.lookAt(crown, crown + outward * 12 * scale) * CFrame.Angles(math.rad(-7), 0, 0),
				Color3.fromRGB(48, 126, 65), Enum.Material.Grass, town, nil, false)
			frond.CastShadow = false
		end
		for coconut = 0, 2 do
			local offset = Vector3.new(math.cos(coconut * 2.1) * 1.2, -1.1, math.sin(coconut * 2.1) * 1.2)
			local ball = newPart("Coconut", Vector3.new(1.1, 1.1, 1.1), CFrame.new(crown + offset),
				Color3.fromRGB(104, 67, 37), Enum.Material.Wood, town, Enum.PartType.Ball, false)
			ball.CastShadow = false
		end
	else
		local crown = base + Vector3.new(0, trunkHeight + 2.8 * scale, 0)
		for i = 1, 5 do
			local angle = i * math.pi * 2 / 5
			local offset = Vector3.new(math.cos(angle) * 3 * scale, (i % 2) * scale, math.sin(angle) * 3 * scale)
			local ball = newPart("Leaf canopy", Vector3.new(7, 6, 7) * scale, CFrame.new(crown + offset),
				(i % 2 == 0) and Color3.fromRGB(59, 123, 68) or Color3.fromRGB(69, 137, 74),
				Enum.Material.Grass, town, Enum.PartType.Ball, false)
			ball.CastShadow = false
		end
	end
end

local function addStreetlight(x, z, forward)
	local ground = Vector3.new(x, 0, z)
	addCylinder("Streetlight pole", ground + Vector3.new(0, 11, 0), 0.8, 22,
		Color3.fromRGB(68, 74, 72), Enum.Material.Metal)
	local armPos = ground + Vector3.new(0, 21.5, 0) + forward * 3.2
	newPart("Streetlight arm", Vector3.new(0.65, 0.65, 6.5), cfFacing(armPos, forward),
		Color3.fromRGB(68, 74, 72), Enum.Material.Metal)
	local lampPos = ground + Vector3.new(0, 20.8, 0) + forward * 6
	local lamp = newPart("Warm street lamp", Vector3.new(3.2, 0.8, 2.2), cfFacing(lampPos, forward),
		Color3.fromRGB(255, 226, 154), Enum.Material.Neon, town, nil, false)
	lamp.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 218, 145)
	light.Brightness = 1.1
	light.Range = 24
	light.Shadows = false
	light.Parent = lamp
end

local function addBench(position, forward)
	local seatCF = cfFacing(position + Vector3.new(0, 2, 0), forward)
	newPart("Town bench seat", Vector3.new(8, 0.8, 2.2), seatCF, COLORS.wood, Enum.Material.WoodPlanks)
	newPart("Town bench back", Vector3.new(8, 3.5, 0.7), seatCF * CFrame.new(0, 1.7, -0.85),
		COLORS.wood, Enum.Material.WoodPlanks)
	for side = -1, 1, 2 do
		newPart("Bench leg", Vector3.new(0.8, 2, 1.8), seatCF * CFrame.new(side * 3, -1, 0),
			Color3.fromRGB(75, 78, 72), Enum.Material.Metal)
	end
end

-- A calm, green base makes the town edges feel intentional without Terrain generation cost.
newPart("Town grass base", Vector3.new(760, 1, 640), CFrame.new(0, -0.65, 0),
	Color3.fromRGB(111, 146, 91), Enum.Material.Grass)

-- A compact street grid: main avenue, north-south connector, and two neighborhood cross streets.
addRoad("X", 0, 0, 620, 48, "Main Street", true)
addRoad("Z", 0, 0, 500, 44, "Market Avenue", true)
addRoad("X", 0, 174, 560, 26, "North Cross Street", true)
addRoad("X", 0, -174, 560, 26, "South Cross Street", true)
addCrosswalk("X", 0, 0, -30, 48, "Main Street west crossing")
addCrosswalk("X", 0, 0, 30, 48, "Main Street east crossing")
addCrosswalk("Z", 0, 0, -28, 44, "Market Avenue south crossing")
addCrosswalk("Z", 0, 0, 28, 44, "Market Avenue north crossing")
addCrosswalk("X", 0, 174, 22, 26, "North Street crossing")
addCrosswalk("X", 0, -174, 22, 26, "South Street crossing")

-- Colorful, varied low-rise homes and shops face the main road.
-- In this layout, negative Z is south and positive Z is north.
local south = Vector3.new(0, 0, -1)
local north = Vector3.new(0, 0, 1)
local east = Vector3.new(-1, 0, 0)
local west = Vector3.new(1, 0, 0)

local buildings = {
	{ name = "Thenga House", x = -258, z = 74, width = 54, depth = 38, height = 23, forward = south, style = "house", wallColor = Color3.fromRGB(231, 201, 152), trimColor = Color3.fromRGB(248, 229, 187), roofColor = Color3.fromRGB(137, 70, 48), sign = "THENGA HOUSE", signColor = Color3.fromRGB(111, 70, 43) },
	{ name = "Chaya Kada", x = -174, z = 74, width = 58, depth = 40, height = 25, forward = south, style = "shop", wallColor = Color3.fromRGB(224, 177, 111), trimColor = Color3.fromRGB(255, 228, 171), roofColor = Color3.fromRGB(128, 69, 46), awningColor = Color3.fromRGB(157, 57, 43), sign = "CHAYA KADA", signColor = Color3.fromRGB(104, 54, 37) },
	{ name = "Mango Grove Home", x = -92, z = 74, width = 54, depth = 38, height = 22, forward = south, style = "house", wallColor = Color3.fromRGB(196, 215, 166), trimColor = Color3.fromRGB(245, 235, 198), roofColor = Color3.fromRGB(129, 75, 54), sign = "MANGO GROVE", signColor = Color3.fromRGB(73, 105, 57) },
	{ name = "Nadu Mart", x = 91, z = 74, width = 56, depth = 40, height = 25, forward = south, style = "shop", wallColor = Color3.fromRGB(210, 190, 154), trimColor = Color3.fromRGB(246, 229, 190), roofColor = Color3.fromRGB(123, 73, 50), awningColor = Color3.fromRGB(37, 112, 91), sign = "NADU MART", signColor = Color3.fromRGB(28, 92, 75) },
	{ name = "Gedi Nadu Hospital", x = 175, z = 78, width = 72, depth = 54, height = 34, forward = south, style = "civic", special = true, roofStyle = "flat", wallColor = Color3.fromRGB(226, 229, 214), trimColor = Color3.fromRGB(192, 210, 190), roofColor = Color3.fromRGB(143, 158, 143), sign = "GEDI NADU HOSPITAL", signColor = Color3.fromRGB(37, 112, 86), signTextColor = Color3.fromRGB(255, 255, 242), flagColor = Color3.fromRGB(46, 143, 93) },
	{ name = "Kavu House", x = 260, z = 74, width = 54, depth = 38, height = 23, forward = south, style = "house", wallColor = Color3.fromRGB(224, 187, 166), trimColor = Color3.fromRGB(250, 229, 206), roofColor = Color3.fromRGB(129, 66, 52), sign = "KAVU HOUSE", signColor = Color3.fromRGB(105, 59, 48) },
	{ name = "Riverbend Stores", x = -258, z = -74, width = 56, depth = 40, height = 24, forward = north, style = "shop", wallColor = Color3.fromRGB(230, 197, 128), trimColor = Color3.fromRGB(250, 232, 185), roofColor = Color3.fromRGB(130, 72, 46), awningColor = Color3.fromRGB(171, 83, 55), sign = "RIVERBEND STORES", signColor = Color3.fromRGB(117, 64, 43) },
	{ name = "Gedi Nadu Police Station", x = -174, z = -76, width = 66, depth = 50, height = 31, forward = north, style = "civic", special = true, roofStyle = "flat", wallColor = Color3.fromRGB(214, 218, 198), trimColor = Color3.fromRGB(177, 190, 159), roofColor = Color3.fromRGB(125, 143, 125), sign = "GEDI NADU POLICE", signColor = Color3.fromRGB(28, 75, 105), signTextColor = Color3.fromRGB(255, 255, 241), flagColor = Color3.fromRGB(40, 91, 145) },
	{ name = "Jackfruit House", x = -88, z = -74, width = 54, depth = 38, height = 23, forward = north, style = "house", wallColor = Color3.fromRGB(204, 218, 170), trimColor = Color3.fromRGB(248, 235, 193), roofColor = Color3.fromRGB(142, 75, 50), sign = "JACKFRUIT HOME", signColor = Color3.fromRGB(68, 106, 56) },
	{ name = "Spice & Rice", x = 91, z = -74, width = 56, depth = 40, height = 25, forward = north, style = "shop", wallColor = Color3.fromRGB(220, 175, 132), trimColor = Color3.fromRGB(251, 227, 196), roofColor = Color3.fromRGB(129, 70, 48), awningColor = Color3.fromRGB(181, 128, 45), sign = "SPICE & RICE", signColor = Color3.fromRGB(121, 77, 30) },
	{ name = "Ponnamma Villa", x = 174, z = -74, width = 54, depth = 38, height = 23, forward = north, style = "house", wallColor = Color3.fromRGB(230, 207, 169), trimColor = Color3.fromRGB(247, 231, 199), roofColor = Color3.fromRGB(126, 66, 48), sign = "PONNAMMA VILLA", signColor = Color3.fromRGB(112, 76, 45) },
	{ name = "Blue Heron House", x = 258, z = -74, width = 54, depth = 38, height = 23, forward = north, style = "house", wallColor = Color3.fromRGB(179, 211, 205), trimColor = Color3.fromRGB(239, 234, 208), roofColor = Color3.fromRGB(119, 73, 53), sign = "BLUE HERON", signColor = Color3.fromRGB(44, 98, 102) },
}

for _, building in ipairs(buildings) do
	addBuilding(building)
end

-- A paved arrival plaza and safe first spawn sit at the north end of Market Avenue.
newPart("Town square paving", Vector3.new(100, 1, 76), CFrame.new(0, 0.12, 260),
	Color3.fromRGB(190, 183, 163), Enum.Material.Cobblestone)
newPart("Town square inset", Vector3.new(50, 0.18, 34), CFrame.new(0, 0.72, 260),
	Color3.fromRGB(163, 179, 143), Enum.Material.Grass)
for _, pos in ipairs({ Vector3.new(-32, 0.95, 260), Vector3.new(32, 0.95, 260) }) do
	newPart("Plaza planter", Vector3.new(12, 0.9, 12), CFrame.new(pos),
		Color3.fromRGB(141, 128, 102), Enum.Material.Brick)
end
addTree(-32, 260, "palm", 0.8)
addTree(32, 260, "shade", 0.8)
addBench(Vector3.new(-17, 0.85, 260), south)
addBench(Vector3.new(17, 0.85, 260), north)

-- Town-entry sign and two posts.
local entryForward = south
local signPos = Vector3.new(0, 12, 302)
addCylinder("Welcome sign post", Vector3.new(-18, 6, 302), 1.4, 12, COLORS.wood, Enum.Material.Wood)
addCylinder("Welcome sign post", Vector3.new(18, 6, 302), 1.4, 12, COLORS.wood, Enum.Material.Wood)
local welcome = newPart("Welcome to Gedi Nadu", Vector3.new(40, 9, 1.5), cfFacing(signPos, entryForward),
	Color3.fromRGB(44, 100, 72), Enum.Material.WoodPlanks)
addLabel(welcome, "GEDI NADU  •  NAMASKARAM", Color3.fromRGB(255, 242, 202), welcome.Color)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Town Square Spawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.CFrame = CFrame.new(0, 1.05, 260)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = town

-- Coconut palms and shade trees line the avenues and soften the town edge.
for _, treePos in ipairs({
	{ -285, 29, "palm", 0.85 }, { 285, 29, "palm", 0.85 },
	{ -285, -29, "palm", 0.85 }, { 285, -29, "palm", 0.85 },
	{ -282, 132, "shade", 0.9 }, { 282, 132, "shade", 0.9 },
	{ -282, -132, "shade", 0.9 }, { 282, -132, "shade", 0.9 },
	{ -245, 218, "palm", 0.9 }, { 245, 218, "palm", 0.9 },
	{ -245, -218, "palm", 0.9 }, { 245, -218, "palm", 0.9 },
}) do
	addTree(treePos[1], treePos[2], treePos[3], treePos[4])
end

-- Lamps are kept to a few well-spaced fixtures to limit lighting and instance cost.
for _, lampPos in ipairs({
	{ -110, 31, south }, { 110, 31, south }, { -110, -31, north }, { 110, -31, north },
	{ -275, 31, south }, { 275, 31, south }, { -275, -31, north }, { 275, -31, north },
	{ 0, 145, east }, { 0, -145, west },
}) do
	addStreetlight(lampPos[1], lampPos[2], lampPos[3])
end

-- A few street blades mark the civic block and neighborhood streets.
for _, signInfo in ipairs({
	{ Vector3.new(-32, 10, 27), south, "MARKET AVE" },
	{ Vector3.new(32, 10, -27), north, "MAIN STREET" },
	{ Vector3.new(20, 9, 162), south, "HOSPITAL  →" },
}) do
	local blade = newPart("Street name sign", Vector3.new(12, 2.5, 0.5), cfFacing(signInfo[1], signInfo[2]),
		Color3.fromRGB(40, 94, 68), Enum.Material.Metal, town, nil, false)
	addLabel(blade, signInfo[3], Color3.fromRGB(255, 248, 220), blade.Color)
end

-- Gentle afternoon light keeps the warm Kerala palette readable.
Lighting.ClockTime = 16.2
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(121, 128, 119)
Lighting.OutdoorAmbient = Color3.fromRGB(157, 167, 152)
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.25
local atmosphere = Lighting:FindFirstChild("GediNaduAtmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GediNaduAtmosphere"
	atmosphere.Parent = Lighting
end
atmosphere.Density = 0.22
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(207, 221, 205)
atmosphere.Decay = Color3.fromRGB(111, 130, 115)
atmosphere.Glare = 0.08
atmosphere.Haze = 0.7

print(("Gedi Nadu prototype generated: %d buildings, 4 connected streets, spawn plaza."):format(#buildings))
