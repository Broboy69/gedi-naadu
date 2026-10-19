local Geometry = require(script.Parent.Geometry)
local BuildingFactory = require(script.Parent.BuildingFactory)

local G = Geometry
local Layout = {}
local UP = Vector3.yAxis
local SOUTH = Vector3.new(0, 0, -1)
local NORTH = Vector3.new(0, 0, 1)
local EAST = Vector3.new(-1, 0, 0)
local WEST = Vector3.new(1, 0, 0)

local function road(parent, axis, centerX, centerZ, length, width, name, dashedCenter)
	local horizontal = axis == "X"
	local roadSize = horizontal and Vector3.new(length, 0.35, width) or Vector3.new(width, 0.35, length)
	G.Part(parent, name .. " - asphalt", roadSize, CFrame.new(centerX, 0.025, centerZ),
		G.Colors.road, Enum.Material.Asphalt)

	-- A narrow gutter runs between the asphalt and the raised curb.
	for _, side in ipairs({ -1, 1 }) do
		local gutterPosition = horizontal and Vector3.new(centerX, 0.205, centerZ + side * (width / 2 - 1.1))
			or Vector3.new(centerX + side * (width / 2 - 1.1), 0.205, centerZ)
		local gutterSize = horizontal and Vector3.new(length, 0.08, 0.45) or Vector3.new(0.45, 0.08, length)
		G.Part(parent, name .. " - roadside drain", gutterSize, CFrame.new(gutterPosition),
			Color3.fromRGB(107, 111, 105), Enum.Material.Concrete,
			{ collide = false, canTouch = false, canQuery = false })

		local sidewalkWidth = 8
		local curbWidth = 0.8
		local sidewalkOffset = side * (width / 2 + sidewalkWidth / 2)
		local curbOffset = side * (width / 2 + curbWidth / 2)
		local sidewalkPosition = horizontal and Vector3.new(centerX, 0.06, centerZ + sidewalkOffset)
			or Vector3.new(centerX + sidewalkOffset, 0.06, centerZ)
		local curbPosition = horizontal and Vector3.new(centerX, 0.2, centerZ + curbOffset)
			or Vector3.new(centerX + curbOffset, 0.2, centerZ)
		local sidewalkSize = horizontal and Vector3.new(length, 0.42, sidewalkWidth)
			or Vector3.new(sidewalkWidth, 0.42, length)
		local curbSize = horizontal and Vector3.new(length, 0.66, curbWidth)
			or Vector3.new(curbWidth, 0.66, length)
		G.Part(parent, name .. " - sidewalk", sidewalkSize, CFrame.new(sidewalkPosition),
			G.Colors.paving, Enum.Material.Concrete)
		G.Part(parent, name .. " - curb", curbSize, CFrame.new(curbPosition),
			G.Colors.curb, Enum.Material.Concrete)
	end

	if dashedCenter then
		local count = math.floor(length / 22)
		for index = 0, count do
			local along = -length / 2 + index * 22
			if math.abs(along) >= 35 then
				local position = horizontal and Vector3.new(centerX + along, 0.215, centerZ)
					or Vector3.new(centerX, 0.215, centerZ + along)
				local size = horizontal and Vector3.new(9, 0.035, 0.34) or Vector3.new(0.34, 0.035, 9)
				G.Part(parent, name .. " - center dash", size, CFrame.new(position),
					G.Colors.roadLine, Enum.Material.SmoothPlastic,
					{ collide = false, canTouch = false, canQuery = false, castShadow = false })
			end
		end
	end
end

local function crosswalk(parent, axis, centerX, centerZ, crossingAt, roadWidth, name)
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
		G.Part(parent, name .. " - zebra stripe", size, CFrame.new(position),
			G.Colors.crosswalk, Enum.Material.SmoothPlastic,
			{ collide = false, canTouch = false, canQuery = false, castShadow = false })
	end
end

