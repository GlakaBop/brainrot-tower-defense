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
local buyRemote = ReplicatedStorage:WaitForChild("BuyTower")

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
	Color = C.Upgrade, Text = "SHOP", TextSize = 24, Radius = 14, Parent = gui,
})
shopBtn.FontFace = Theme.FontHeavy

local shop = UI.panel({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(620, 400),
	Visible = false, ZIndex = 10, Parent = gui,
}, { UI.padding(18) })
UI.label({ Size = UDim2.new(1, -40, 0, 32), Text = "Tower Shop", FontFace = Theme.FontHeavy, TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
UI.label({ Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20), TextSize = 15, TextColor3 = C.SubText,
	TextXAlignment = Enum.TextXAlignment.Left, Text = "Unlock towers with " .. Config.CurrencyName .. " earned from matches.", Parent = shop })
local closeShop = UI.button({ Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 0), Color = C.PanelLight, Text = "X", Parent = shop })

local grid = UI.new("Frame", {
	Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66), BackgroundTransparency = 1, Parent = shop,
}, {
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(136, 290), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local shopCards = {}
for i, kind in Config.TowerOrder do
	local def = Config.Towers[kind]
	local card = UI.new("Frame", { BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0.3, LayoutOrder = i, Parent = grid },
		{ UI.corner(12), UI.padding(10) })
	local cardStroke = UI.stroke(def.Color, 0.6, 2)
	cardStroke.Parent = card
	UI.icon({ Size = UDim2.fromOffset(80, 80), Position = UDim2.new(0.5, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 0),
		Color = def.Color, Image = Theme.Icons.Towers[kind], Glyph = Theme.Glyphs.Towers[kind], Parent = card })
	UI.label({ Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 22), Text = def.DisplayName,
		FontFace = Theme.FontHeavy, TextSize = 17, Parent = card })
	UI.label({ Position = UDim2.fromOffset(0, 122), Size = UDim2.new(1, 0, 0, 60), Text = def.Description or "",
		TextSize = 14, TextColor3 = C.SubText, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
	local lvl = def.Levels[1]
	UI.label({ Position = UDim2.fromOffset(0, 186), Size = UDim2.new(1, 0, 0, 40), RichText = true, TextSize = 13,
		TextColor3 = C.SubText, TextYAlignment = Enum.TextYAlignment.Top,
		Text = string.format("DMG %d  ·  RNG %d\nPlace cost $%d", lvl.Damage, lvl.Range, lvl.Cost), Parent = card })
	local buy = UI.button({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -40), Color = C.Upgrade, TextSize = 17, Parent = card })
	buy.Activated:Connect(function()
		local ok, msg = buyRemote:InvokeServer(kind)
		toast(msg, ok)
	end)
	shopCards[kind] = { buy = buy, stroke = cardStroke }
end

local function refreshShop()
	local owned = {}
	for _, k in string.split(player:GetAttribute("OwnedTowers") or "", ",") do owned[k] = true end
	local coins = player:GetAttribute("Coins") or 0
	for kind, c in shopCards do
		local def = Config.Towers[kind]
		if owned[kind] then
			c.buy.Text = "OWNED"
			UI.setButtonColor(c.buy, C.Disabled)
			c.stroke.Transparency = 0.2
		elseif def.UnlockPrice then
			c.buy.Text = def.UnlockPrice .. " " .. Config.CurrencyName
			UI.setButtonColor(c.buy, if coins >= def.UnlockPrice then C.Upgrade else C.Disabled)
			c.stroke.Transparency = 0.6
		else
			c.buy.Text = "Locked"
			UI.setButtonColor(c.buy, C.Disabled)
		end
	end
end

shopBtn.Activated:Connect(function() shop.Visible = not shop.Visible end)
closeShop.Activated:Connect(function() shop.Visible = false end)

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
