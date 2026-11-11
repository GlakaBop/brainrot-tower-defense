-- Builds the look of each Brainrot enemy from its Config entry (Shape + Accessories).
local Util = require(script.Parent.Util)
local makePart, weld = Util.makePart, Util.weld

local BLACK = Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(255, 200, 40)
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local function attach(ctx, props)
	props.Anchored = false
	props.CanCollide = false
	props.CanQuery = false
	props.Massless = true
	local p = makePart(props, ctx.model)
	weld(ctx.body, p)
	return p
end

-- Rotation that turns a cylinder (axis X) upright (axis Y).
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local Accessories = {}

function Accessories.Noodles(ctx)
	local s, cf = ctx.s, ctx.cf
	local rng = Random.new()
	for i = 1, 7 do
		local len = rng:NextNumber(0.4, 0.7) * s.Y
		local ang = (i / 7) * math.pi * 2
		local r = s.X * 0.22
		attach(ctx, {
			Name = "Noodle", Shape = CYL, Size = Vector3.new(len, 0.3, 0.3),
			CFrame = cf * CFrame.new(math.cos(ang) * r, ctx.top - s.Y * 0.1 + len * 0.4, math.sin(ang) * r)
				* CFrame.Angles(rng:NextNumber(-0.5, 0.5), 0, rng:NextNumber(-0.5, 0.5)) * UPRIGHT,
			Color = Color3.fromRGB(255, 225, 120),
		})
	end
	ctx.top += s.Y * 0.35
end

function Accessories.Tongue(ctx)
	local s = ctx.s
	attach(ctx, {
		Name = "Tongue", Size = Vector3.new(s.X * 0.18, s.Y * 0.16, 0.2),
		CFrame = ctx.cf * CFrame.new(0, -s.Y * 0.3, ctx.faceZ - 0.1),
		Color = Color3.fromRGB(255, 110, 150),
	})
end

function Accessories.Sunglasses(ctx)
	local s = ctx.s
	attach(ctx, {
		Name = "Sunglasses", Size = Vector3.new(s.X * 0.85, s.Y * 0.17, 0.25),
		CFrame = ctx.cf * CFrame.new(0, s.Y * 0.18, ctx.faceZ - ctx.eyeSize * 0.5 - 0.1),
		Color = BLACK, Reflectance = 0.4,
	})
end

function Accessories.BackwardsCap(ctx)
	local s = ctx.s
	local d = math.min(s.X, s.Z) * 0.9
	local h = s.Y * 0.25
	attach(ctx, {
		Name = "Cap", Shape = CYL, Size = Vector3.new(h, d, d),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + h / 2, 0) * UPRIGHT,
		Color = Color3.fromRGB(230, 40, 40),
	})
	attach(ctx, {
		Name = "Brim", Size = Vector3.new(d * 0.6, 0.15, d * 0.5),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + 0.1, d * 0.6),
		Color = Color3.fromRGB(230, 40, 40),
	})
	ctx.top += h
end

function Accessories.SpeedTrail(ctx)
	local s = ctx.s
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, s.Y * 0.3, s.Z / 2)
	a0.Parent = ctx.body
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -s.Y * 0.3, s.Z / 2)
	a1.Parent = ctx.body
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.25
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(ctx.def.Color)
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.Parent = ctx.body
end

function Accessories.Butter(ctx)
	local s = ctx.s
	attach(ctx, {
		Name = "Butter", Size = Vector3.new(s.X * 0.35, 0.35, s.Z * 0.45),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + 0.1, 0) * CFrame.Angles(0, math.rad(20), 0),
		Color = Color3.fromRGB(255, 235, 110),
	})
	ctx.top += 0.35
end

function Accessories.Propeller(ctx)
	local s = ctx.s
	attach(ctx, {
		Name = "Stick", Shape = CYL, Size = Vector3.new(1, 0.3, 0.3),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + 0.4, 0) * UPRIGHT, Color = Color3.fromRGB(80, 80, 80),
	})
	attach(ctx, {
		Name = "Blade", Size = Vector3.new(s.X * 1.4, 0.12, 0.45),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + 0.95, 0) * CFrame.Angles(0, math.rad(35), 0),
		Color = Color3.fromRGB(255, 80, 80),
	})
	ctx.top += 1
