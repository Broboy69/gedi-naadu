-- Gedi Nadu: server bootstrap for the procedural roleplay town.
-- Geometry is built from anchored built-in Roblox parts; the generated folder is safe to rebuild.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TownLayout = require(script.Parent.Town.Layout)

local ROOT_NAME = "GediNaduGenerated"
local oldTown = Workspace:FindFirstChild(ROOT_NAME)
if oldTown then
	oldTown:Destroy()
end

local town = Instance.new("Folder")
town.Name = ROOT_NAME
town.Parent = Workspace

TownLayout.Build(town)

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

print("Gedi Nadu roleplay town generated with interiors, public spaces, and Town Square spawn.")
