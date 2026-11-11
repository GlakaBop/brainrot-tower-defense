-- Visual + audio effects: shots, explosions, death confetti, cash popups, sounds.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(script.Parent.Util)
local makePart = Util.makePart

local Effects = {}
local folder = Util.makeFolder("Effects", workspace)

local CONFETTI = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 200)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 60)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 255, 120)),
})

local function anchorPart(position, lifetime)
	local p = makePart({
		Size = Vector3.one * 0.2, Position = position, Transparency = 1,
		CanCollide = false, CanQuery = false, CanTouch = false,
	}, folder)
	Debris:AddItem(p, lifetime)
	return p
end

-- Sounds: throttled so 20 towers firing at once doesn't blow out your ears.
local lastPlayed = {}
local MIN_GAP = 0.07

function Effects.sound(name, position, pitch, force)
	local def = Config.Sounds[name]
	if not def or def.Id == "" then return end
	local now = os.clock()
	if not force and lastPlayed[name] and now - lastPlayed[name] < MIN_GAP then return end
	lastPlayed[name] = now
	local s = Instance.new("Sound")
	s.SoundId = def.Id
	s.Volume = def.Volume
	s.PlaybackSpeed = pitch or 1
	if position then
		s.RollOffMaxDistance = 250
		s.Parent = anchorPart(position, 4)
	else
		s.Parent = SoundService
		Debris:AddItem(s, 6)
	end
	s:Play()
end

function Effects.pop(position, color, size)
	local p = makePart({
		Shape = Enum.PartType.Ball, Size = Vector3.one * size, Position = position,
		Color = color, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false,
	}, folder)
	TweenService:Create(p, TweenInfo.new(0.3), { Size = Vector3.one * size * 2.5, Transparency = 1 }):Play()
	Debris:AddItem(p, 0.35)
end

function Effects.beam(from, to, color, width)
	local len = (to - from).Magnitude
	local beam = makePart({
		Size = Vector3.new(width, width, len),
		CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -len / 2),
		Color = color, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false,
	}, folder)
	Debris:AddItem(beam, 0.08)
end

function Effects.lob(from, to, color)
	local ball = makePart({
		Shape = Enum.PartType.Ball, Size = Vector3.one * 1.2, Position = from,
		Color = color, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false,
	}, folder)
	TweenService:Create(ball, TweenInfo.new(0.15), { Position = to }):Play()
	Debris:AddItem(ball, 0.16)
end

function Effects.confetti(position, amount)
	local holder = anchorPart(position, 2)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = CONFETTI
	pe.LightEmission = 0.5
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.5, 1)
	pe.Speed = NumberRange.new(10, 20)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -30, 0)
	pe.Size = NumberSequence.new(0.5, 0.1)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-200, 200)
	pe.Parent = holder
	pe:Emit(amount or 20)
end

function Effects.floatText(position, text, color)
	local holder = anchorPart(position, 1.1)
	local bb, label = Util.billboardText(holder, text, UDim2.fromOffset(90, 30), Vector3.zero, color)
	TweenService:Create(bb, TweenInfo.new(1), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end

function Effects.flash(part, color, duration)
	local original = part:GetAttribute("OriginalColor")
	if not original then
		original = part.Color
		part:SetAttribute("OriginalColor", original)
	end
	part.Color = color
	task.delay(duration or 0.15, function()
		if part.Parent then part.Color = original end
	end)
end

return Effects
