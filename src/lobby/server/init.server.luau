-- Brainrot Tower Defense: lobby server (queue pads, difficulty select, shop, teleport to matches).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("DataService"))
local RateLimit = require(game:GetService("ServerScriptService").Common:WaitForChild("RateLimit"))
require(game:GetService("ServerScriptService").Common:WaitForChild("DevCommands")).start()
DataService.start()

local QUEUE_TIME = 20
local PAD_RADIUS = 7

---------------------------------------------------------------- helpers
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then p.Shape = props.Shape end
	if props.Size then p.Size = props.Size end
	for k, v in props do
		if k ~= "Shape" and k ~= "Size" then p[k] = v end
	end
	p.Parent = parent
	return p
end

local function billboard(adornee, size, offset)
	local bb = Instance.new("BillboardGui")
	bb.Size = size
	bb.StudsOffset = offset
	bb.AlwaysOnTop = false
	bb.MaxDistance = 120
	bb.Parent = adornee
	return bb
end

local function bbText(parent, text, pos, size, color, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = pos
	t.Size = size
	t.Text = text
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Parent = parent
	return t
end

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

---------------------------------------------------------------- lobby world
Lighting.ClockTime = 15
Lighting.Brightness = 2.5
Lighting.Ambient = Color3.fromRGB(90, 70, 110)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 130, 170)

local old = workspace:FindFirstChild("Lobby")
if old then old:Destroy() end
local lobby = Instance.new("Folder")
lobby.Name = "Lobby"

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

part({ Name = "Floor", Size = Vector3.new(160, 4, 120), Position = Vector3.new(0, -2, 0),
	Color = Color3.fromRGB(110, 90, 170), Material = Enum.Material.SmoothPlastic }, lobby)
part({ Name = "FloorInner", Size = Vector3.new(140, 0.2, 100), Position = Vector3.new(0, 0.1, 0),
	Color = Color3.fromRGB(140, 120, 210), Material = Enum.Material.SmoothPlastic }, lobby)
for _, x in { -80, 80 } do
	part({ Name = "Wall", Size = Vector3.new(2, 8, 120), Position = Vector3.new(x, 4, 0), Transparency = 0.6,
		Color = Color3.fromRGB(255, 120, 220), Material = Enum.Material.Neon }, lobby)
end
for _, z in { -60, 60 } do
	part({ Name = "Wall", Size = Vector3.new(160, 8, 2), Position = Vector3.new(0, 4, z), Transparency = 0.6,
		Color = Color3.fromRGB(255, 120, 220), Material = Enum.Material.Neon }, lobby)
end

-- Title sign
local sign = part({ Name = "TitleSign", Size = Vector3.new(60, 14, 2), Position = Vector3.new(0, 18, -58),
	Color = Color3.fromRGB(30, 20, 50), Material = Enum.Material.SmoothPlastic }, lobby)
local signGui = Instance.new("SurfaceGui")
signGui.Face = Enum.NormalId.Back
signGui.CanvasSize = Vector2.new(600, 140)
signGui.Parent = sign
bbText(signGui, "BRAINROT", UDim2.fromScale(0, 0.02), UDim2.fromScale(1, 0.55), Color3.fromRGB(255, 120, 220))
bbText(signGui, "TOWER DEFENSE", UDim2.fromScale(0, 0.58), UDim2.fromScale(1, 0.38), Color3.fromRGB(255, 220, 60))

local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawn then
	spawn = Instance.new("SpawnLocation")
	spawn.Parent = workspace
end
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 35)
spawn.Transparency = 0.5
spawn.Color = Color3.fromRGB(255, 220, 60)
spawn.Material = Enum.Material.Neon
spawn.Duration = 0

---------------------------------------------------------------- queue pads
local pads = {}
local PAD_SPOTS = { Vector3.new(-40, 0, -25), Vector3.new(0, 0, -25), Vector3.new(40, 0, -25) }