local function addStreetlight(parent, x, z, forward, includeLight)
	local ground = Vector3.new(x, 0, z)
	G.Cylinder(parent, "Streetlight pole", ground + UP * 9, 0.72, 18,
		Color3.fromRGB(66, 73, 71), Enum.Material.Metal)
	local armPosition = ground + UP * 17.4 + forward * 2.8
	G.Box(parent, "Streetlight arm", Vector3.new(0.6, 0.6, 5.8), armPosition, forward,
		Color3.fromRGB(66, 73, 71), Enum.Material.Metal,
		{ collide = false, canTouch = false, canQuery = false })
	local lampPosition = ground + UP * 16.8 + forward * 5.6
	local lamp = G.Box(parent, "Warm street lamp", Vector3.new(2.8, 0.7, 1.8), lampPosition, forward,
		Color3.fromRGB(255, 222, 150), Enum.Material.Neon,
		{ collide = false, canTouch = false, canQuery = false, castShadow = false })
	if includeLight then
		local pointLight = Instance.new("PointLight")
		pointLight.Color = Color3.fromRGB(255, 218, 145)
		pointLight.Brightness = 0.55
		pointLight.Range = 17
		pointLight.Shadows = false
		pointLight.Parent = lamp
	end
end

local function addTree(parent, x, z, style, scale)
	scale = scale or 1
	local base = Vector3.new(x, 0, z)
	local palm = style == "palm"
	local trunkHeight = (palm and 18 or 9.5) * scale
	local trunkDiameter = (palm and 1.3 or 2) * scale
	G.Cylinder(parent, palm and "Coconut palm trunk" or "Shade tree trunk",
		base + UP * (trunkHeight / 2), trunkDiameter, trunkHeight,
		palm and Color3.fromRGB(124, 85, 49) or Color3.fromRGB(111, 77, 49), Enum.Material.Wood)
	if palm then
		local crown = base + UP * trunkHeight
		for index = 0, 6 do
			local angle = index * math.pi * 2 / 7
			local direction = Vector3.new(math.cos(angle), -0.42, math.sin(angle))
			G.Part(parent, "Coconut palm frond", Vector3.new(1.4 * scale, 0.24 * scale, 11 * scale),
				CFrame.lookAt(crown, crown + direction * 11 * scale) * CFrame.Angles(math.rad(-6), 0, 0),
				Color3.fromRGB(52, 128, 69), Enum.Material.Grass,
				{ collide = false, canTouch = false, canQuery = false, castShadow = false })
		end
		for coconut = 0, 2 do
			local offset = Vector3.new(math.cos(coconut * 2.1), -0.8, math.sin(coconut * 2.1))
			G.Part(parent, "Coconut", Vector3.new(1, 1, 1), CFrame.new(crown + offset),
				Color3.fromRGB(105, 68, 38), Enum.Material.Wood,
				{ shape = Enum.PartType.Ball, collide = false, canTouch = false, canQuery = false, castShadow = false })
		end
	else
		local crown = base + UP * (trunkHeight + 2.5 * scale)
		for index = 1, 5 do
			local angle = index * math.pi * 2 / 5
			local offset = Vector3.new(math.cos(angle) * 2.7 * scale, (index % 2) * scale, math.sin(angle) * 2.7 * scale)
			G.Part(parent, "Shade tree crown", Vector3.new(6.5, 5.6, 6.5) * scale,
				CFrame.new(crown + offset), index % 2 == 0 and Color3.fromRGB(58, 122, 67) or Color3.fromRGB(72, 137, 76),
				Enum.Material.Grass, { shape = Enum.PartType.Ball, collide = false, canTouch = false, canQuery = false, castShadow = false })
		end
	end
end

local function addBench(parent, position, forward, color)
	G.Box(parent, "Town bench seat", Vector3.new(7, 0.65, 2), position + UP * 1.8, forward,
		color or G.Colors.wood, Enum.Material.WoodPlanks)
	G.Box(parent, "Town bench back", Vector3.new(7, 3.2, 0.65), position + UP * 3.3 - forward * 0.75,
		forward, color or G.Colors.wood, Enum.Material.WoodPlanks)
	for side = -1, 1, 2 do
		G.Box(parent, "Bench leg", Vector3.new(0.65, 1.8, 1.6), position + UP * 0.9 + Vector3.new(side * 2.6, 0, 0),
			forward, Color3.fromRGB(75, 81, 76), Enum.Material.Metal)
	end
end

