-- Builds the themed battlefield: lighting, checkered field, path, portal, castle base, decorations.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(script.Parent.Util)
local makePart = Util.makePart

local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
local FIELD = Vector2.new(200, 140)
local TILE = 10

local MapBuilder = {}

local function setupLighting(theme)
	Lighting.ClockTime = theme.ClockTime
	Lighting.Brightness = 2.5
	Lighting.Ambient = theme.Ambient
	Lighting.OutdoorAmbient = theme.OutdoorAmbient
	for _, child in Lighting:GetChildren() do
		if child.Name:sub(1, 3) == "BR_" then child:Destroy() end
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = theme.AtmoDensity
	atmo.Color = theme.AtmoColor
	atmo.Decay = theme.AtmoDecay
	atmo.Glare = 0.3
	atmo.Haze = 1
	atmo.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "BR_ColorCorrection"
	cc.Saturation = 0.25
	cc.Contrast = 0.08
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BR_Bloom"
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting
end

---------------------------------------------------------------- decorations
local Decor = {}

function Decor.Mushroom(parent, pos, rng)
	local h = rng:NextNumber(3, 5)
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(h, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * UPRIGHT,
		Color = Color3.fromRGB(250, 240, 220) }, parent)
	local capY = pos.Y + h + 0.5
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(1.2, 5.5, 5.5), CFrame = CFrame.new(pos.X, capY, pos.Z) * UPRIGHT,
		Color = Color3.fromRGB(240, 50, 70) }, parent)
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + rng:NextNumber()
		makePart({ Name = "Decor", Shape = BALL, Size = Vector3.one * 0.9,
			Position = Vector3.new(pos.X + math.cos(a) * 1.6, capY + 0.5, pos.Z + math.sin(a) * 1.6),
			Color = Color3.new(1, 1, 1) }, parent)
	end
	return 3.5
end

function Decor.CandyTree(parent, pos, rng)
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(6, 1.2, 1.2), CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * UPRIGHT,
		Color = Color3.fromRGB(120, 70, 40) }, parent)
	local colors = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(110, 230, 255), Color3.fromRGB(190, 120, 255) }
	local sizes = { 5, 4, 3 }
	local y = pos.Y + 6
	for i = 1, 3 do
		makePart({ Name = "Decor", Shape = BALL, Size = Vector3.one * sizes[i], Position = Vector3.new(pos.X, y, pos.Z),
			Color = colors[(i + rng:NextInteger(0, 2)) % 3 + 1] }, parent)
		y += sizes[i] * 0.6
	end
	return 3
end

function Decor.FloatingBrain(parent, pos, rng)
	local center = pos + Vector3.new(0, rng:NextNumber(5, 7), 0)
	local pink = Color3.fromRGB(255, 160, 200)
	local brain = makePart({ Name = "Decor", Shape = BALL, Size = Vector3.one * 4, Position = center, Color = pink,
		Material = Enum.Material.Neon, Transparency = 0.1 }, parent)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		makePart({ Name = "Decor", Shape = BALL, Size = Vector3.one * 1.8,
			Position = center + Vector3.new(math.cos(a) * 1.3, 1, math.sin(a) * 1.3), Color = pink }, parent)
	end
	local light = Instance.new("PointLight")
	light.Color = pink
	light.Range = 14
	light.Parent = brain
	return 2.5
end

function Decor.Lollipop(parent, pos, rng)
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(7, 0.5, 0.5), CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0)) * UPRIGHT,
		Color = Color3.new(1, 1, 1) }, parent)
	local colors = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 200, 40), Color3.fromRGB(120, 255, 160) }
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(0.7, 4.5, 4.5),
		CFrame = CFrame.new(pos + Vector3.new(0, 8.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		Color = colors[rng:NextInteger(1, #colors)], Material = Enum.Material.Neon }, parent)
	return 2
end

function Decor.Rock(parent, pos, rng)
	local s = rng:NextNumber(2, 4)
	makePart({ Name = "Decor", Size = Vector3.new(s * 1.3, s, s),
		CFrame = CFrame.new(pos + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
		Color = Color3.fromRGB(140, 130, 160), Material = Enum.Material.Slate }, parent)
	return s * 0.8
end

function Decor.DeadTree(parent, pos, rng)
	local bark = Color3.fromRGB(70, 55, 50)
	local h = rng:NextNumber(6, 9)
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(h, 1.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * UPRIGHT,
		Color = bark, Material = Enum.Material.Wood }, parent)
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2 + rng:NextNumber()
		local len = rng:NextNumber(2.5, 4)
		makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(len, 0.6, 0.6),
			CFrame = CFrame.new(pos + Vector3.new(0, h * rng:NextNumber(0.6, 0.9), 0)) * CFrame.Angles(0, a, math.rad(35))
				* CFrame.new(len / 2, 0, 0),
			Color = bark, Material = Enum.Material.Wood }, parent)
	end
	return 2.5
end

function Decor.GlowShroom(parent, pos, rng)
	local h = rng:NextNumber(2, 4)
	local glow = if rng:NextInteger(0, 1) == 0 then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(190, 110, 255)
	makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(h, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * UPRIGHT,
		Color = Color3.fromRGB(220, 220, 200) }, parent)
	local cap = makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(0.9, 4, 4),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 0.4, 0)) * UPRIGHT, Color = glow, Material = Enum.Material.Neon }, parent)
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 12
	light.Parent = cap
	return 2.5
