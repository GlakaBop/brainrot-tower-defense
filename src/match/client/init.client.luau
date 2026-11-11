-- Brainrot Tower Defense: client HUD, tower placement and tower upgrade panel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local state = ReplicatedStorage:WaitForChild("GameState")
local placeRemote = ReplicatedStorage:WaitForChild("PlaceTower")
local actionRemote = ReplicatedStorage:WaitForChild("TowerAction")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local C = Theme.Colors

---------------------------------------------------------------- UI kit
local function new(className, props, children)
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Corner) })
end

local function stroke(color, transparency, thickness)
	return new("UIStroke", {
		Color = color or C.Stroke, Transparency = transparency or 0.88, Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(x, y)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x),
		PaddingTop = UDim.new(0, y or x), PaddingBottom = UDim.new(0, y or x),
	})
end

local function shine()
	return new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 215)),
		Rotation = 90,
	})
end

local function label(props)
	local defaults = {
		BackgroundTransparency = 1, FontFace = Theme.Font, TextColor3 = C.Text, TextSize = 18,
	}
	for k, v in props do
		defaults[k] = v
	end
	return new("TextLabel", defaults)
end

local function panel(props, children)
	local defaults = { BackgroundColor3 = C.Panel, BackgroundTransparency = Theme.PanelTransparency, BorderSizePixel = 0 }
	for k, v in props do
		defaults[k] = v
	end
	local f = new("Frame", defaults, children)
	corner().Parent = f
	stroke().Parent = f
	return f
end

-- Round icon: uses an image if one is set in Theme.Icons, otherwise a text glyph.
local function icon(props)
	local holder = new("Frame", {
		Name = "Icon", Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = props.Color, BorderSizePixel = 0, Parent = props.Parent,
	}, { corner(999), shine() })
	if props.Image and props.Image ~= "" then
		-- Custom art has its own shape, so drop the colored circle behind it.
		holder.BackgroundTransparency = 1
		holder:FindFirstChildOfClass("UIGradient"):Destroy()
		new("ImageLabel", {
			Name = "Art", Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(-0.075, -0.075),
			BackgroundTransparency = 1, Image = props.Image, ScaleType = Enum.ScaleType.Fit, Parent = holder,
		})
	else
		label({
			Size = UDim2.fromScale(1, 1), Text = props.Glyph or "?", FontFace = Theme.FontHeavy,
			TextScaled = true, Parent = holder,
		}, nil)
		new("UIPadding", {
			PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0),
			Parent = holder:FindFirstChildOfClass("TextLabel"),
		})
	end
	return holder
end

local function tween(inst, time, goal, style)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local function lighten(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function actionButton(props)
	local color = props.Color
	local btn = new("TextButton", {
		Name = props.Name, Size = props.Size, Position = props.Position or UDim2.new(), LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = color, AutoButtonColor = false, BorderSizePixel = 0,
		FontFace = Theme.FontBold, TextColor3 = Color3.new(1, 1, 1), TextSize = props.TextSize or 18,
		Text = props.Text or "", Parent = props.Parent,
	}, { corner(10), shine() })
	btn:SetAttribute("BaseColor", color)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = lighten(btn:GetAttribute("BaseColor"), 0.15) })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.12, { BackgroundColor3 = btn:GetAttribute("BaseColor") })
	end)
	return btn
end

local function setButtonColor(btn, color)
	btn:SetAttribute("BaseColor", color)
	btn.BackgroundColor3 = color
end

---------------------------------------------------------------- root + scaling
local gui = new("ScreenGui", {
	Name = "TDHud", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiScale = new("UIScale", { Parent = gui })
local function updateScale()
	local vp = camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.15)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

---------------------------------------------------------------- top HUD
local hudRow = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(0, 46),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = gui,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local function statPill(order, key, color, width)
	local pill = panel({ Size = UDim2.fromOffset(width, 46), LayoutOrder = order, Parent = hudRow })
	icon({
		Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(6, 6), Color = color,
		Image = Theme.Icons[key], Glyph = Theme.Glyphs[key], Parent = pill,
	})
	return label({
		Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -56, 1, 0), FontFace = Theme.FontHeavy,
		TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
	})
end

local livesLbl = statPill(1, "Lives", C.Lives, 120)
local waveLbl = statPill(2, "Wave", C.Wave, 160)
local cashLbl = statPill(3, "Cash", C.Cash, 150)