local function addBusShelter(parent)
	local center = Vector3.new(49, 0, 230)
	local forward = SOUTH
	G.Box(parent, "Bus shelter paved pad", Vector3.new(22, 0.45, 13), center + UP * 0.395, forward,
		Color3.fromRGB(177, 171, 153), Enum.Material.Concrete)
	G.Box(parent, "Bus shelter roof", Vector3.new(22, 0.8, 13), center + UP * 9, forward,
		Color3.fromRGB(49, 105, 77), Enum.Material.Metal)
	for side = -1, 1, 2 do
		G.Box(parent, "Bus shelter post", Vector3.new(0.8, 8.5, 0.8), center + Vector3.new(side * 9.5, 4.8, -4),
			forward, Color3.fromRGB(72, 82, 76), Enum.Material.Metal)
	end
	G.Box(parent, "Bus shelter back panel", Vector3.new(20, 6, 0.45), center + UP * 4.3 - forward * 5,
		forward, Color3.fromRGB(151, 181, 164), Enum.Material.Glass,
		{ transparency = 0.42, canTouch = false, canQuery = false })
	addBench(parent, center + forward * 1.5, forward, Color3.fromRGB(93, 106, 91))
	G.Sign(parent, "Bus route sign", center + UP * 7 + Vector3.new(-8, 0, 0), forward,
		6.5, 3.5, "GEDI NADU\nBUS STOP", Color3.fromRGB(34, 99, 69), Color3.fromRGB(255, 248, 219), Enum.Material.Metal)
end

local function addKavuGrove(parent)
	local center = Vector3.new(166, 0, 258)
	G.Part(parent, "Kavu grove paved connector", Vector3.new(15, 1, 8), CFrame.new(137.5, 0.12, 258),
		Color3.fromRGB(173, 164, 143), Enum.Material.Cobblestone)
	local stone = Color3.fromRGB(143, 126, 99)
	G.Part(parent, "Kavu grove stone apron", Vector3.new(42, 1, 36), CFrame.new(center + UP * 0.12),
		Color3.fromRGB(167, 154, 128), Enum.Material.Cobblestone)
	G.Part(parent, "Lotus pond stone rim", Vector3.new(25, 1.25, 19), CFrame.new(center + UP * 0.9),
		stone, Enum.Material.Slate)
	local water = G.Part(parent, "Kavu lotus pond", Vector3.new(21.5, 0.4, 15.5), CFrame.new(center + UP * 1.22),
		Color3.fromRGB(82, 145, 151), Enum.Material.Water,
		{ collide = false, canTouch = false, canQuery = false, transparency = 0.12, castShadow = false })
	water.Reflectance = 0.05
	for index = 1, 5 do
		local angle = index * math.pi * 2 / 5
		local flowerPosition = center + Vector3.new(math.cos(angle) * 6, 1.55, math.sin(angle) * 4)
		G.Part(parent, "Lotus leaf", Vector3.new(2.1, 0.15, 1.7), CFrame.new(flowerPosition),
			Color3.fromRGB(65, 132, 76), Enum.Material.Grass,
			{ shape = Enum.PartType.Ball, collide = false, canTouch = false, canQuery = false, castShadow = false })
	end
	G.Box(parent, "Kavu grove shrine plinth", Vector3.new(8, 1.1, 7), center + Vector3.new(14, 0.85, -8), SOUTH,
		stone, Enum.Material.Slate)
	G.Cylinder(parent, "Kavu grove stone marker", center + Vector3.new(14, 3.1, -8), 3.2, 4.2,
		Color3.fromRGB(117, 97, 71), Enum.Material.Slate)
	G.Sign(parent, "Kavu grove nameboard", center + Vector3.new(14, 7, 11), SOUTH,
		22, 3.2, "GEDI NADU KAVU", Color3.fromRGB(71, 91, 62), Color3.fromRGB(246, 239, 211), Enum.Material.WoodPlanks)
	addTree(parent, 146, 254, "palm", 0.72)
	addTree(parent, 186, 254, "shade", 0.78)
end