end

function Decor.Volcano(parent, pos, rng)
	local rock = Color3.fromRGB(60, 40, 40)
	local y = pos.Y
	for i, d in { 12, 9, 6 } do
		local h = 3
		makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(h, d, d), CFrame = CFrame.new(pos.X, y + h / 2, pos.Z) * UPRIGHT,
			Color = rock:Lerp(Color3.fromRGB(90, 50, 40), i / 3), Material = Enum.Material.Basalt }, parent)
		y += h
	end
	local lava = makePart({ Name = "Decor", Shape = CYL, Size = Vector3.new(0.4, 4, 4), CFrame = CFrame.new(pos.X, y + 0.1, pos.Z) * UPRIGHT,
		Color = Color3.fromRGB(255, 120, 30), Material = Enum.Material.Neon }, parent)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(255, 140, 60), Color3.fromRGB(80, 60, 60))
	smoke.Rate = 6
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(4, 7)
	smoke.Size = NumberSequence.new(1.5, 4)
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Parent = lava
	return 6.5
end

function Decor.LavaCrystal(parent, pos, rng)
	for _ = 1, 3 do
		local h = rng:NextNumber(2.5, 5)
		makePart({ Name = "Decor", Size = Vector3.new(0.9, h, 0.9),
			CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), h / 2, rng:NextNumber(-1, 1)))
				* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)),
			Color = Color3.fromRGB(255, 90, 40), Material = Enum.Material.Neon }, parent)
	end
	return 2
end

