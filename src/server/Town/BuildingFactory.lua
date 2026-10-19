local G = require(script.Parent.Geometry)
local Factory = {}
local UP = Vector3.yAxis
local FLOOR_BASE = 0.32
local FLOOR_HEIGHT = 13.4
local WALL_THICKNESS = 1.2
local WOOD = Color3.fromRGB(105, 68, 43)
local TRIM = Color3.fromRGB(245, 228, 191)

local function sortedUnique(values)
	table.sort(values)
	local result = {}
	for _, value in ipairs(values) do
		if #result == 0 or math.abs(value - result[#result]) > 0.001 then
			table.insert(result, value)
		end
	end
	return result
end

local function cutWall(parent, name, base, normal, span, height, thickness, openings, color, material)
	local right = normal:Cross(UP).Unit
	local xs, ys = { -span / 2, span / 2 }, { 0, height }
	local holes = {}
	for _, opening in ipairs(openings) do
		local left = math.max(-span / 2 + 0.1, opening.u - opening.width / 2)
		local rightEdge = math.min(span / 2 - 0.1, opening.u + opening.width / 2)
		local bottom = math.max(0.05, opening.bottom)
		local top = math.min(height - 0.05, opening.bottom + opening.height)
		if rightEdge > left and top > bottom then
			table.insert(xs, left)
			table.insert(xs, rightEdge)
			table.insert(ys, bottom)
			table.insert(ys, top)
			table.insert(holes, { left = left, right = rightEdge, bottom = bottom, top = top })
		end
	end
	xs, ys = sortedUnique(xs), sortedUnique(ys)
	for xi = 1, #xs - 1 do
		for yi = 1, #ys - 1 do
			local left, rightEdge = xs[xi], xs[xi + 1]
			local bottom, top = ys[yi], ys[yi + 1]
			local midX, midY = (left + rightEdge) / 2, (bottom + top) / 2
			local isHole = false
			for _, hole in ipairs(holes) do
				if midX > hole.left and midX < hole.right and midY > hole.bottom and midY < hole.top then
					isHole = true
					break
				end
			end
			if not isHole and rightEdge - left > 0.1 and top - bottom > 0.1 then
				G.Box(parent, name, Vector3.new(rightEdge - left, top - bottom, thickness),
					base + right * midX + UP * midY, normal, color, material,
					{ canTouch = false })
			end
		end
	end
	return right
end

local function exteriorOpenings(spec, face, story, span, wallHeight)
	local openings = {}
	if face == "front" then
		if story == 0 then
			table.insert(openings, { kind = "door", u = spec.doorOffset or 0, bottom = 0,
				width = spec.doorWidth or 6.4, height = spec.doorHeight or 10.1 })
		elseif story == 1 and spec.balcony then
			table.insert(openings, { kind = "door", u = 0, bottom = 0, width = 7.2, height = 10.2 })
		end
		local openingWidth = spec.style == "shop" and story == 0 and 10.5 or (spec.style == "civic" and 8 or 7.2)
		for _, u in ipairs({ -span * 0.29, span * 0.29 }) do
			table.insert(openings, { kind = "window", u = u, bottom = 3.1,
				width = openingWidth, height = spec.style == "civic" and 7.3 or 6.8 })
		end
		if story > 0 and not (story == 1 and spec.balcony) and span > 48 then
			table.insert(openings, { kind = "window", u = 0, bottom = 3.3, width = 7.2, height = 6.8 })
		end
	elseif face == "back" then
		if story == 0 and spec.backDoor then
			table.insert(openings, { kind = "door", u = 0, bottom = 0, width = 5.5, height = 9.6 })
		end
		for _, u in ipairs({ -span * 0.25, span * 0.25 }) do
			table.insert(openings, { kind = "window", u = u, bottom = 3.1, width = 6.2, height = 6.5 })
		end
	else
		for _, u in ipairs({ -span * 0.24, span * 0.24 }) do
			table.insert(openings, { kind = "window", u = u, bottom = 3.2, width = 5.6, height = 6.2 })
		end
	end
	for _, opening in ipairs(openings) do
		opening.bottom = math.clamp(opening.bottom, 0, wallHeight - opening.height - 0.5)
	end
	return openings
end