end

function Accessories.Helmet(ctx)
	local s = ctx.s
	attach(ctx, {
		Name = "Helmet", Size = Vector3.new(s.X * 1.1, s.Y * 0.25, s.Z * 1.1),
		CFrame = ctx.cf * CFrame.new(0, s.Y * 0.5, 0), Color = Color3.fromRGB(190, 190, 200),
		Material = Enum.Material.DiamondPlate,
	})
	ctx.top += s.Y * 0.12
end

function Accessories.GoldChain(ctx)
	local s = ctx.s
	for i = -3, 3 do
		attach(ctx, {
			Name = "Chain", Shape = BALL, Size = Vector3.one * math.max(s.X * 0.1, 0.4),
			CFrame = ctx.cf * CFrame.new(i * s.X * 0.11, -s.Y * 0.42 + (i * i) * s.Y * 0.012, ctx.faceZ - 0.05),
			Color = GOLD, Material = Enum.Material.Metal, Reflectance = 0.3,
		})
	end
end

function Accessories.Brain(ctx)
	local s = ctx.s
	local d = s.X * 0.7
	local y = ctx.top + d * 0.15
	local pink = Color3.fromRGB(255, 160, 200)
	attach(ctx, { Name = "Brain", Shape = BALL, Size = Vector3.one * d, CFrame = ctx.cf * CFrame.new(0, y, 0), Color = pink })
	for i = 1, 6 do
		local ang = i / 6 * math.pi * 2
		attach(ctx, {
			Name = "BrainLump", Shape = BALL, Size = Vector3.one * d * 0.4,
			CFrame = ctx.cf * CFrame.new(math.cos(ang) * d * 0.3, y + d * 0.25, math.sin(ang) * d * 0.3),
			Color = pink:Lerp(Color3.new(1, 1, 1), 0.15),
		})
	end
	ctx.top = y + d * 0.5
end

function Accessories.Crown(ctx)
	local s = ctx.s
	local d = s.X * 0.55
	local h = s.Y * 0.1
	attach(ctx, {
		Name = "CrownBase", Shape = CYL, Size = Vector3.new(h, d, d),
		CFrame = ctx.cf * CFrame.new(0, ctx.top + h / 2, 0) * UPRIGHT, Color = GOLD, Material = Enum.Material.Neon,
	})
	for i = 1, 5 do
		local ang = i / 5 * math.pi * 2
		attach(ctx, {
			Name = "CrownSpike", Size = Vector3.new(d * 0.15, h * 1.6, d * 0.15),
			CFrame = ctx.cf * CFrame.new(math.cos(ang) * d * 0.4, ctx.top + h + h * 0.8, math.sin(ang) * d * 0.4),
			Color = GOLD, Material = Enum.Material.Neon,
		})
	end
	ctx.top += h * 2.6
end

function Accessories.Horns(ctx)
	local s = ctx.s
	local len, w = s.Y * 0.4, s.X * 0.12
	for _, side in { -1, 1 } do
		attach(ctx, {
			Name = "Horn", Shape = CYL, Size = Vector3.new(len, w, w),
			CFrame = ctx.cf * CFrame.new(side * s.X * 0.38, s.Y / 2 + len * 0.35, 0)
				* CFrame.Angles(0, 0, math.rad(90) - side * 0.45),
			Color = Color3.fromRGB(245, 240, 230),
		})
	end
end

