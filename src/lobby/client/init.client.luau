-- Brainrot Tower Defense: lobby UI (coins, shop, queue panel with difficulty select).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Theme = require(Shared:WaitForChild("Theme"))
local UI = require(Shared:WaitForChild("UIKit"))
local C = Theme.Colors

local player = Players.LocalPlayer
local queueRemote = ReplicatedStorage:WaitForChild("QueueAction")
local crateRemote = ReplicatedStorage:WaitForChild("OpenCrate")
local CrateOpening = require(script.CrateOpening)

local gui = UI.screen("LobbyHud", player:WaitForChild("PlayerGui"))
local toast = UI.toast(gui)

---------------------------------------------------------------- top-left: coins + wins
local statsRow = UI.new("Frame", {
	Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(0, 46), AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1, Parent = gui,
}, { UI.list(Enum.FillDirection.Horizontal, 10, nil, Enum.VerticalAlignment.Center) })

local function statPill(order, iconKey, glyph, color, width)
	local pill = UI.panel({ Size = UDim2.fromOffset(width, 46), LayoutOrder = order, Parent = statsRow })
	UI.icon({ Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(6, 6), Color = color,
		Image = iconKey and Theme.Icons[iconKey], Glyph = glyph, Parent = pill })
	return UI.label({ Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -56, 1, 0), FontFace = Theme.FontHeavy,
		TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = pill })
end

local coinsLbl = statPill(1, nil, "C", C.Gold, 150)
local winsLbl = statPill(2, nil, "W", C.Wave, 120)

---------------------------------------------------------------- shop button + panel
local shopBtn = UI.button({
	Name = "ShopButton", Size = UDim2.fromOffset(150, 52), Position = UDim2.new(0, 16, 1, -16), AnchorPoint = Vector2.new(0, 1),
	Color = C.Gold:Lerp(C.Sell, 0.35), Text = "CRATES", TextSize = 24, Radius = 14, Parent = gui,
})
shopBtn.FontFace = Theme.FontHeavy

local shop = UI.panel({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 440),
	Visible = false, ZIndex = 10, Parent = gui,
}, { UI.padding(18) })
UI.label({ Size = UDim2.new(1, -40, 0, 32), Text = "Crates", FontFace = Theme.FontHeavy, TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
local pityLbl = UI.label({ Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, -40, 0, 20), TextSize = 15, TextColor3 = C.SubText,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
local closeShop = UI.button({ Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 0), Color = C.PanelLight, Text = "X", Parent = shop })

local crateRow = UI.new("Frame", {
	Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66), BackgroundTransparency = 1, Parent = shop,
}, { UI.list(Enum.FillDirection.Horizontal, 16, Enum.HorizontalAlignment.Center) })

-- Odds popup
local oddsPanel = UI.panel({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(360, 0),
	AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 20, Parent = gui,
}, { UI.padding(16), UI.list(nil, 6) })
local oddsTitle = UI.label({ Size = UDim2.new(1, 0, 0, 28), FontFace = Theme.FontHeavy, TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = oddsPanel })
local oddsRows = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, LayoutOrder = 1, Parent = oddsPanel }, { UI.list(nil, 6) })
local oddsClose = UI.button({ Size = UDim2.new(1, 0, 0, 36), Color = C.PanelLight, Text = "Close", LayoutOrder = 2, Parent = oddsPanel })
oddsClose.Activated:Connect(function() oddsPanel.Visible = false end)