local statusPill = panel({
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64), Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X, Parent = gui,
}, { padding(16, 0) })
local statusLbl = label({
	Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextSize = 16,
	TextColor3 = C.SubText, Parent = statusPill,
})

---------------------------------------------------------------- wave banner
local banner = new("CanvasGroup", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(600, 120),
	BackgroundTransparency = 1, GroupTransparency = 1, Parent = gui,
})
local bannerScale = new("UIScale", { Parent = banner })
local bannerTitle = label({
	Size = UDim2.new(1, 0, 0, 80), FontFace = Theme.FontHeavy, TextSize = 72, Parent = banner,
}, nil)
new("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = bannerTitle })
local bannerSub = label({
	Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 30), TextSize = 22, Parent = banner,
})
new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = bannerSub })

local bannerToken = 0
local function showBanner(title, sub, color)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerTitle.TextColor3 = color
	bannerSub.Text = sub
	bannerScale.Scale = 0.6
	banner.GroupTransparency = 1
	tween(bannerScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(banner, 0.25, { GroupTransparency = 0 })
	task.delay(1.8, function()
		if token == bannerToken then
			tween(banner, 0.4, { GroupTransparency = 1 })
		end
	end)
end

local function waveHasBoss(w)
	local wave = Config.Waves[w]
	if not wave then return false end
	for _, group in wave do
		local def = Config.Enemies[group[1]]
		if def and def.IsBoss then return true end
	end
	return false
end

---------------------------------------------------------------- toast
local toast = new("CanvasGroup", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -170), Size = UDim2.fromOffset(0, 36),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Panel, BackgroundTransparency = 0.05,
	GroupTransparency = 1, Parent = gui,
}, { corner(999), padding(18, 0) })
local toastLbl = label({
	Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, FontFace = Theme.FontBold, TextSize = 17,
	Parent = toast,
})

local toastToken = 0
local function showMessage(text, good)
	toastToken += 1
	local token = toastToken
	toastLbl.Text = text
	toastLbl.TextColor3 = if good then C.Good else C.Bad
	tween(toast, 0.15, { GroupTransparency = 0 })
	task.delay(1.8, function()
		if token == toastToken then
			tween(toast, 0.3, { GroupTransparency = 1 })
		end
	end)
end

local hintPill = panel({
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -140), Size = UDim2.fromOffset(0, 26),
	AutomaticSize = Enum.AutomaticSize.X, Visible = false, Parent = gui,
}, { padding(14, 0) })
label({
	Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextSize = 14, TextColor3 = C.SubText,
	Text = "Click the grass to place   ·   Q to cancel", Parent = hintPill,
})

---------------------------------------------------------------- state binding
local lastWave = 0
local function refreshState()
	local lives = state:GetAttribute("Lives") or 0
	local wave = state:GetAttribute("Wave") or 0
	livesLbl.Text = tostring(lives)
	waveLbl.Text = string.format("%d / %d", wave, state:GetAttribute("MaxWave") or 0)
	local status = state:GetAttribute("Status") or ""
	statusLbl.Text = status
	statusPill.Visible = status ~= ""

	if wave ~= lastWave then
		if wave > 0 then
			if waveHasBoss(wave) then
				showBanner("BOSS WAVE", "Wave " .. wave .. " - brace yourself!", C.Bad)
			else
				showBanner("WAVE " .. wave, "Here they come!", C.Text)
			end
		end
		lastWave = wave
	end
end
state.AttributeChanged:Connect(refreshState)
refreshState()

---------------------------------------------------------------- world helpers
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function raycastInto(folderNames, ray)
	local list = {}
	for _, name in folderNames do
		local f = workspace:FindFirstChild(name)
		if f then table.insert(list, f) end
	end
	rayParams.FilterDescendantsInstances = list
	return workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
end