function Accessories.NurseHat(ctx)
	local s = ctx.s
	local w, h = s.X * 0.6, s.Y * 0.28
	local hatCf = ctx.cf * CFrame.new(0, ctx.top + h / 2, 0)
	attach(ctx, { Name = "Hat", Size = Vector3.new(w, h, s.Z * 0.5), CFrame = hatCf, Color = Color3.new(1, 1, 1) })
	local red = Color3.fromRGB(230, 40, 50)
	attach(ctx, { Name = "Cross", Size = Vector3.new(w * 0.45, h * 0.18, 0.12), CFrame = hatCf * CFrame.new(0, 0, -s.Z * 0.25 - 0.05), Color = red })
	attach(ctx, { Name = "Cross", Size = Vector3.new(w * 0.15, h * 0.6, 0.12), CFrame = hatCf * CFrame.new(0, 0, -s.Z * 0.25 - 0.05), Color = red })
	ctx.top += h
end

function Accessories.Aura(ctx)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(ctx.def.Color)
	pe.LightEmission = 1
	pe.Rate = 25
	pe.Lifetime = NumberRange.new(0.6, 1)
	pe.Speed = NumberRange.new(2, 4)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(1.2, 0)
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Parent = ctx.body
	local light = Instance.new("PointLight")
	light.Color = ctx.def.Color
	light.Range = ctx.s.X * 2
	light.Brightness = 2
	light.Parent = ctx.body
end

local EnemyLooks = {}

-- Returns model, body (the anchored root to move), and the height of the top of the model above body center.
function EnemyLooks.build(def, cf)
	local shape = def.Shape or "Block"
	local s = if shape == "Ball" then Vector3.one * def.Size.X else def.Size

	local model = Instance.new("Model")
	model.Name = def.DisplayName
	local body = makePart({
		Name = "Body", Shape = if shape == "Ball" then BALL else nil, Size = s, CFrame = cf,
		Color = def.Color, Material = Enum.Material.SmoothPlastic, CanCollide = false,
	}, model)

	local ctx = {
		model = model, body = body, def = def, s = s, cf = cf,
		top = s.Y / 2,
		faceZ = if shape == "Ball" then -s.Z * 0.42 else -s.Z / 2,
		eyeSize = math.min(s.X, s.Y) * 0.32,
	}

	if shape == "Toast" then
		local d = s.X
		attach(ctx, {
			Name = "Crust", Shape = CYL, Size = Vector3.new(s.Z * 0.98, d, d),
			CFrame = cf * CFrame.new(0, s.Y / 2 - d * 0.2, 0) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(190, 120, 60),
		})
		ctx.top = s.Y / 2 + d * 0.3
	end

	-- Googly face
	for _, side in { -1, 1 } do
		local eyeCf = cf * CFrame.new(side * s.X * 0.22, s.Y * 0.18, ctx.faceZ)
		attach(ctx, { Name = "Eye", Shape = BALL, Size = Vector3.one * ctx.eyeSize, CFrame = eyeCf, Color = Color3.new(1, 1, 1) })
		attach(ctx, {
			Name = "Pupil", Shape = BALL, Size = Vector3.one * ctx.eyeSize * 0.45,
			CFrame = eyeCf * CFrame.new(side * ctx.eyeSize * 0.1, 0, -ctx.eyeSize * 0.35), Color = BLACK,
		})
		if def.Flying then
			attach(ctx, {
				Name = "Wing", Size = Vector3.new(s.X * 0.9, 0.2, s.Z * 0.6),
				CFrame = cf * CFrame.new(side * s.X * 0.85, s.Y * 0.1, 0) * CFrame.Angles(0, 0, side * math.rad(-20)),
				Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon, Transparency = 0.3,
			})
		end
	end
	attach(ctx, {
		Name = "Mouth", Size = Vector3.new(s.X * 0.5, s.Y * 0.08, 0.1),
		CFrame = cf * CFrame.new(0, -s.Y * 0.2, ctx.faceZ), Color = Color3.fromRGB(60, 20, 20),
	})

	for _, name in def.Accessories or {} do
		local builder = Accessories[name]
		if builder then
			builder(ctx)
		else
			warn("Unknown enemy accessory: " .. tostring(name))
		end
	end

	model.PrimaryPart = body
	return model, body, ctx.top
end

return EnemyLooks