local function showOdds(crate)
	oddsTitle.Text = crate.DisplayName .. " odds"
	for _, child in oddsRows:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	local odds = Config.CrateOdds(crate)
	for i, r in Config.Rarities do
		local towers = Config.TowersOfRarity(r.Id)
		if odds[r.Id] > 0 then
			local names = {}
			for _, kind in towers do table.insert(names, Config.Towers[kind].DisplayName) end
			local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.PanelLight, LayoutOrder = i, Parent = oddsRows },
				{ UI.corner(8), UI.padding(10, 4) })
			UI.label({ Size = UDim2.new(0.6, 0, 0, 18), Text = r.Id, FontFace = Theme.FontHeavy, TextSize = 16,
				TextColor3 = r.Color, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
			UI.label({ Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, -70, 0, 16), Text = table.concat(names, ", "),
				TextSize = 13, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
			UI.label({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(70, 20),
				Text = string.format("%.1f%%", odds[r.Id] * 100), FontFace = Theme.FontBold, TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
		end
	end
	oddsPanel.Visible = true
end

local crateButtons = {}
local busy = false

for i, crate in Config.Crates do
	local card = UI.new("Frame", { Size = UDim2.fromOffset(280, 334), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0.3,
		LayoutOrder = i, Parent = crateRow }, { UI.corner(14), UI.padding(14) })
	UI.stroke(crate.Color, 0.3, 2.5).Parent = card
	local art = CrateOpening.crateArt(crate, UDim2.fromOffset(150, 150), card)
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0, 4)
	UI.label({ Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 28), Text = crate.DisplayName,
		FontFace = Theme.FontHeavy, TextSize = 24, TextColor3 = crate.Color, Parent = card })
	local odds = Config.CrateOdds(crate)
	local best = ""
	for _, r in Config.Rarities do
		if odds[r.Id] > 0 then best = string.format("%s %.1f%%", r.Id, odds[r.Id] * 100) end
	end
	UI.label({ Position = UDim2.fromOffset(0, 192), Size = UDim2.new(1, 0, 0, 20), Text = "Best drop: " .. best,
		TextSize = 14, TextColor3 = C.SubText, Parent = card })
	local oddsBtn = UI.button({ Position = UDim2.new(0, 0, 1, -98), Size = UDim2.new(1, 0, 0, 34), Color = C.Target,
		Text = "View odds", TextSize = 16, Parent = card })
	oddsBtn.Activated:Connect(function() showOdds(crate) end)
	local openBtn = UI.button({ Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 54), Color = C.Upgrade,
		Text = "OPEN  ·  " .. crate.Price .. " " .. Config.CurrencyName, TextSize = 19, Parent = card })
	openBtn.FontFace = Theme.FontHeavy
	openBtn.Activated:Connect(function()
		if busy then return end
		busy = true
		local ok, result = crateRemote:InvokeServer(crate.Id)
		if ok then
			shop.Visible = false
			CrateOpening.play(gui, crate, result)
			shop.Visible = true
		else
			toast(result, false)
		end
		busy = false
	end)
	crateButtons[crate.Id] = { button = openBtn, crate = crate }
end

local function refreshShop()
	local coins = player:GetAttribute("Coins") or 0
	for _, c in crateButtons do
		UI.setButtonColor(c.button, if coins >= c.crate.Price then C.Upgrade else C.Disabled)
	end
	local pity = player:GetAttribute("Pity") or 0
	pityLbl.Text = string.format("Guaranteed Legendary in %d crates  ·  Duplicates give %s back",
		math.max(Config.PityThreshold - pity, 1), Config.CurrencyName)
end

shopBtn.Activated:Connect(function() shop.Visible = not shop.Visible end)
closeShop.Activated:Connect(function() shop.Visible = false end)

---------------------------------------------------------------- towers / loadout panel
local loadoutRemote = ReplicatedStorage:WaitForChild("ToggleLoadout")

local towersBtn = UI.button({
	Name = "TowersButton", Size = UDim2.fromOffset(150, 52), Position = UDim2.new(0, 16, 1, -78), AnchorPoint = Vector2.new(0, 1),
	Color = C.Target, Text = "TOWERS", TextSize = 24, Radius = 14, Parent = gui,
})
towersBtn.FontFace = Theme.FontHeavy

local towersPanel = UI.panel({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 600),
	Visible = false, ZIndex = 10, Parent = gui,
}, { UI.padding(18) })
UI.label({ Size = UDim2.new(1, -40, 0, 32), Text = "Towers", FontFace = Theme.FontHeavy, TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = towersPanel })
local loadoutLbl = UI.label({ Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, -40, 0, 20), TextSize = 15,
	TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = towersPanel })
local closeTowers = UI.button({ Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 0), Color = C.PanelLight, Text = "X", Parent = towersPanel })

local towerGrid = UI.new("Frame", {
	Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 354), BackgroundTransparency = 1, Parent = towersPanel,
}, {
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(140, 172), CellPadding = UDim2.fromOffset(10, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})

local towerCards = {}
for i, kind in Config.TowerOrder do
	local def = Config.Towers[kind]
	local rarity = Config.GetRarity(def.Rarity or "Common")
	local card = UI.new("TextButton", { BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0.3, AutoButtonColor = false,
		Text = "", LayoutOrder = i, Parent = towerGrid }, { UI.corner(12) })
	local cardStroke = UI.stroke(rarity.Color, 0.5, 2)
	cardStroke.Parent = card
	local iconFrame = UI.icon({ Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0.5, 0, 0, 12), AnchorPoint = Vector2.new(0.5, 0),
		Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = card })
	UI.label({ Position = UDim2.fromOffset(4, 88), Size = UDim2.new(1, -8, 0, 20), Text = def.DisplayName,
		FontFace = Theme.FontBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	UI.label({ Position = UDim2.fromOffset(0, 108), Size = UDim2.new(1, 0, 0, 16), Text = rarity.Id:upper(),
		FontFace = Theme.FontHeavy, TextSize = 12, TextColor3 = rarity.Color, Parent = card })
	local status = UI.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -20, 0, 26),
		BackgroundTransparency = 0, BackgroundColor3 = C.Panel, FontFace = Theme.FontBold, TextSize = 14, Parent = card })
	UI.corner(8).Parent = status
	card.Activated:Connect(function()
		local ok, msg = loadoutRemote:InvokeServer(kind)
		toast(msg, ok)
	end)
	towerCards[kind] = { card = card, stroke = cardStroke, status = status, icon = iconFrame }