local function addWindowDetails(parent, base, normal, right, opening, thickness, traditional, civic)
	local center = base + right * opening.u + UP * (opening.bottom + opening.height / 2)
	local outside = center + normal * (thickness / 2 + 0.13)
	local frameColor = civic and Color3.fromRGB(224, 229, 216) or TRIM
	local frame = 0.55
	local glassSize = Vector3.new(opening.width - frame * 2, opening.height - frame * 2, 0.25)
	G.Box(parent, "Recessed window glass", glassSize, center - normal * 0.15, normal, G.Colors.glass,
		Enum.Material.Glass, { transparency = 0.28, canTouch = false, canQuery = false, castShadow = false })
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Window jamb", Vector3.new(frame, opening.height + 0.2, 0.7),
			outside + right * side * (opening.width / 2 - frame / 2), normal, frameColor, Enum.Material.Wood,
			{ collide = false, canTouch = false, canQuery = false })
	end
	G.Box(parent, "Window lintel", Vector3.new(opening.width + 0.25, frame, 0.85),
		outside + UP * (opening.height / 2 - frame / 2), normal, frameColor, Enum.Material.Wood,
		{ collide = false, canTouch = false, canQuery = false })
	G.Box(parent, "Deep window sill", Vector3.new(opening.width + 1.1, 0.65, 1.45),
		outside + UP * (-opening.height / 2 + 0.22) + normal * 0.22, normal,
		traditional and Color3.fromRGB(188, 157, 111) or frameColor, Enum.Material.Concrete,
		{ collide = false, canTouch = false, canQuery = false })
	if traditional then
		for _, side in ipairs({ -1, 1 }) do
			G.Box(parent, "Timber shutter", Vector3.new(1.3, opening.height - 0.25, 0.6),
				outside + right * side * (opening.width / 2 + 0.85), normal,
				Color3.fromRGB(108, 70, 42), Enum.Material.WoodPlanks,
				{ collide = false, canTouch = false, canQuery = false })
		end
		G.Box(parent, "Timber window rail", Vector3.new(opening.width - 1.2, 0.3, 0.3),
			outside + UP * 0.15 + normal * 0.2, normal, frameColor, Enum.Material.Wood,
			{ collide = false, canTouch = false, canQuery = false })
	elseif civic then
		G.Box(parent, "Civic window mullion", Vector3.new(0.35, opening.height - 1.1, 0.35),
			outside + normal * 0.2, normal, frameColor, Enum.Material.Metal,
			{ collide = false, canTouch = false, canQuery = false })
	end
end

local function addDoorDetails(parent, spec, base, normal, right, opening, thickness)
	local center = base + right * opening.u + UP * (opening.bottom + opening.height / 2)
	local outside = center + normal * (thickness / 2 + 0.15)
	local trim = spec.trimColor or TRIM
	local jamb = 0.65
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Door jamb", Vector3.new(jamb, opening.height + 0.3, 0.9),
			outside + right * side * (opening.width / 2 - jamb / 2), normal, trim, Enum.Material.Wood,
			{ collide = false, canTouch = false, canQuery = false })
	end
	G.Box(parent, "Door lintel", Vector3.new(opening.width + 0.5, 0.7, 1),
		outside + UP * (opening.height / 2 - 0.25), normal, trim, Enum.Material.Wood,
		{ collide = false, canTouch = false, canQuery = false })
	G.Box(parent, "Stone door threshold", Vector3.new(opening.width + 0.4, 0.35, 1.4),
		outside + UP * (-opening.height / 2 + 0.1) + normal * 0.2, normal,
		Color3.fromRGB(153, 144, 124), Enum.Material.Stone,
		{ collide = false, canTouch = false, canQuery = false })
	-- The visible leaf is hinged partly open and non-colliding; the doorway remains traversable.
	local hinge = center + right * (-opening.width / 2 + 0.5) + normal * (thickness / 2 + 0.28)
	local doorCFrame = G.Facing(hinge, normal) * CFrame.Angles(0, math.rad(-48), 0)
		* CFrame.new((opening.width - 0.8) / 2, 0, 0)
	G.Part(parent, "Open non-colliding door leaf", Vector3.new(opening.width - 0.8, opening.height - 0.45, 0.45),
		doorCFrame, spec.doorColor or WOOD, Enum.Material.WoodPlanks,
		{ collide = false, canTouch = false, canQuery = false })
end

