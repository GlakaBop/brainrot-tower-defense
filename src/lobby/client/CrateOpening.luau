-- Crate opening animation: shake + glow -> burst -> spinning strip -> reveal card.
-- CrateOpening.play(gui, crate, result) yields until the player closes the reveal.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Theme = require(Shared:WaitForChild("Theme"))
local UI = require(Shared:WaitForChild("UIKit"))
local C = Theme.Colors

local CARD_W, CARD_GAP = 130, 10
local STRIP_COUNT = 48
local TARGET_INDEX = 42
local SPIN_TIME = 4.8

local CrateOpening = {}

local function playSound(name, pitch, volumeMult)
	local def = Config.Sounds[name]
	if not def or def.Id == "" then return end
	local s = Instance.new("Sound")
	s.SoundId = def.Id
	s.Volume = def.Volume * (volumeMult or 1)
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
end

-- Picks a random tower for filler strip cards, using the crate's real odds so the strip looks honest.
local function randomFiller(crate, rng)
	local odds = Config.CrateOdds(crate)
	local roll = rng:NextNumber()
	for _, r in Config.Rarities do
		roll -= odds[r.Id]
		if roll <= 0 then
			local pool = Config.TowersOfRarity(r.Id)
			if #pool > 0 then return pool[rng:NextInteger(1, #pool)], r.Id end
		end
	end
	local kind = Config.TowerOrder[1]
	return kind, Config.Towers[kind].Rarity or "Common"
end

-- Drawn crate (used when no crate image is set in Theme.Icons.Crates).
function CrateOpening.crateArt(crate, size, parent)
	local holder = UI.new("Frame", { Size = size, BackgroundTransparency = 1, Parent = parent })
	local image = Theme.Icons.Crates and Theme.Icons.Crates[crate.Id]
	if image and image ~= "" then
		UI.new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = image,
			ScaleType = Enum.ScaleType.Fit, Parent = holder })
		return holder
	end
	local box = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(0.86, 0.68),
		BackgroundColor3 = crate.Color, Parent = holder,
	}, { UI.corner(14), UI.shine(), UI.stroke(Color3.fromRGB(30, 15, 50), 0, 5) })
	UI.new("Frame", { -- lid
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromScale(0.96, 0.2),
		BackgroundColor3 = crate.Color:Lerp(Color3.new(1, 1, 1), 0.25), Parent = holder,
	}, { UI.corner(10), UI.shine(), UI.stroke(Color3.fromRGB(30, 15, 50), 0, 5) })
	UI.new("Frame", { -- strap
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.16, 1),
		BackgroundColor3 = C.Gold, Parent = box,
	}, { UI.stroke(Color3.fromRGB(30, 15, 50), 0, 3) })
	UI.label({ Size = UDim2.fromScale(1, 1), Text = "?", FontFace = Theme.FontHeavy, TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1), Parent = box }).ZIndex = 2
	return holder
end