local function inputRay(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return camera:ScreenPointToRay(input.Position.X, input.Position.Y)
	end
	local m = UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(m.X, m.Y)
end

local function makeRangeRing(range)
	return new("Part", {
		Name = "RangeRing", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false,
		CanQuery = false, CastShadow = false, Size = Vector3.new(0.2, range * 2, range * 2),
		Material = Enum.Material.ForceField, Transparency = 0.3,
	})
end

local function ringCFrame(pos)
	return CFrame.new(pos.X, 1.15, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
end

---------------------------------------------------------------- upgrade panel
local selected = nil
local selectedConns = {}
local selectedRing = nil

local towerPanel = panel({
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(290, 0),
	AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui,
}, {
	padding(14),
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 1, Parent = towerPanel })
local headerIconHolder = new("Frame", { Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Parent = header })
local panelTitle = label({
	Position = UDim2.fromOffset(54, 0), Size = UDim2.new(1, -90, 0, 24), FontFace = Theme.FontHeavy, TextSize = 21,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
})
local pipRow = new("Frame", {
	Position = UDim2.fromOffset(54, 30), Size = UDim2.fromOffset(120, 8), BackgroundTransparency = 1, Parent = header,
}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5) }) })
local closeBtn = actionButton({
	Name = "Close", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 0, 0), Color = C.PanelLight,
	Text = "X", TextSize = 16, Parent = header,
})

new("Frame", {
	Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BackgroundTransparency = 0.88, BorderSizePixel = 0,
	LayoutOrder = 2, Parent = towerPanel,
})

local statsBox = new("Frame", {
	Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	LayoutOrder = 3, Parent = towerPanel,
}, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

local upgradeBtn = actionButton({ Name = "Upgrade", Size = UDim2.new(1, 0, 0, 44), Color = C.Upgrade, TextSize = 19, LayoutOrder = 4, Parent = towerPanel })

local btnRow = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 5, Parent = towerPanel })
local targetBtn = actionButton({ Name = "Target", Size = UDim2.new(0.5, -5, 1, 0), Color = C.Target, TextSize = 16, Parent = btnRow })
local sellBtn = actionButton({
	Name = "Sell", Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0), Color = C.Sell, TextSize = 16, Parent = btnRow,
})
local ownerNote = label({
	Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = C.SubText, Text = "Owned by another player",
	LayoutOrder = 6, Visible = false, Parent = towerPanel,
})

local function fmtNum(n)
	if type(n) ~= "number" then return tostring(n) end
	return if n == math.floor(n) then tostring(n) else string.format("%.1f", n)
end

local function statRow(order, name, cur, nxt, suffix)
	suffix = suffix or ""
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order, Parent = statsBox })
	label({ Size = UDim2.fromScale(0.5, 1), Text = name, TextColor3 = C.SubText, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local valueText = fmtNum(cur) .. suffix
	if nxt ~= nil and nxt ~= cur then
		valueText ..= string.format('  <font color="#6EEB82">→ %s%s</font>', fmtNum(nxt), suffix)
	end
	label({
		Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), Text = valueText, RichText = true,
		FontFace = Theme.FontBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
	})
end

local function refreshPanel()
	if not selected then return end
	local kind = selected:GetAttribute("Kind")
	local level = selected:GetAttribute("Level") or 1
	local def = Config.Towers[kind]
	if not def then return end
	local s, n = def.Levels[level], def.Levels[level + 1]

	panelTitle.Text = def.DisplayName
	for _, child in headerIconHolder:GetChildren() do child:Destroy() end
	icon({ Size = UDim2.fromScale(1, 1), Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = headerIconHolder })

	for _, child in pipRow:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	for i = 1, #def.Levels do
		new("Frame", {
			Size = UDim2.fromOffset(26, 8), BorderSizePixel = 0, LayoutOrder = i,
			BackgroundColor3 = if i <= level then C.Gold else C.PanelLight, Parent = pipRow,
		}, { corner(999) })
	end

	for _, child in statsBox:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	if def.Type == "Farm" then
		statRow(1, "Cash per wave", s.Income, n and n.Income)
	elseif def.Type == "Support" then
		statRow(1, "Boost range", s.Range, n and n.Range)
		statRow(2, "Damage boost", math.floor(s.DamageBuff * 100), n and math.floor(n.DamageBuff * 100), "%")
		statRow(3, "Fire rate boost", math.floor(s.SpeedBuff * 100), n and math.floor(n.SpeedBuff * 100), "%")
	else
		statRow(1, "Damage", s.Damage, n and n.Damage)
		statRow(2, "Range", s.Range, n and n.Range)
		statRow(3, "Shots / sec", 1 / s.Cooldown, n and 1 / n.Cooldown)
		if s.Splash then statRow(4, "Splash", s.Splash, n and n.Splash) end
		if s.Slow then
			statRow(5, "Slow", math.floor((1 - s.Slow) * 100), n and math.floor((1 - n.Slow) * 100), "%")
		end
		if s.Chains then statRow(6, "Chains", s.Chains, n and n.Chains) end
		statRow(7, "Hits flying", if def.HitsFlying then "Yes" else "No")
		if def.RevealsHidden then statRow(8, "Reveals hidden", "Yes") end
	end

	local mine = selected:GetAttribute("OwnerId") == player.UserId
	upgradeBtn.Visible, btnRow.Visible, ownerNote.Visible = mine, mine, not mine
	if mine then
		if n then
			upgradeBtn.Text = "Upgrade   $" .. n.Cost
			setButtonColor(upgradeBtn, if cash.Value >= n.Cost then C.Upgrade else C.Disabled)
		else
			upgradeBtn.Text = "MAX LEVEL"
			setButtonColor(upgradeBtn, C.Disabled)
		end
		targetBtn.Text = "Target: " .. (selected:GetAttribute("Targeting") or "First")
		sellBtn.Text = "Sell  $" .. Config.SellValue(kind, level)
	end

	if selectedRing then
		selectedRing.Size = Vector3.new(0.2, s.Range * 2, s.Range * 2)
		selectedRing.CFrame = ringCFrame(selected:GetPivot().Position)
	end
end

local function deselect()
	for _, c in selectedConns do c:Disconnect() end
	table.clear(selectedConns)
	if selectedRing then
		selectedRing:Destroy()
		selectedRing = nil
	end
	selected = nil
	towerPanel.Visible = false
end

local function selectTower(model)
	deselect()
	selected = model
	local def = Config.Towers[model:GetAttribute("Kind")]
	selectedRing = makeRangeRing(def.Levels[1].Range)
	selectedRing.Color = def.Color
	selectedRing.Parent = workspace
	table.insert(selectedConns, model.AttributeChanged:Connect(refreshPanel))
	table.insert(selectedConns, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then deselect() end
	end))
	towerPanel.Visible = true
	refreshPanel()