local function buildExteriorWall(parent, spec, center, normal, span, perpendicularDepth, floorBase, story, wallHeight, face, thickness)
	local openings = exteriorOpenings(spec, face, story, span, wallHeight)
	local base = center + normal * (perpendicularDepth / 2 - thickness / 2) + UP * (floorBase + 0.25)
	local right = cutWall(parent, "Cut exterior wall panel", base, normal, span, wallHeight, thickness,
		openings, spec.wallColor, spec.wallMaterial or Enum.Material.SmoothPlastic)
	for _, opening in ipairs(openings) do
		if opening.kind == "door" then
			addDoorDetails(parent, spec, base, normal, right, opening, thickness)
		else
			addWindowDetails(parent, base, normal, right, opening, thickness,
				spec.style == "house", spec.style == "civic")
		end
	end
end

local function addBalcony(parent, center, forward, width, depth, floorBase)
	local right = forward:Cross(UP).Unit
	local balconyWidth = math.min(width * 0.42, 20)
	G.Box(parent, "Balcony slab", Vector3.new(balconyWidth, 0.65, 5.5),
		center + forward * (depth / 2 + 2.5) + UP * (floorBase + 0.45), forward,
		Color3.fromRGB(159, 151, 132), Enum.Material.Concrete)
	local railY = floorBase + 3.6
	local railColor = Color3.fromRGB(76, 82, 78)
	G.Box(parent, "Balcony handrail", Vector3.new(balconyWidth, 0.35, 0.35),
		center + forward * (depth / 2 + 5.2) + UP * railY, forward, railColor, Enum.Material.Metal,
		{ canTouch = false, canQuery = false })
	for index = 0, 5 do
		local u = -balconyWidth / 2 + index * balconyWidth / 5
		G.Box(parent, "Balcony baluster", Vector3.new(0.3, 2.6, 0.3),
			center + right * u + forward * (depth / 2 + 5.2) + UP * (railY - 1.4), forward,
			railColor, Enum.Material.Metal, { canTouch = false, canQuery = false })
	end
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Balcony side rail", Vector3.new(0.35, 0.35, 5.2),
			center + right * side * balconyWidth / 2 + forward * (depth / 2 + 2.5) + UP * railY,
			forward, railColor, Enum.Material.Metal, { canTouch = false, canQuery = false })
	end
end

local function addVeranda(parent, spec, center, forward, width, depth)
	local right = forward:Cross(UP).Unit
	local verandaWidth = math.min(width - 8, 30)
	local verandaDepth = 7
	G.Box(parent, "Veranda stone deck", Vector3.new(verandaWidth, 0.35, verandaDepth),
		center + forward * (depth / 2 + verandaDepth / 2 - 0.5) + UP * (FLOOR_BASE + 0.075),
		forward, Color3.fromRGB(173, 161, 136), Enum.Material.Slate)
	local roofY = FLOOR_BASE + 10.7
	G.Box(parent, "Deep veranda eave", Vector3.new(verandaWidth + 2, 0.9, verandaDepth + 1.5),
		center + forward * (depth / 2 + verandaDepth / 2) + UP * roofY, forward,
		spec.roofColor, Enum.Material.WoodPlanks)
	for side = -1, 1, 2 do
		G.Cylinder(parent, "Veranda timber column",
			center + right * side * (verandaWidth / 2 - 1.1) + forward * (depth / 2 + verandaDepth - 0.5)
				+ UP * ((roofY + FLOOR_BASE) / 2), 1.15, roofY - FLOOR_BASE,
			Color3.fromRGB(139, 97, 58), Enum.Material.Wood)
		G.Box(parent, "Veranda low side rail", Vector3.new(0.45, 2.7, verandaDepth - 1),
			center + right * side * (verandaWidth / 2 - 0.25) + forward * (depth / 2 + verandaDepth / 2 - 0.5)
				+ UP * (FLOOR_BASE + 1.85), forward, spec.trimColor, Enum.Material.Wood)
	end
end

local function addBoundary(parent, spec, center, forward, right, width, depth)
	if not spec.boundary then
		return
	end
	local wallColor = spec.boundaryColor or Color3.fromRGB(150, 129, 101)
	local sideLength = depth * 0.78
	for _, side in ipairs({ -1, 1 }) do
		local position = center + right * side * (width / 2 + 3.8) + UP * 2.15
		G.Box(parent, "Laterite boundary wall", Vector3.new(0.65, 4.3, sideLength), position, forward,
			wallColor, Enum.Material.Brick)
		G.Box(parent, "Boundary wall cap", Vector3.new(1.05, 0.45, sideLength), position + UP * 2.35,
			forward, Color3.fromRGB(190, 164, 128), Enum.Material.Sandstone,
			{ collide = false, canTouch = false, canQuery = false })
	end
	local front = center + forward * (depth / 2 + 1.2) + UP * 1.6
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Front yard wall", Vector3.new((width - 12) / 2, 3.2, 0.7),
			front + right * side * (width / 4 + 3), forward, wallColor, Enum.Material.Brick)
	end