local function stripCard(kind, rarityId, parent, order)
	local def = Config.Towers[kind]
	local rarity = Config.GetRarity(rarityId)
	local card = UI.new("Frame", {
		Size = UDim2.fromOffset(CARD_W, 150), BackgroundColor3 = C.PanelLight, LayoutOrder = order, Parent = parent,
	}, { UI.corner(12) })
	UI.new("Frame", { -- rarity glow at the bottom
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = rarity.Color, BackgroundTransparency = 0.2, Parent = card,
	}, {
		UI.corner(12),
		UI.new("UIGradient", { Rotation = -90, Transparency = NumberSequence.new(0, 1) }),
	})
	UI.stroke(rarity.Color, 0, 3).Parent = card
	UI.icon({ Size = UDim2.fromOffset(78, 78), Position = UDim2.new(0.5, 0, 0, 14), AnchorPoint = Vector2.new(0.5, 0),
		Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = card })
	UI.label({ Position = UDim2.fromOffset(4, 100), Size = UDim2.new(1, -8, 0, 20), Text = def.DisplayName,
		FontFace = Theme.FontBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	UI.label({ Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 18), Text = rarityId:upper(),
		FontFace = Theme.FontHeavy, TextSize = 13, TextColor3 = rarity.Color, Parent = card })
	return card
end

local function sunburst(parent, color)
	local rays = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 700),
		BackgroundTransparency = 1, Parent = parent,
	})
	for i = 1, 12 do
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 60, 1, 0),
			Rotation = i * 15, BackgroundColor3 = color, BorderSizePixel = 0, Parent = rays,
		}, {
			UI.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	return rays
end

function CrateOpening.play(gui, crate, result)
	local rarity = Config.GetRarity(result.Rarity)
	local def = Config.Towers[result.Tower]
	local rng = Random.new()
	local skipped = false
	local connections = {}

	-- Dark overlay that blocks the rest of the UI
	local overlay = UI.new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "", ZIndex = 100, Parent = gui,
	})
	local stage = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100, Parent = overlay })
	UI.tween(overlay, 0.3, { BackgroundTransparency = 0.25 })
	local skipHint = UI.label({
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(300, 22),
		Text = "Click to skip", TextSize = 15, TextColor3 = C.SubText, Parent = overlay,
	})
	table.insert(connections, overlay.Activated:Connect(function() skipped = true end))

	-- 1) Shake + growing glow
	local glow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(160, 160),
		BackgroundColor3 = crate.Color, BackgroundTransparency = 0.6, Parent = stage,
	}, { UI.corner(999) })
	local crateHolder = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(200, 200),
		BackgroundTransparency = 1, Parent = stage,
	})
	local crateScale = UI.new("UIScale", { Scale = 0.3, Parent = crateHolder })
	CrateOpening.crateArt(crate, UDim2.fromScale(1, 1), crateHolder)
	UI.tween(crateScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.wait(0.35)

	local shakeStart = os.clock()
	local SHAKE_TIME = 1.3
	while os.clock() - shakeStart < SHAKE_TIME and not skipped do
		local t = (os.clock() - shakeStart) / SHAKE_TIME
		crateHolder.Rotation = math.sin(os.clock() * (30 + t * 40)) * (4 + t * 14)
		crateScale.Scale = 1 + t * 0.15
		glow.Size = UDim2.fromOffset(160 + t * 260, 160 + t * 260)
		glow.BackgroundTransparency = 0.6 - t * 0.3
		RunService.RenderStepped:Wait()
	end

	-- 2) Burst
	playSound("Pop", 0.8, 1.5)
	local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, ZIndex = 110, Parent = overlay })
	UI.tween(flash, 0.4, { BackgroundTransparency = 1 })
	crateHolder:Destroy()
	glow:Destroy()

	-- 3) Spinning strip
	if not skipped then
		local window = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(820, 170),
			BackgroundColor3 = C.Panel, BackgroundTransparency = 0.1, ClipsDescendants = true, Parent = stage,
		}, { UI.corner(16), UI.stroke(crate.Color, 0.2, 3) })
		local strip = UI.new("Frame", {
			Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(STRIP_COUNT * (CARD_W + CARD_GAP), 150),
			BackgroundTransparency = 1, Parent = window,
		}, { UI.list(Enum.FillDirection.Horizontal, CARD_GAP) })
		for i = 1, STRIP_COUNT do
			if i == TARGET_INDEX then
				stripCard(result.Tower, result.Rarity, strip, i)
			else
				local kind, rarityId = randomFiller(crate, rng)
				stripCard(kind, rarityId, strip, i)
			end
		end
		-- center marker
		UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = C.Gold, ZIndex = 5, Parent = window,
		})
		for _, y in { 0, 1 } do
			UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, y), Position = UDim2.fromScale(0.5, y), Size = UDim2.fromOffset(18, 10),
				BackgroundColor3 = C.Gold, ZIndex = 5, Parent = window,
			}, { UI.corner(4) })
		end

		local step = CARD_W + CARD_GAP
		local windowCenter = 820 / 2
		local jitter = rng:NextNumber(-CARD_W * 0.35, CARD_W * 0.35)
		local finalX = windowCenter - ((TARGET_INDEX - 1) * step + CARD_W / 2) - jitter
		local spin = UI.tween(strip, SPIN_TIME, { Position = UDim2.fromOffset(finalX, 10) }, Enum.EasingStyle.Quint)

		local lastIndex = -1
		table.insert(connections, RunService.RenderStepped:Connect(function()
			local index = math.floor((windowCenter - strip.Position.X.Offset) / step)
			if index ~= lastIndex then
				lastIndex = index
				playSound("Pop", 1.8 + rng:NextNumber() * 0.2, 0.4)
			end
		end))

		local spinStart = os.clock()
		while os.clock() - spinStart < SPIN_TIME + 0.2 and not skipped do
			task.wait()
		end
		spin:Cancel()
		task.wait(if skipped then 0 else 0.4)
		window:Destroy()
	end
	for _, c in connections do c:Disconnect() end
	table.clear(connections)
	skipHint:Destroy()

	-- 4) Reveal
	local rays = sunburst(stage, rarity.Color)
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		rays.Rotation += dt * 20
	end))
	local card = UI.panel({
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(300, 360),
		ZIndex = 2, Parent = stage,
	})
	card:FindFirstChildOfClass("UIStroke").Color = rarity.Color
	card:FindFirstChildOfClass("UIStroke").Transparency = 0
	card:FindFirstChildOfClass("UIStroke").Thickness = 4
	local cardScale = UI.new("UIScale", { Scale = 0.2, Parent = card })
	UI.tween(cardScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)

	UI.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 26), Text = result.Rarity:upper(),
		FontFace = Theme.FontHeavy, TextSize = 26, TextColor3 = rarity.Color, Parent = card })
	UI.icon({ Size = UDim2.fromOffset(150, 150), Position = UDim2.new(0.5, 0, 0, 58), AnchorPoint = Vector2.new(0.5, 0),
		Color = def.Color, Image = Theme.Icons.Towers[result.Tower], Glyph = Theme.Glyphs.Towers[result.Tower], Parent = card })
	UI.label({ Position = UDim2.fromOffset(0, 220), Size = UDim2.new(1, 0, 0, 30), Text = def.DisplayName,
		FontFace = Theme.FontHeavy, TextSize = 28, Parent = card })
	UI.label({
		Position = UDim2.fromOffset(0, 254), Size = UDim2.new(1, 0, 0, 22),
		Text = if result.Duplicate then "Duplicate!  +" .. result.Refund .. " " .. Config.CurrencyName else "NEW TOWER UNLOCKED!",
		FontFace = Theme.FontBold, TextSize = 18, TextColor3 = if result.Duplicate then C.Gold else C.Good, Parent = card,
	})
	local okBtn = UI.button({
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(1, -40, 0, 44),
		Color = C.Upgrade, Text = "AWESOME!", TextSize = 20, Parent = card,
	})

	local _, rarityIndex = Config.GetRarity(result.Rarity)
	playSound(if rarityIndex >= 4 then "WaveStart" else "Pop", if rarityIndex >= 4 then 1.2 else 1, if rarityIndex >= 4 then 1 else 1.5)

	local closed = false
	okBtn.Activated:Once(function() closed = true end)
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then closed = true end
	end))
	while not closed do task.wait() end

	for _, c in connections do c:Disconnect() end
	UI.tween(overlay, 0.2, { BackgroundTransparency = 1 })
	overlay:Destroy()
end

return CrateOpening