end

local function doAction(action)
	if not selected then return end
	local ok, msg = actionRemote:InvokeServer(action, selected:GetAttribute("Id"))
	showMessage(msg, ok)
	refreshPanel()
end

closeBtn.Activated:Connect(deselect)
upgradeBtn.Activated:Connect(function() doAction("Upgrade") end)
targetBtn.Activated:Connect(function() doAction("Target") end)
sellBtn.Activated:Connect(function() doAction("Sell") end)

---------------------------------------------------------------- tower hotbar
local hotbar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(0, 118),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = gui,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local cards = {} -- kind -> { card, stroke, cost, iconFrame }
local placing = nil
local ghost = nil

local function refreshCards()
	for kind, c in cards do
		local cost = Config.Towers[kind].Levels[1].Cost
		local affordable = cash.Value >= cost
		local active = placing == kind
		c.cost.TextColor3 = if affordable then C.Gold else C.Bad
		local art = c.iconFrame:FindFirstChild("Art")
		if art then
			art.ImageTransparency = if affordable then 0 else 0.5
		else
			c.iconFrame.BackgroundTransparency = if affordable then 0 else 0.5
		end
		c.stroke.Color = if active then Config.Towers[kind].Color else C.Stroke
		c.stroke.Transparency = if active then 0 else 0.88
		c.stroke.Thickness = if active then 3 else 1.5
	end
end

---------------------------------------------------------------- placement
local function cancelPlacing()
	placing = nil
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	hintPill.Visible = false
	refreshCards()
end

local function startPlacing(kind)
	cancelPlacing()
	deselect()
	local def = Config.Towers[kind]
	if cash.Value < def.Levels[1].Cost then
		showMessage("Not enough cash!", false)
		return
	end
	placing = kind
	hintPill.Visible = true
	ghost = new("Model", { Name = "PlacementGhost" })
	makeRangeRing(def.Levels[1].Range).Parent = ghost
	new("Part", {
		Name = "Body", Shape = Enum.PartType.Ball, Anchored = true, CanCollide = false, CanQuery = false,
		Size = Vector3.one * 3, Material = Enum.Material.Neon, Transparency = 0.4, Parent = ghost,
	})
	ghost.Parent = workspace
	refreshCards()
end

local function togglePlacing(kind)
	if placing == kind then
		cancelPlacing()
	else
		startPlacing(kind)
	end
end