end

local function worldAt(center, forward, right, width, depth, u, fromFront, y)
	return center + right * u + forward * (depth / 2 - fromFront) + UP * y
end

local function addPartition(parent, center, forward, depth, depthFromFront, span, height, uOffset, color)
	local base = center + forward * (depth / 2 - depthFromFront) + UP * 0.5
	cutWall(parent, "Interior partition", base, forward, span, height, 0.65,
		{ { kind = "door", u = uOffset or 0, bottom = 0, width = 5.5, height = 9.2 } },
		color or Color3.fromRGB(225, 218, 198), Enum.Material.SmoothPlastic)
end

local function addCounter(parent, center, forward, right, width, depth, u, fromFront, name, color)
	local position = worldAt(center, forward, right, width, depth, u, fromFront, 1.8)
	G.Box(parent, name, Vector3.new(12, 2.6, 2.5), position, forward,
		color or Color3.fromRGB(135, 94, 57), Enum.Material.WoodPlanks)
	G.Box(parent, "Counter top", Vector3.new(13, 0.35, 3.1), position + UP * 1.45, forward,
		Color3.fromRGB(201, 185, 151), Enum.Material.Marble)
end

local function addSeat(parent, position, forward, color)
	local wood = color or Color3.fromRGB(111, 82, 57)
	G.Box(parent, "Roleplay chair seat", Vector3.new(2.4, 0.55, 2.2), position + UP * 1.4, forward, wood, Enum.Material.WoodPlanks)
	G.Box(parent, "Roleplay chair back", Vector3.new(2.4, 2.2, 0.5), position + UP * 2.55 - forward * 0.8,
		forward, wood, Enum.Material.WoodPlanks)
	for _, side in ipairs({ -1, 1 }) do
		for _, depthSign in ipairs({ -1, 1 }) do
			G.Box(parent, "Chair leg", Vector3.new(0.3, 1.2, 0.3),
				position + UP * 0.6 + Vector3.new(side * 0.85, 0, 0) + forward * depthSign * 0.75,
				forward, Color3.fromRGB(86, 75, 61), Enum.Material.Wood)
		end
	end
end

local function addBed(parent, position, forward, label)
	G.Box(parent, label, Vector3.new(7.5, 1, 3.5), position + UP * 1.25,
		forward, Color3.fromRGB(226, 224, 210), Enum.Material.Fabric)
	G.Box(parent, "Bed frame", Vector3.new(7.8, 0.55, 3.8), position + UP * 0.65,
		forward, Color3.fromRGB(116, 122, 117), Enum.Material.Metal)
	G.Box(parent, "Bed pillow", Vector3.new(2, 0.45, 2.8), position + UP * 1.95 - forward * 2.2,
		forward, Color3.fromRGB(244, 242, 226), Enum.Material.Fabric,
		{ collide = false, canTouch = false, canQuery = false })
end

local function addStairs(parent, center, forward, right, width, depth, floorHeight)
	local count, tread = 9, 1.65
	local rise, startDepth = (floorHeight - 0.25) / count, depth - 3
	for index = 1, count do
		local stepHeight = rise * index
		G.Box(parent, "Interior stair tread", Vector3.new(4.2, stepHeight, tread),
			worldAt(center, forward, right, width, depth, -width * 0.31, startDepth - (index - 0.5) * tread, FLOOR_BASE + stepHeight / 2),
			forward, Color3.fromRGB(151, 111, 76), Enum.Material.WoodPlanks)
	end
	local start = worldAt(center, forward, right, width, depth, -width * 0.31 + 2.5,
		startDepth - tread / 2, FLOOR_BASE + 1.8)
	local finish = worldAt(center, forward, right, width, depth, -width * 0.31 + 2.5,
		startDepth - count * tread + tread / 2, FLOOR_BASE + floorHeight - 1.2)
	local delta = finish - start
	G.Part(parent, "Stair handrail", Vector3.new(0.35, 0.35, delta.Magnitude),
		CFrame.lookAt((start + finish) / 2, (start + finish) / 2 + delta),
		Color3.fromRGB(92, 70, 50), Enum.Material.Wood, { canTouch = false, canQuery = false })