local function buildingSpecs()
	return {
		{ name = "Thenga House", x = -258, z = 78, width = 54, depth = 42, floors = 2, forward = SOUTH, style = "house", veranda = true, balcony = true, boundary = true, roofStyle = "pitched", wallColor = Color3.fromRGB(231, 203, 157), trimColor = Color3.fromRGB(248, 231, 194), roofColor = Color3.fromRGB(137, 70, 48), sign = "THENGA HOUSE", signColor = Color3.fromRGB(111, 70, 43), wallMaterial = Enum.Material.SmoothPlastic, plinthColor = Color3.fromRGB(140, 119, 91) },
		{ name = "Chaya Kada", x = -174, z = 74, width = 60, depth = 42, floors = 2, forward = SOUTH, style = "shop", balcony = true, roofStyle = "flat", wallColor = Color3.fromRGB(225, 180, 113), trimColor = Color3.fromRGB(255, 231, 180), roofColor = Color3.fromRGB(128, 69, 46), awningColor = Color3.fromRGB(157, 57, 43), sign = "CHAYA KADA", signColor = Color3.fromRGB(104, 54, 37), wallMaterial = Enum.Material.Brick },
		{ name = "Mango Grove Home", x = -92, z = 77, width = 52, depth = 36, floors = 1, forward = SOUTH, style = "house", veranda = true, boundary = true, roofStyle = "pitched", roofRise = 8, wallColor = Color3.fromRGB(195, 216, 165), trimColor = Color3.fromRGB(245, 235, 201), roofColor = Color3.fromRGB(130, 76, 55), sign = "MANGO GROVE", signColor = Color3.fromRGB(73, 105, 57), wallMaterial = Enum.Material.SmoothPlastic },
		{ name = "Nadu Mart", x = 91, z = 73, width = 56, depth = 44, floors = 2, forward = SOUTH, style = "shop", balcony = true, roofStyle = "flat", wallColor = Color3.fromRGB(210, 191, 157), trimColor = Color3.fromRGB(246, 229, 192), roofColor = Color3.fromRGB(123, 73, 50), awningColor = Color3.fromRGB(37, 112, 91), sign = "NADU MART", signColor = Color3.fromRGB(28, 92, 75), wallMaterial = Enum.Material.Concrete },
		{ name = "Gedi Nadu Hospital", x = 175, z = 78, width = 72, depth = 54, floors = 2, forward = SOUTH, style = "civic", roofStyle = "flat", wallColor = Color3.fromRGB(226, 230, 216), trimColor = Color3.fromRGB(192, 210, 190), roofColor = Color3.fromRGB(143, 158, 143), sign = "GEDI NADU HOSPITAL", signColor = Color3.fromRGB(37, 112, 86), signTextColor = Color3.fromRGB(255, 255, 242), wallMaterial = Enum.Material.Concrete, plinthColor = Color3.fromRGB(151, 163, 144) },
		{ name = "Kavu House", x = 260, z = 78, width = 54, depth = 40, floors = 1, forward = SOUTH, style = "house", veranda = true, boundary = true, roofStyle = "pitched", wallColor = Color3.fromRGB(224, 187, 166), trimColor = Color3.fromRGB(250, 229, 206), roofColor = Color3.fromRGB(129, 66, 52), sign = "KAVU HOUSE", signColor = Color3.fromRGB(105, 59, 48), wallMaterial = Enum.Material.SmoothPlastic },
		{ name = "Riverbend Stores", x = -258, z = -74, width = 56, depth = 40, floors = 1, forward = NORTH, style = "shop", roofStyle = "pitched", roofRise = 7, wallColor = Color3.fromRGB(230, 197, 128), trimColor = Color3.fromRGB(250, 232, 185), roofColor = Color3.fromRGB(130, 72, 46), awningColor = Color3.fromRGB(171, 83, 55), sign = "RIVERBEND STORES", signColor = Color3.fromRGB(117, 64, 43), wallMaterial = Enum.Material.Brick },
		{ name = "Gedi Nadu Police Station", x = -174, z = -76, width = 66, depth = 50, floors = 2, forward = NORTH, style = "civic", roofStyle = "flat", wallColor = Color3.fromRGB(214, 219, 201), trimColor = Color3.fromRGB(177, 190, 159), roofColor = Color3.fromRGB(125, 143, 125), sign = "GEDI NADU POLICE", signColor = Color3.fromRGB(28, 75, 105), signTextColor = Color3.fromRGB(255, 255, 241), wallMaterial = Enum.Material.Concrete, plinthColor = Color3.fromRGB(136, 150, 133) },
		{ name = "Jackfruit House", x = -88, z = -75, width = 54, depth = 40, floors = 2, forward = NORTH, style = "house", veranda = true, balcony = true, boundary = true, roofStyle = "pitched", wallColor = Color3.fromRGB(204, 218, 170), trimColor = Color3.fromRGB(248, 235, 193), roofColor = Color3.fromRGB(142, 75, 50), sign = "JACKFRUIT HOME", signColor = Color3.fromRGB(68, 106, 56), wallMaterial = Enum.Material.SmoothPlastic },
		{ name = "Spice & Rice", x = 91, z = -74, width = 56, depth = 42, floors = 2, forward = NORTH, style = "shop", balcony = true, roofStyle = "pitched", roofRise = 7, wallColor = Color3.fromRGB(220, 175, 132), trimColor = Color3.fromRGB(251, 227, 196), roofColor = Color3.fromRGB(129, 70, 48), awningColor = Color3.fromRGB(181, 128, 45), sign = "SPICE & RICE", signColor = Color3.fromRGB(121, 77, 30), wallMaterial = Enum.Material.Brick },
		{ name = "Ponnamma Villa", x = 174, z = -77, width = 54, depth = 38, floors = 1, forward = NORTH, style = "house", veranda = true, boundary = true, roofStyle = "pitched", roofRise = 11, eaveOverhang = 5, wallColor = Color3.fromRGB(230, 207, 169), trimColor = Color3.fromRGB(247, 231, 199), roofColor = Color3.fromRGB(126, 66, 48), sign = "PONNAMMA VILLA", signColor = Color3.fromRGB(112, 76, 45), wallMaterial = Enum.Material.SmoothPlastic },
		{ name = "Blue Heron House", x = 258, z = -74, width = 54, depth = 40, floors = 2, forward = NORTH, style = "house", veranda = true, balcony = true, roofStyle = "pitched", roofRise = 9, wallColor = Color3.fromRGB(179, 211, 205), trimColor = Color3.fromRGB(239, 234, 208), roofColor = Color3.fromRGB(119, 73, 53), sign = "BLUE HERON", signColor = Color3.fromRGB(44, 98, 102), wallMaterial = Enum.Material.SmoothPlastic },
	}