-- Only towers this player has unlocked go on the hotbar.
local loadStart = os.clock()
while not player:GetAttribute("DataLoaded") and os.clock() - loadStart < 10 do
	task.wait(0.1)
end
local owned = {}
for _, kind in string.split(player:GetAttribute("OwnedTowers") or "", ",") do
	owned[kind] = true
end
for _, kind in Config.StarterTowers do
	owned[kind] = true
end
-- Hotbar = the loadout picked in the lobby (falls back to owned towers if it's missing).
local loadout = {}
for _, kind in string.split(player:GetAttribute("Loadout") or "", ",") do
	if Config.Towers[kind] and owned[kind] then table.insert(loadout, kind) end
end
if #loadout == 0 then
	for _, kind in Config.TowerOrder do
		if owned[kind] and #loadout < Config.LoadoutSize then table.insert(loadout, kind) end
	end
end

for i, kind in loadout do
	local def = Config.Towers[kind]
	local card = new("TextButton", {
		Name = kind, Size = UDim2.fromOffset(104, 118), BackgroundColor3 = C.Panel,
		BackgroundTransparency = Theme.PanelTransparency, AutoButtonColor = false, Text = "", LayoutOrder = i, Parent = hotbar,
	}, { corner() })
	local cardStroke = stroke()
	cardStroke.Parent = card
	local cardScale = new("UIScale", { Parent = card })

	local iconFrame = icon({
		Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0),
		Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = card,
	})
	label({
		Position = UDim2.fromOffset(4, 68), Size = UDim2.new(1, -8, 0, 20), Text = def.DisplayName, TextSize = 15,
		FontFace = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	})
	local costLbl = label({
		Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 0, 20), Text = "$" .. def.Levels[1].Cost,
		FontFace = Theme.FontHeavy, TextSize = 17, TextColor3 = C.Gold, Parent = card,
	})
	local keyBadge = new("Frame", {
		Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.PanelLight, Parent = card,
	}, { corner(6) })
	label({ Size = UDim2.fromScale(1, 1), Text = tostring(i), FontFace = Theme.FontBold, TextSize = 13, TextColor3 = C.SubText, Parent = keyBadge })

	card.MouseEnter:Connect(function() tween(cardScale, 0.12, { Scale = 1.06 }) end)
	card.MouseLeave:Connect(function() tween(cardScale, 0.12, { Scale = 1 }) end)
	card.Activated:Connect(function() togglePlacing(kind) end)

	cards[kind] = { card = card, stroke = cardStroke, cost = costLbl, iconFrame = iconFrame }
end

RunService.RenderStepped:Connect(function()
	if not (placing and ghost) then return end
	local hit = raycastInto({ "Map", "Towers" }, inputRay(nil))
	if not hit then return end
	local valid = hit.Instance.Name == "Ground"
	local color = if valid then Color3.fromRGB(80, 255, 80) else Color3.fromRGB(255, 70, 70)
	local ring, body = ghost:FindFirstChild("RangeRing"), ghost:FindFirstChild("Body")
	ring.CFrame = ringCFrame(hit.Position)
	body.Position = hit.Position + Vector3.new(0, 2, 0)
	ring.Color = color
	body.Color = color
end)

local function towerModelFrom(inst)
	local towersFolder = workspace:FindFirstChild("Towers")
	while inst and inst.Parent ~= towersFolder do
		inst = inst.Parent
	end
	return inst
end

local hotkeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		cancelPlacing()
		deselect()
		return
	end
	local slot = table.find(hotkeys, input.KeyCode)
	if slot and loadout[slot] then
		togglePlacing(loadout[slot])
		return
	end

	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	if not isClick then return end

	if placing then
		local kind = placing
		local hit = raycastInto({ "Map", "Towers" }, inputRay(input))
		if not hit then return end
		local ok, msg = placeRemote:InvokeServer(kind, hit.Position)
		showMessage(msg, ok)
		if ok then cancelPlacing() end
	else
		local hit = raycastInto({ "Towers" }, inputRay(input))
		local model = hit and towerModelFrom(hit.Instance)
		if model then
			selectTower(model)
		elseif selected then
			deselect()
		end
	end
end)

---------------------------------------------------------------- cash
local function refreshCash()
	cashLbl.Text = tostring(cash.Value)
	refreshCards()
	refreshPanel()
end
cash.Changed:Connect(refreshCash)
refreshCash()