end

local function addShopInterior(parent, center, forward, right, width, depth)
	addPartition(parent, center, forward, depth, depth * 0.54, width - 4, 10.8, -width * 0.31, Color3.fromRGB(218, 205, 177))
	addCounter(parent, center, forward, right, width, depth, width * 0.19, depth * 0.34,
		"Shop service counter", Color3.fromRGB(132, 83, 48))
	for _, side in ipairs({ -1, 1 }) do
		local position = worldAt(center, forward, right, width, depth, side * width * 0.34, depth * 0.64, 4.5)
		G.Box(parent, "Shop shelving", Vector3.new(3.2, 8.5, 1.4), position, forward,
			Color3.fromRGB(124, 87, 55), Enum.Material.WoodPlanks)
		for level = 1, 2 do
			G.Box(parent, "Shop shelf tier", Vector3.new(3.7, 0.35, 1.8), position + UP * (level * 2.4), forward,
				Color3.fromRGB(190, 147, 87), Enum.Material.WoodPlanks,
				{ collide = false, canTouch = false, canQuery = false })
		end
	end
	G.Box(parent, "Market produce crate", Vector3.new(3.2, 2.4, 3.2),
		worldAt(center, forward, right, width, depth, -width * 0.28, depth * 0.25, 1.3), forward,
		Color3.fromRGB(145, 98, 50), Enum.Material.WoodPlanks)
end

local function addHomeInterior(parent, center, forward, right, width, depth)
	addPartition(parent, center, forward, depth, depth * 0.48, width - 4, 10.6, -width * 0.31, Color3.fromRGB(229, 218, 192))
	local tablePosition = worldAt(center, forward, right, width, depth, -width * 0.18, depth * 0.28, 1.4)
	G.Box(parent, "Family dining table", Vector3.new(7, 0.5, 4), tablePosition, forward,
		Color3.fromRGB(127, 81, 48), Enum.Material.WoodPlanks)
	for _, side in ipairs({ -1, 1 }) do
		addSeat(parent, tablePosition + right * side * 4 - UP * 1.4, forward, Color3.fromRGB(121, 87, 59))
	end
	local kitchen = worldAt(center, forward, right, width, depth, width * 0.3, depth * 0.7, 1.7)
	G.Box(parent, "Kitchen counter", Vector3.new(8, 2.5, 2), kitchen, forward,
		Color3.fromRGB(159, 148, 125), Enum.Material.Concrete)
	G.Box(parent, "Kitchen worktop", Vector3.new(8.4, 0.35, 2.4), kitchen + UP * 1.4, forward,
		Color3.fromRGB(207, 203, 183), Enum.Material.Marble)
	addBed(parent, worldAt(center, forward, right, width, depth, width * 0.27, depth * 0.72, 0), forward, "Home bed")
end

local function addHospitalInterior(parent, center, forward, right, width, depth)
	addPartition(parent, center, forward, depth, depth * 0.53, width - 5, 11.2, -width * 0.31, Color3.fromRGB(216, 225, 213))
	addPartition(parent, center, forward, depth, depth * 0.79, width * 0.44, 10.8, 0, Color3.fromRGB(216, 225, 213))
	addCounter(parent, center, forward, right, width, depth, width * 0.22, depth * 0.33,
		"Hospital reception counter", Color3.fromRGB(49, 111, 91))
	for index = 1, 3 do
		local u = -width * 0.3 + (index - 1) * 5.7
		addSeat(parent, worldAt(center, forward, right, width, depth, u, depth * 0.2, 0), forward,
			Color3.fromRGB(91, 116, 105))
	end
	addBed(parent, worldAt(center, forward, right, width, depth, -width * 0.2, depth * 0.72, 0), forward, "Hospital examination bed")
	addBed(parent, worldAt(center, forward, right, width, depth, width * 0.2, depth * 0.72, 0), forward, "Hospital examination bed")
	G.Box(parent, "Hospital privacy screen", Vector3.new(8, 7, 0.35),
		worldAt(center, forward, right, width, depth, 0, depth * 0.72, 4), forward,
		Color3.fromRGB(164, 192, 170), Enum.Material.Fabric,
		{ collide = false, canTouch = false, canQuery = false })
end