end

function Layout.Build(parent)
	G.Part(parent, "Town grass base", Vector3.new(760, 1, 640), CFrame.new(0, -0.65, 0),
		Color3.fromRGB(111, 146, 91), Enum.Material.Grass)

	-- Preserve the prototype's road names, widths, and connections while adding drains and crossings.
	road(parent, "X", 0, 0, 620, 48, "Main Street", true)
	road(parent, "Z", 0, 0, 500, 44, "Market Avenue", true)
	road(parent, "X", 0, 174, 560, 26, "North Cross Street", true)
	road(parent, "X", 0, -174, 560, 26, "South Cross Street", true)
	crosswalk(parent, "X", 0, 0, -30, 48, "Main Street west crossing")
	crosswalk(parent, "X", 0, 0, 30, 48, "Main Street east crossing")
	crosswalk(parent, "Z", 0, 0, -28, 44, "Market Avenue south crossing")
	crosswalk(parent, "Z", 0, 0, 28, 44, "Market Avenue north crossing")
	crosswalk(parent, "X", 0, 174, 22, 26, "North Street crossing")
	crosswalk(parent, "X", 0, -174, 22, 26, "South Street crossing")

	for _, spec in ipairs(buildingSpecs()) do
		BuildingFactory.Build(parent, spec)
	end

	-- A narrow arrival apron preserves the northbound road connection and leads into the plaza beside it.
	G.Part(parent, "Town square arrival apron", Vector3.new(44, 0.35, 24), CFrame.new(0, 0.025, 261),
		G.Colors.road, Enum.Material.Asphalt)
	G.Part(parent, "Town square west connection", Vector3.new(10, 1, 12), CFrame.new(26, 0.12, 260),
		Color3.fromRGB(190, 183, 163), Enum.Material.Cobblestone)
	-- Small gated yards and mixed setbacks break up the continuous row of facades.
	G.Part(parent, "Town square paving", Vector3.new(100, 1, 76), CFrame.new(80, 0.12, 260),
		Color3.fromRGB(190, 183, 163), Enum.Material.Cobblestone)
	G.Part(parent, "Town square inset", Vector3.new(50, 0.18, 34), CFrame.new(80, 0.72, 260),
		Color3.fromRGB(163, 179, 143), Enum.Material.Grass)
	for _, position in ipairs({ Vector3.new(48, 0, 260), Vector3.new(112, 0, 260) }) do
		local planterColor = Color3.fromRGB(141, 128, 102)
		for _, side in ipairs({ -1, 1 }) do
			G.Box(parent, "Town square planter wall", Vector3.new(12, 0.9, 0.75),
				position + UP * 1.02 + Vector3.new(0, 0, side * 5.6), SOUTH, planterColor, Enum.Material.Brick)
			G.Box(parent, "Town square planter wall", Vector3.new(0.75, 0.9, 10.8),
				position + UP * 1.02 + Vector3.new(side * 5.6, 0, 0), SOUTH, planterColor, Enum.Material.Brick)
		end
		G.Part(parent, "Planter soil", Vector3.new(10.3, 0.14, 10.3), CFrame.new(position + UP * 0.7),
			Color3.fromRGB(91, 111, 65), Enum.Material.Ground, { collide = false, canTouch = false, canQuery = false })
	end
	addTree(parent, 48, 260, "palm", 0.8)
	addTree(parent, 112, 260, "shade", 0.8)
	addBench(parent, Vector3.new(63, 0, 260), SOUTH)
	addBench(parent, Vector3.new(97, 0, 260), NORTH)

	local entrySignPosition = Vector3.new(0, 12, 302)
	G.Cylinder(parent, "Welcome sign post", Vector3.new(-18, 6, 302), 1.4, 12, G.Colors.wood, Enum.Material.Wood)
	G.Cylinder(parent, "Welcome sign post", Vector3.new(18, 6, 302), 1.4, 12, G.Colors.wood, Enum.Material.Wood)
	G.Sign(parent, "Welcome to Gedi Nadu", entrySignPosition, SOUTH, 40, 9,
		"GEDI NADU  •  NAMASKARAM", Color3.fromRGB(44, 100, 72), Color3.fromRGB(255, 242, 202), Enum.Material.WoodPlanks)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Town Square Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 1.05, 260)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = parent

	-- Compact local destinations: a shaded bus shelter and a small community Kavu grove.
	addBusShelter(parent)
	addKavuGrove(parent)

	for _, tree in ipairs({
		{ -285, 29, "palm", 0.85 }, { 285, 29, "palm", 0.85 },
		{ -285, -29, "palm", 0.85 }, { 285, -29, "palm", 0.85 },
		{ -282, 132, "shade", 0.9 }, { 282, 132, "shade", 0.9 },
		{ -282, -132, "shade", 0.9 }, { 282, -132, "shade", 0.9 },
		{ -245, 218, "palm", 0.9 }, { 245, 218, "palm", 0.9 },
		{ -245, -218, "palm", 0.9 }, { 245, -218, "palm", 0.9 },
	}) do
		addTree(parent, tree[1], tree[2], tree[3], tree[4])
	end

	for index, lamp in ipairs({
		{ -110, 31, SOUTH }, { 110, 31, SOUTH }, { -110, -31, NORTH }, { 110, -31, NORTH },
		{ -275, 31, SOUTH }, { 275, 31, SOUTH }, { -275, -31, NORTH }, { 275, -31, NORTH },
		{ 0, 145, EAST }, { 0, -145, WEST },
	}) do
		addStreetlight(parent, lamp[1], lamp[2], lamp[3], index <= 4)
	end

	for _, streetSign in ipairs({
		{ Vector3.new(-32, 10, 27), SOUTH, "MARKET AVE" },
		{ Vector3.new(32, 10, -27), NORTH, "MAIN STREET" },
		{ Vector3.new(20, 9, 162), SOUTH, "HOSPITAL  →" },
	}) do
		G.Sign(parent, "Street name sign", streetSign[1], streetSign[2], 12, 2.5,
			streetSign[3], Color3.fromRGB(40, 94, 68), Color3.fromRGB(255, 248, 220), Enum.Material.Metal)
	end
end

return Layout