end

-- Hotbar preview: exactly what the bottom of the screen will look like in a match.
UI.new("Frame", { Position = UDim2.fromOffset(0, 426), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke,
	BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = towersPanel })
UI.label({ Position = UDim2.fromOffset(0, 434), Size = UDim2.new(1, 0, 0, 18), Text = "YOUR MATCH HOTBAR  ·  click a slot to unequip",
	FontFace = Theme.FontBold, TextSize = 13, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = towersPanel })
local hotbarPreview = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(0, 104),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = towersPanel,
}, { UI.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center) })

local lastPreviewKey = nil
local function refreshHotbarPreview(loadout)
	for _, child in hotbarPreview:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	for slot = 1, Config.LoadoutSize do
		local kind = loadout[slot]
		local def = kind and Config.Towers[kind]
		local card = UI.new("TextButton", { Size = UDim2.fromOffset(96, 104), BackgroundColor3 = C.Panel, BackgroundTransparency = 0.1,
			AutoButtonColor = false, Text = "", LayoutOrder = slot, Parent = hotbarPreview }, { UI.corner(12) })
		local badge = UI.new("Frame", { Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = C.PanelLight,
			ZIndex = 2, Parent = card }, { UI.corner(5) })
		UI.label({ Size = UDim2.fromScale(1, 1), Text = tostring(slot), FontFace = Theme.FontBold, TextSize = 12, TextColor3 = C.SubText,
			ZIndex = 2, Parent = badge })
		if def then
			UI.stroke().Parent = card
			UI.icon({ Size = UDim2.fromOffset(48, 48), Position = UDim2.new(0.5, 0, 0, 8), AnchorPoint = Vector2.new(0.5, 0),
				Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = card })
			UI.label({ Position = UDim2.fromOffset(3, 58), Size = UDim2.new(1, -6, 0, 18), Text = def.DisplayName, TextSize = 13,
				FontFace = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
			UI.label({ Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 18), Text = "$" .. def.Levels[1].Cost,
				FontFace = Theme.FontHeavy, TextSize = 15, TextColor3 = C.Gold, Parent = card })
			card.Activated:Connect(function()
				local ok, msg = loadoutRemote:InvokeServer(kind)
				toast(msg, ok)
			end)
		else
			UI.stroke(C.Stroke, 0.7, 1.5).Parent = card
			card.BackgroundTransparency = 0.6
			UI.label({ Size = UDim2.fromScale(1, 1), Text = "Empty", TextSize = 14, TextColor3 = C.SubText, Parent = card })
		end
	end
end

local function refreshLoadout()
	local owned, equipped = {}, {}
	for _, k in string.split(player:GetAttribute("OwnedTowers") or "", ",") do owned[k] = true end
	local loadout = string.split(player:GetAttribute("Loadout") or "", ",")
	for _, k in loadout do equipped[k] = true end
	local count = 0
	for _, k in loadout do if k ~= "" then count += 1 end end
	local loadoutKey = player:GetAttribute("Loadout") or ""
	if loadoutKey ~= lastPreviewKey then -- only rebuild when the loadout actually changes
		lastPreviewKey = loadoutKey
		local cleanLoadout = {}
		for _, k in loadout do
			if Config.Towers[k] then table.insert(cleanLoadout, k) end
		end
		refreshHotbarPreview(cleanLoadout)
	end
	loadoutLbl.Text = string.format("Equipped %d / %d  ·  Click a tower to equip or unequip it", count, Config.LoadoutSize)

	for kind, c in towerCards do
		local art = c.icon:FindFirstChild("Art")
		if equipped[kind] then
			c.status.Text = "EQUIPPED"
			c.status.TextColor3 = C.Gold
			c.stroke.Transparency, c.stroke.Thickness = 0, 3
		elseif owned[kind] then
			c.status.Text = "Equip"
			c.status.TextColor3 = C.Text
			c.stroke.Transparency, c.stroke.Thickness = 0.5, 2
		else
			c.status.Text = "From crates"
			c.status.TextColor3 = C.SubText
			c.stroke.Transparency, c.stroke.Thickness = 0.8, 2
		end
		local dim = if owned[kind] then 0 else 0.6
		if art then art.ImageTransparency = dim else c.icon.BackgroundTransparency = dim end
	end
end

towersBtn.Activated:Connect(function()
	towersPanel.Visible = not towersPanel.Visible
	shop.Visible = false
end)
closeTowers.Activated:Connect(function() towersPanel.Visible = false end)
shopBtn.Activated:Connect(function() towersPanel.Visible = false end)

---------------------------------------------------------------- queue panel
local queue = UI.panel({
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(300, 0),
	AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = gui,
}, { UI.padding(16), UI.list(nil, 10) })

local queueTitle = UI.label({ Size = UDim2.new(1, 0, 0, 28), FontFace = Theme.FontHeavy, TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "Party", LayoutOrder = 1, Parent = queue })
local queueInfo = UI.label({ Size = UDim2.new(1, 0, 0, 20), TextSize = 16, TextColor3 = C.SubText,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = queue })
UI.label({ Size = UDim2.new(1, 0, 0, 18), TextSize = 14, TextColor3 = C.SubText, Text = "DIFFICULTY",
	FontFace = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = queue })

local diffButtons = {}
local diffBox = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	LayoutOrder = 4, Parent = queue }, { UI.list(nil, 6) })
for i, d in Config.Difficulties do
	local btn = UI.button({ Size = UDim2.new(1, 0, 0, 38), Color = C.PanelLight, TextSize = 17, LayoutOrder = i, Parent = diffBox })
	local btnStroke = UI.stroke(d.Color, 1, 2.5)
	btnStroke.Parent = btn
	btn.Activated:Connect(function()
		local ok, msg = queueRemote:InvokeServer("Difficulty", d.Id)
		toast(msg, ok)
	end)
	diffButtons[d.Id] = { btn = btn, stroke = btnStroke, def = d }