local function addPoliceInterior(parent, center, forward, right, width, depth)
	addPartition(parent, center, forward, depth, depth * 0.55, width - 5, 11.2, -width * 0.31, Color3.fromRGB(205, 217, 208))
	addCounter(parent, center, forward, right, width, depth, width * 0.2, depth * 0.34,
		"Police reception desk", Color3.fromRGB(44, 82, 105))
	G.Box(parent, "Police duty desk", Vector3.new(8, 2.3, 4),
		worldAt(center, forward, right, width, depth, -width * 0.24, depth * 0.7, 1.4), forward,
		Color3.fromRGB(95, 106, 101), Enum.Material.WoodPlanks)
	for cell = 1, 2 do
		local u = (cell == 1 and -1 or 1) * width * 0.22
		local back = worldAt(center, forward, right, width, depth, u, depth * 0.89, 0)
		G.Box(parent, "Holding cell back", Vector3.new(width * 0.33, 9, 0.6), back + UP * 4.8,
			forward, Color3.fromRGB(197, 205, 197), Enum.Material.Concrete)
		for bar = -2, 2 do
			G.Cylinder(parent, "Holding cell bar", back + right * (bar * 1.2) + UP * 4.8,
				0.24, 9, Color3.fromRGB(84, 95, 95), Enum.Material.Metal, { canTouch = false })
		end
	end
end

local function addRoof(parent, spec, center, forward, width, depth, roofY)
	local right = forward:Cross(UP).Unit
	if spec.roofStyle == "flat" then
		G.Box(parent, "Civic roof deck", Vector3.new(width + 4, 1.2, depth + 4), center + UP * roofY,
			forward, spec.roofColor, Enum.Material.Concrete)
		local parapetY = roofY + 2.2
		for _, side in ipairs({ -1, 1 }) do
			G.Box(parent, "Roof parapet side", Vector3.new(1.1, 3.1, depth + 4),
				center + right * side * (width / 2 + 1.8) + UP * parapetY,
				forward, spec.trimColor, Enum.Material.Concrete)
			G.Box(parent, "Roof parapet end", Vector3.new(width + 4, 3.1, 1.1),
				center + forward * side * (depth / 2 + 1.8) + UP * parapetY,
				forward, spec.trimColor, Enum.Material.Concrete)
		end
		return
	end

	local overhang = spec.eaveOverhang or 4
	local halfWidth = width / 2 + overhang
	local rise = spec.roofRise or (spec.style == "house" and 10 or 6)
	local slopeLength = math.sqrt(halfWidth * halfWidth + rise * rise)
	local angle = math.atan(rise / halfWidth)
	for _, side in ipairs({ -1, 1 }) do
		local position = center + right * side * (halfWidth / 2) + UP * (roofY + rise / 2)
		local cf = G.Facing(position, forward) * CFrame.Angles(0, 0, -side * angle)
		G.Part(parent, "Overhanging tiled roof slope", Vector3.new(slopeLength, 0.9, depth + overhang * 2),
			cf, spec.roofColor, Enum.Material.RoofShingles)
	end
	-- Paired wedge infills close each triangular gable end while leaving the shell opening-based.
	for _, endSide in ipairs({ -1, 1 }) do
		local normal = forward * endSide
		local endRight = normal:Cross(UP).Unit
		for _, side in ipairs({ -1, 1 }) do
			local position = center + normal * (depth / 2 - WALL_THICKNESS / 2)
				+ endRight * side * (width / 4) + UP * (roofY + rise / 2)
			local cf = G.Facing(position, normal)
			if side < 0 then
				cf = cf * CFrame.Angles(0, math.pi, 0)
			end
			G.Part(parent, "Masonry gable infill", Vector3.new(width / 2 + 0.1, rise, WALL_THICKNESS),
				cf, spec.wallColor, spec.wallMaterial or Enum.Material.SmoothPlastic, { className = "WedgePart" })
		end
	end
	G.Box(parent, "Terracotta ridge cap", Vector3.new(1.1, 1.1, depth + overhang * 2),
		center + UP * (roofY + rise), forward, spec.roofColor, Enum.Material.RoofShingles,
		{ collide = false, canTouch = false, canQuery = false })
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Eave fascia", Vector3.new(0.8, 1.1, depth + overhang * 2),
			center + right * side * halfWidth * 0.98 + UP * (roofY + 0.1), forward,
			spec.trimColor, Enum.Material.WoodPlanks, { collide = false, canTouch = false, canQuery = false })
	end
end