for i, pos in PAD_SPOTS do
	local model = Instance.new("Model")
	model.Name = "Pad" .. i
	local ring = part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, PAD_RADIUS * 2, PAD_RADIUS * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * UPRIGHT, Color = Color3.fromRGB(90, 160, 255),
		Material = Enum.Material.Neon, Transparency = 0.2 }, model)
	for _, side in { -1, 1 } do
		part({ Name = "Pillar", Size = Vector3.new(1.5, 14, 1.5), Position = pos + Vector3.new(side * (PAD_RADIUS + 1), 7, 0),
			Color = Color3.fromRGB(40, 30, 70), Material = Enum.Material.Slate }, model)
	end
	part({ Name = "Arch", Size = Vector3.new(PAD_RADIUS * 2 + 4, 1.5, 1.5), Position = pos + Vector3.new(0, 14, 0),
		Color = Color3.fromRGB(40, 30, 70), Material = Enum.Material.Slate }, model)
	local bb = billboard(ring, UDim2.fromOffset(260, 110), Vector3.new(0, 10, 0))
	local title = bbText(bb, "PLAY", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.4))
	local info = bbText(bb, "", UDim2.fromScale(0, 0.42), UDim2.fromScale(1, 0.28), Color3.fromRGB(255, 220, 60))
	local timerLbl = bbText(bb, "", UDim2.fromScale(0, 0.72), UDim2.fromScale(1, 0.28), Color3.fromRGB(200, 200, 230))
	model.Parent = lobby

	pads[i] = {
		id = i, center = pos, ring = ring, title = title, info = info, timerLbl = timerLbl,
		players = {}, difficulty = "Normal", timer = 0, launching = false,
	}
end

lobby.Parent = workspace

---------------------------------------------------------------- pad logic
local function padOf(player)
	for _, pad in pads do
		if table.find(pad.players, player) then return pad end
	end
	return nil
end

local function leader(pad)
	return pad.players[1]
end

local function isUnlocked(player, diffId)
	local diff = Config.GetDifficulty(diffId)
	if diff.Id ~= diffId then return false end
	if not diff.Requires then return true end
	local data = DataService.get(player)
	return data ~= nil and data.Beaten[diff.Requires] == true
end

local function defaultDifficulty(player)
	return if isUnlocked(player, "Normal") then "Normal" else Config.Difficulties[1].Id
end