end

local startBtn = UI.button({ Size = UDim2.new(1, 0, 0, 44), Color = C.Upgrade, Text = "START NOW", TextSize = 19, LayoutOrder = 5, Parent = queue })
local leaveBtn = UI.button({ Size = UDim2.new(1, 0, 0, 36), Color = C.Sell, Text = "Leave", TextSize = 16, LayoutOrder = 6, Parent = queue })
local leaderNote = UI.label({ Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextColor3 = C.SubText,
	Text = "The party leader picks the difficulty", LayoutOrder = 7, Parent = queue })

startBtn.Activated:Connect(function()
	local ok, msg = queueRemote:InvokeServer("Start")
	toast(msg, ok)
end)
leaveBtn.Activated:Connect(function()
	local ok, msg = queueRemote:InvokeServer("Leave")
	toast(msg, ok)
end)

local function refreshQueue()
	local padId = player:GetAttribute("QueuePad")
	queue.Visible = padId ~= nil
	if not padId then return end
	local isLeader = player:GetAttribute("QueueLeader") == true
	local current = player:GetAttribute("QueueDifficulty")
	local beaten = {}
	for _, k in string.split(player:GetAttribute("BeatenDifficulties") or "", ",") do beaten[k] = true end

	queueTitle.Text = if isLeader then "Your Party" else "Party"
	queueInfo.Text = string.format("%d / %d players  ·  starts in %ds",
		player:GetAttribute("QueueCount") or 1, Config.MaxPartySize, player:GetAttribute("QueueTimer") or 0)

	for id, b in diffButtons do
		local d = b.def
		local unlocked = not d.Requires or beaten[d.Requires] == true
		local selected = id == current
		b.btn.Text = if unlocked then d.DisplayName else "🔒 " .. d.DisplayName .. "  (beat " .. d.Requires .. ")"
		UI.setButtonColor(b.btn, if selected then d.Color:Lerp(C.Panel, 0.35) else C.PanelLight)
		b.btn.TextTransparency = if unlocked then 0 else 0.5
		b.stroke.Transparency = if selected then 0 else 1
		b.btn.Active = isLeader
	end
	startBtn.Visible = isLeader
	leaderNote.Visible = not isLeader
end

---------------------------------------------------------------- bindings
local function refreshStats()
	coinsLbl.Text = tostring(player:GetAttribute("Coins") or 0)
	winsLbl.Text = tostring(player:GetAttribute("Wins") or 0)
	refreshShop()
	refreshLoadout()
	refreshQueue()
end

player.AttributeChanged:Connect(function(attr)
	if attr == "LobbyMessage" then
		local msg = player:GetAttribute("LobbyMessage")
		if msg then toast(msg, false) end
		player:SetAttribute("LobbyMessage", nil)
		return
	end
	refreshStats()
end)
refreshStats()