local function addFacade(parent, spec, center, forward, width, depth, floors)
	local right = forward:Cross(UP).Unit
	local wallFace = center + forward * (depth / 2 + 0.45)
	if spec.style == "shop" then
		local awningY = 9.5
		G.Box(parent, "Shop awning", Vector3.new(width - 8, 0.8, 5.5), wallFace + UP * awningY, forward,
			spec.awningColor, Enum.Material.Fabric, { collide = false, canTouch = false, canQuery = false })
		for stripe = -2, 2 do
			G.Box(parent, "Awning valance stripe", Vector3.new((width - 10) / 6, 1.15, 0.55),
				wallFace + right * stripe * ((width - 10) / 5) + UP * (awningY - 0.82), forward,
				Color3.fromRGB(246, 233, 202), Enum.Material.Fabric,
				{ collide = false, canTouch = false, canQuery = false })
		end
	end
	G.Sign(parent, "Facade sign - " .. spec.sign, wallFace + UP * 11.7, forward,
		math.min(width - 12, spec.style == "civic" and 38 or 31), 2.8, spec.sign,
		spec.signColor or Color3.fromRGB(95, 65, 42), spec.signTextColor or Color3.fromRGB(255, 245, 218))
	if spec.style == "civic" then
		G.Sign(parent, "Civic vertical sign", wallFace + right * (width / 2 - 3) + UP * 20, forward,
			2.5, 8, spec.name == "Gedi Nadu Hospital" and "CARE" or "POLICE",
			spec.signColor, Color3.fromRGB(255, 255, 241), Enum.Material.Metal)
	end
	if floors > 1 then
		G.Box(parent, "Upper storey sunshade", Vector3.new(width - 10, 0.55, 2.2),
			wallFace + UP * (FLOOR_HEIGHT + 11.9), forward, spec.trimColor, Enum.Material.Concrete,
			{ collide = false, canTouch = false, canQuery = false })
	end
end

local function addVerandaAndSteps(parent, spec, center, forward, width, depth)
	if spec.veranda then
		local right = forward:Cross(UP).Unit
		local verandaWidth, verandaDepth = math.min(width - 8, 30), 7
		G.Box(parent, "Veranda stone deck", Vector3.new(verandaWidth, 0.35, verandaDepth),
			center + forward * (depth / 2 + verandaDepth / 2 - 0.5) + UP * (FLOOR_BASE + 0.075),
			forward, Color3.fromRGB(173, 161, 136), Enum.Material.Slate)
		local roofY = FLOOR_BASE + 10.7
		G.Box(parent, "Deep veranda eave", Vector3.new(verandaWidth + 2, 0.9, verandaDepth + 1.5),
			center + forward * (depth / 2 + verandaDepth / 2) + UP * roofY, forward,
			spec.roofColor, Enum.Material.WoodPlanks)
		for _, side in ipairs({ -1, 1 }) do
			G.Cylinder(parent, "Veranda timber column",
				center + right * side * (verandaWidth / 2 - 1.1) + forward * (depth / 2 + verandaDepth - 0.5)
					+ UP * ((roofY + FLOOR_BASE) / 2), 1.15, roofY - FLOOR_BASE,
				Color3.fromRGB(139, 97, 58), Enum.Material.Wood)
			G.Box(parent, "Veranda low side rail", Vector3.new(0.45, 2.7, verandaDepth - 1),
				center + right * side * (verandaWidth / 2 - 0.25) + forward * (depth / 2 + verandaDepth / 2 - 0.5)
					+ UP * (FLOOR_BASE + 1.85), forward, spec.trimColor, Enum.Material.Wood)
		end
	end

	local doorWidth = spec.doorWidth or 6.4
	local outerOffset = spec.veranda and 9.25 or 4.5
	for step = 1, 3 do
		local height = step * 0.24
		local offset = outerOffset - (step - 1) * 1.5
		local position = center + forward * (depth / 2 + offset) + UP * (-0.15 + height / 2)
		G.Box(parent, "Concrete entry step", Vector3.new(math.min(width - 10, doorWidth + 4), height, 1.5),
			position, forward, Color3.fromRGB(175, 168, 148), Enum.Material.Concrete)
	end
end