---------------------------------------------------------------- build
-- Returns { bounds = Part, baseCenter = Vector3, basePart = Part, blockers = { {pos, radius} } }
function MapBuilder.build(mapDef, waypoints, distanceToPath, groundY)
	local theme = mapDef.Theme
	setupLighting(theme)
	local map = Util.makeFolder("Map", workspace)

	-- Invisible bounds used by the server to validate tower placement.
	local bounds = makePart({
		Name = "Bounds", Size = Vector3.new(FIELD.X, 1, FIELD.Y), Position = Vector3.new(0, groundY - 0.5, 0),
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false,
	}, map)

	-- Dirt cliff under the field
	makePart({
		Name = "Cliff", Size = Vector3.new(FIELD.X + 4, 8, FIELD.Y + 4), Position = Vector3.new(0, groundY - 4.6, 0),
		Color = theme.Cliff, Material = Enum.Material.Ground,
	}, map)

	-- Checkered field (tiles are named Ground so the client knows it can build there)
	local tiles = Instance.new("Folder")
	tiles.Name = "Tiles"
	for ix = 0, FIELD.X / TILE - 1 do
		for iz = 0, FIELD.Y / TILE - 1 do
			makePart({
				Name = "Ground", Size = Vector3.new(TILE, 1, TILE),
				Position = Vector3.new(-FIELD.X / 2 + TILE / 2 + ix * TILE, groundY - 0.5, -FIELD.Y / 2 + TILE / 2 + iz * TILE),
				Color = if (ix + iz) % 2 == 0 then theme.TileA else theme.TileB,
				Material = Enum.Material.SmoothPlastic,
			}, tiles)
		end
	end
	tiles.Parent = map

	-- Path with candy curbs
	local w = Config.PathWidth
	for i = 1, #waypoints - 1 do
		local a = waypoints[i] + Vector3.new(0, 0.05, 0)
		local b = waypoints[i + 1] + Vector3.new(0, 0.05, 0)
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		makePart({
			Name = "Path", Size = Vector3.new(w, 0.1, len + w), CFrame = cf,
			Color = theme.Path, Material = if theme.PathNeon then Enum.Material.Neon else Enum.Material.SmoothPlastic,
		}, map)
		for _, side in { -1, 1 } do
			makePart({
				Name = "Path", Size = Vector3.new(0.6, 0.4, len - w + 0.6),
				CFrame = cf * CFrame.new(side * (w / 2 + 0.3), 0.15, 0),
				Color = if i % 2 == 0 then theme.CurbA else theme.CurbB,
				Material = Enum.Material.Neon,
			}, map)
		end
	end

	-- Spawn portal: dark frame + glowing swirl
	local portalCf = CFrame.lookAt(waypoints[1], waypoints[2]) * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(0, 6, 0)
	local portal = makePart({
		Name = "Portal", Size = Vector3.new(0.6, 12, 10), CFrame = portalCf,
		Color = Color3.fromRGB(170, 60, 255), Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false,
	}, map)
	for _, side in { -1, 1 } do
		makePart({ Name = "PortalFrame", Size = Vector3.new(1.5, 14, 1.5), CFrame = portalCf * CFrame.new(0, 1, side * 5.5),
			Color = Color3.fromRGB(40, 20, 60), Material = Enum.Material.Slate }, map)
	end
	makePart({ Name = "PortalFrame", Size = Vector3.new(1.5, 1.5, 12.5), CFrame = portalCf * CFrame.new(0, 7.5, 0),
		Color = Color3.fromRGB(40, 20, 60), Material = Enum.Material.Slate }, map)
	local swirl = Instance.new("ParticleEmitter")
	swirl.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255), Color3.fromRGB(255, 100, 200))
	swirl.LightEmission = 1
	swirl.Rate = 30
	swirl.Lifetime = NumberRange.new(1, 1.5)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.RotSpeed = NumberRange.new(-180, 180)
	swirl.Size = NumberSequence.new(1.5, 0)
	swirl.Transparency = NumberSequence.new(0.3, 1)
	swirl.Parent = portal
	local portalLight = Instance.new("PointLight")
	portalLight.Color = Color3.fromRGB(200, 100, 255)
	portalLight.Range = 20
	portalLight.Brightness = 3
	portalLight.Parent = portal

	-- Castle base
	local baseCenter = waypoints[#waypoints]
	local basePart = makePart({
		Name = "Base", Size = Vector3.new(14, 10, 14), Position = baseCenter + Vector3.new(0, 5, 0),
		Color = Color3.fromRGB(70, 130, 255), Material = Enum.Material.SmoothPlastic,
	}, map)
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			local p = baseCenter + Vector3.new(dx * 7, 0, dz * 7)
			makePart({ Name = "BaseTower", Shape = CYL, Size = Vector3.new(14, 4.5, 4.5), CFrame = CFrame.new(p + Vector3.new(0, 7, 0)) * UPRIGHT,
				Color = Color3.fromRGB(240, 240, 255) }, map)
			makePart({ Name = "BaseTower", Shape = CYL, Size = Vector3.new(1.5, 5.5, 5.5), CFrame = CFrame.new(p + Vector3.new(0, 14.5, 0)) * UPRIGHT,
				Color = Color3.fromRGB(255, 120, 220), Material = Enum.Material.Neon }, map)
		end
	end
	makePart({ Name = "FlagPole", Shape = CYL, Size = Vector3.new(10, 0.4, 0.4), CFrame = CFrame.new(baseCenter + Vector3.new(0, 15, 0)) * UPRIGHT,
		Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Metal }, map)
	makePart({ Name = "Flag", Size = Vector3.new(4, 2.5, 0.2), Position = baseCenter + Vector3.new(2.2, 18.5, 0),
		Color = Color3.fromRGB(255, 220, 60), Material = Enum.Material.Neon }, map)
	Util.billboardText(basePart, "YOUR BASE", UDim2.fromOffset(200, 50), Vector3.new(0, 16, 0))

	-- Decorations (fixed seed so the map is the same every time)
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decor"
	local rng = Random.new(67)
	local blockers = {}
	local placed = 0
	for _ = 1, 200 do
		if placed >= 24 then break end
		local pos = Vector3.new(rng:NextNumber(-FIELD.X / 2 + 5, FIELD.X / 2 - 5), groundY, rng:NextNumber(-FIELD.Y / 2 + 5, FIELD.Y / 2 - 5))
		local ok = distanceToPath(pos) > w / 2 + 8 and (pos - baseCenter).Magnitude > 16 and (pos - waypoints[1]).Magnitude > 12
		if ok then
			for _, b in blockers do
				if (b.pos - pos).Magnitude < 12 then
					ok = false
					break
				end
			end
		end
		if ok then
			placed += 1
			local kind = theme.Decor[(placed - 1) % #theme.Decor + 1]
			local radius = Decor[kind](decorFolder, pos, rng)
			table.insert(blockers, { pos = pos, radius = radius })
		end
	end
	decorFolder.Parent = map

	return { bounds = bounds, baseCenter = baseCenter, basePart = basePart, blockers = blockers }
end

return MapBuilder