local function syncPad(pad)
	local diff = Config.GetDifficulty(pad.difficulty)
	pad.ring.Color = if #pad.players > 0 then diff.Color else Color3.fromRGB(90, 160, 255)
	pad.title.Text = if #pad.players > 0 then diff.DisplayName else "PLAY"
	pad.title.TextColor3 = if #pad.players > 0 then diff.Color else Color3.new(1, 1, 1)
	pad.info.Text = string.format("%d / %d players", #pad.players, Config.MaxPartySize)
	pad.timerLbl.Text = if pad.launching then "Teleporting..." elseif #pad.players > 0 then "Starting in " .. math.ceil(pad.timer) else "Step in to play"
	for _, p in pad.players do
		p:SetAttribute("QueuePad", pad.id)
		p:SetAttribute("QueueLeader", leader(pad) == p)
		p:SetAttribute("QueueDifficulty", pad.difficulty)
		p:SetAttribute("QueueCount", #pad.players)
		p:SetAttribute("QueueTimer", math.ceil(pad.timer))
	end
end

local function clearQueueAttrs(player)
	for _, a in { "QueuePad", "QueueLeader", "QueueDifficulty", "QueueCount", "QueueTimer" } do
		player:SetAttribute(a, nil)
	end
end

local function pushOff(player, pad)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(pad.center + Vector3.new(0, 3, PAD_RADIUS + 6))
	end
end

local function removeFromPad(player, pad, push)
	local idx = table.find(pad.players, player)
	if not idx then return end
	table.remove(pad.players, idx)
	clearQueueAttrs(player)
	if push then pushOff(player, pad) end
	if #pad.players == 0 then
		pad.difficulty = "Normal"
		pad.timer = 0
	end
	syncPad(pad)
end

local function addToPad(player, pad)
	if #pad.players >= Config.MaxPartySize or pad.launching then
		pushOff(player, pad)
		return
	end
	table.insert(pad.players, player)
	if #pad.players == 1 then
		pad.timer = QUEUE_TIME
		pad.difficulty = defaultDifficulty(player)
	end
	syncPad(pad)
end

local function launch(pad)
	pad.launching = true
	syncPad(pad)
	local group = table.clone(pad.players)
	for _, p in group do
		DataService.save(p, true) -- release the lock so the match server can load it
	end
	local ok, err = pcall(function()
		if RunService:IsStudio() then
			error("Teleports only work in the live game (publish, then play from the Roblox website).")
		end
		local code = TeleportService:ReserveServer(Config.PlaceIds.Match)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ Difficulty = pad.difficulty, PartySize = #group })
		TeleportService:TeleportAsync(Config.PlaceIds.Match, group, options)
	end)
	if ok then
		task.wait(6) -- give the teleport time to finish before freeing the pad
	else
		warn("[Lobby] Teleport failed: " .. tostring(err))
		for _, p in group do
			p:SetAttribute("LobbyMessage", "Teleport failed: " .. tostring(err))
		end
		task.wait(3)
	end
	for _, p in group do
		if p.Parent then removeFromPad(p, pad, true) end
	end
	pad.launching = false
	pad.players = {}
	syncPad(pad)
end

for _, pad in pads do
	syncPad(pad)
end

-- Detect who is standing on each pad.
task.spawn(function()
	while true do
		local dt = task.wait(0.25)
		for _, pad in pads do
			if not pad.launching then
				for _, p in Players:GetPlayers() do
					local char = p.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					local onPad = false
					if root then
						local offset = root.Position - pad.center
						onPad = Vector2.new(offset.X, offset.Z).Magnitude < PAD_RADIUS and offset.Y < 10
					end
					local current = padOf(p)
					if onPad and not current and p:GetAttribute("DataLoaded") then
						addToPad(p, pad)
					elseif current == pad and not onPad then
						removeFromPad(p, pad, false)
					end
				end
				if #pad.players > 0 then
					pad.timer -= dt
					if pad.timer <= 0 then
						task.spawn(launch, pad)
					end
					syncPad(pad)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	local pad = padOf(p)
	if pad then removeFromPad(p, pad, false) end
end)

---------------------------------------------------------------- remotes
local function makeRemote(name, handler)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r then r:Destroy() end
	r = Instance.new("RemoteFunction")
	r.Name = name
	r.OnServerInvoke = RateLimit.wrap(handler, 4, 1) -- max 4 calls/second per player
	r.Parent = ReplicatedStorage
end

makeRemote("QueueAction", function(player, action, arg)
	local pad = padOf(player)
	if not pad or pad.launching then return false, "You're not in a queue" end
	if action == "Leave" then
		removeFromPad(player, pad, true)
		return true, "Left the queue"
	end
	if leader(pad) ~= player then return false, "Only the party leader can do that" end
	if action == "Difficulty" then
		if typeof(arg) ~= "string" or not isUnlocked(player, arg) then
			return false, "That difficulty is locked!"
		end
		pad.difficulty = arg
		syncPad(pad)
		return true, Config.GetDifficulty(arg).DisplayName .. " selected"
	elseif action == "Start" then
		pad.timer = math.min(pad.timer, 3)
		syncPad(pad)
		return true, "Starting!"
	end
	return false, "Unknown action"
end)

---------------------------------------------------------------- crates
-- All rolls happen here on the server; the client only plays the animation for the result.
local rng = Random.new()
local opening = {} -- player -> true while a crate is being processed

local function pickWeighted(weights)
	local total = 0
	for _, w in weights do total += w.weight end
	local roll = rng:NextNumber() * total
	for _, w in weights do
		roll -= w.weight
		if roll <= 0 then return w.id end
	end
	return weights[#weights].id
end

local function rollCrate(crate, pity)
	local odds = Config.CrateOdds(crate)
	local _, legendaryIndex = Config.GetRarity("Legendary")
	local forced = pity >= Config.PityThreshold - 1
	local weights = {}
	for i, r in Config.Rarities do
		local chance = odds[r.Id]
		if chance > 0 and (not forced or i >= legendaryIndex) then
			table.insert(weights, { id = r.Id, weight = chance })
		end
	end
	if #weights == 0 then -- crate has no Legendary+ odds: fall back to normal odds
		for _, r in Config.Rarities do
			if odds[r.Id] > 0 then table.insert(weights, { id = r.Id, weight = odds[r.Id] }) end
		end
	end
	local rarityId = pickWeighted(weights)
	local pool = Config.TowersOfRarity(rarityId)
	return pool[rng:NextInteger(1, #pool)], rarityId
end

makeRemote("OpenCrate", function(player, crateId)
	local crate = typeof(crateId) == "string" and Config.GetCrate(crateId)
	if not crate then return false, "Unknown crate" end
	if opening[player] then return false, "Already opening a crate!" end
	local data = DataService.get(player)
	if not data then return false, "Your data hasn't loaded yet" end
	if data.Coins < crate.Price then return false, "Not enough " .. Config.CurrencyName .. "!" end

	opening[player] = true
	local kind, rarityId = rollCrate(crate, data.Pity)
	local rarity, rarityIndex = Config.GetRarity(rarityId)
	local _, legendaryIndex = Config.GetRarity("Legendary")
	local duplicate = data.Towers[kind] == true
	local refund = if duplicate then rarity.Refund else 0

	DataService.update(player, function(d)
		d.Coins -= crate.Price
		d.Coins += refund
		d.Towers[kind] = true
		d.CratesOpened += 1
		d.Pity = if rarityIndex >= legendaryIndex then 0 else d.Pity + 1
	end)
	task.spawn(function()
		DataService.save(player)
		task.wait(0.5)
		opening[player] = nil
	end)
	return true, { Tower = kind, Rarity = rarityId, Duplicate = duplicate, Refund = refund }
end)

Players.PlayerRemoving:Connect(function(p)
	opening[p] = nil
end)