local function addBoundary(parent, spec, center, forward, right, width, depth)
	if not spec.boundary then return end
	local color = spec.boundaryColor or Color3.fromRGB(150, 129, 101)
	for _, side in ipairs({ -1, 1 }) do
		local wallPosition = center + right * side * (width / 2 + 3.8) + UP * 2.15
		G.Box(parent, "Laterite boundary wall", Vector3.new(0.65, 4.3, depth * 0.78), wallPosition, forward,
			color, Enum.Material.Brick)
		G.Box(parent, "Boundary wall cap", Vector3.new(1.05, 0.45, depth * 0.78), wallPosition + UP * 2.35,
			forward, Color3.fromRGB(190, 164, 128), Enum.Material.Sandstone,
			{ collide = false, canTouch = false, canQuery = false })
	end
	local front = center + forward * (depth / 2 + 1.2) + UP * 1.6
	for _, side in ipairs({ -1, 1 }) do
		G.Box(parent, "Front yard wall", Vector3.new((width - 12) / 2, 3.2, 0.7),
			front + right * side * (width / 4 + 3), forward, color, Enum.Material.Brick)
	end
end

function Factory.Build(parent, spec)
	local model = Instance.new("Model")
	model.Name = spec.name
	model:SetAttribute("BuildingType", spec.style)
	model:SetAttribute("Stories", spec.floors or 1)
	model.Parent = parent

	local center = Vector3.new(spec.x, 0, spec.z)
	local forward = spec.forward
	local right = forward:Cross(UP).Unit
	local width, depth = spec.width, spec.depth
	local floors = spec.floors or 1
	local floorHeight = spec.floorHeight or FLOOR_HEIGHT
	local wallHeight = floorHeight - 1
	local thickness = spec.wallThickness or WALL_THICKNESS

	G.Box(model, "Raised stone plinth", Vector3.new(width + 1.6, 0.65, depth + 1.6),
		center + UP * 0.18, forward, spec.plinthColor or Color3.fromRGB(142, 132, 112),
		spec.baseMaterial or Enum.Material.Slate)

	for story = 0, floors - 1 do
		local floorBase = FLOOR_BASE + story * floorHeight
		G.Box(model, "Walkable interior floor", Vector3.new(width - 1, 0.5, depth - 1),
			center + UP * floorBase, forward, Color3.fromRGB(193, 184, 162),
			story == 0 and (spec.floorMaterial or Enum.Material.Concrete) or Enum.Material.WoodPlanks)
		buildExteriorWall(model, spec, center, forward, width, depth, floorBase, story, wallHeight, "front", thickness)
		buildExteriorWall(model, spec, center, -forward, width, depth, floorBase, story, wallHeight, "back", thickness)
		buildExteriorWall(model, spec, center, right, depth, width, floorBase, story, wallHeight, "side", thickness)
		buildExteriorWall(model, spec, center, -right, depth, width, floorBase, story, wallHeight, "side", thickness)
		if story < floors - 1 then
			G.Box(model, "Storey belt course", Vector3.new(width + 0.7, 0.65, depth + 0.7),
				center + UP * (floorBase + floorHeight - 0.35), forward, spec.trimColor, Enum.Material.Concrete)
		end
		if story == 1 and spec.balcony then
			addBalcony(model, center, forward, width, depth, floorBase)
		end
	end

	local roofBase = FLOOR_BASE + (floors - 1) * floorHeight + 0.25 + wallHeight
	local topFloorBase = FLOOR_BASE + (floors - 1) * floorHeight
	G.Box(model, "Interior ceiling", Vector3.new(width - 2, 0.4, depth - 2),
		center + UP * (topFloorBase + wallHeight - 0.15), forward,
		spec.ceilingColor or Color3.fromRGB(207, 198, 176),
		spec.style == "house" and Enum.Material.WoodPlanks or Enum.Material.SmoothPlastic)
	addRoof(model, spec, center, forward, width, depth, roofBase)
	addFacade(model, spec, center, forward, width, depth, floors)
	addVerandaAndSteps(model, spec, center, forward, width, depth)
	addBoundary(model, spec, center, forward, right, width, depth)

	if spec.style == "shop" then
		addShopInterior(model, center, forward, right, width, depth)
	elseif spec.name == "Gedi Nadu Hospital" then
		addHospitalInterior(model, center, forward, right, width, depth)
	elseif spec.name == "Gedi Nadu Police Station" then
		addPoliceInterior(model, center, forward, right, width, depth)
	else
		addHomeInterior(model, center, forward, right, width, depth)
	end
	if floors > 1 then
		addStairs(model, center, forward, right, width, depth, floorHeight)
	end
	return model
end

return Factory
