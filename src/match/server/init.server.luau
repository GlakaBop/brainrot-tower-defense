-- Brainrot Tower Defense: server game logic (enemies, towers, waves).
-- Map, enemy looks and effects live in the sibling modules.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(script.Util)
local Effects = require(script.Effects)
local EnemyLooks = require(script.EnemyLooks)
local MapBuilder = require(script.MapBuilder)
local TeleportService = game:GetService("TeleportService")
local DataService = require(game:GetService("ServerScriptService"):WaitForChild("Common"):WaitForChild("DataService"))
local RateLimit = require(game:GetService("ServerScriptService").Common:WaitForChild("RateLimit"))
require(game:GetService("ServerScriptService").Common:WaitForChild("DevCommands")).start()
DataService.start()

local makePart = Util.makePart
local GROUND_Y = 1
local ICE_COLOR = Color3.fromRGB(150, 220, 255)

---------------------------------------------------------------- path math
local waypoints = {}
for i, p in Config.Path do
	waypoints[i] = Vector3.new(p.X, GROUND_Y, p.Z)
end
local cumulative = { 0 }
for i = 2, #waypoints do
	cumulative[i] = cumulative[i - 1] + (waypoints[i] - waypoints[i - 1]).Magnitude
end
local pathLength = cumulative[#waypoints]

-- Position and facing direction at distance d along the path.
local function pointAt(d)
	for i = 2, #waypoints do
		if d <= cumulative[i] then
			local a, b = waypoints[i - 1], waypoints[i]
			local t = (d - cumulative[i - 1]) / (cumulative[i] - cumulative[i - 1])
			return a:Lerp(b, t), (b - a).Unit
		end
	end
	local n = #waypoints
	return waypoints[n], (waypoints[n] - waypoints[n - 1]).Unit
end

local function distanceToPath(pos)
	local p = Vector3.new(pos.X, 0, pos.Z)
	local best = math.huge
	for i = 1, #waypoints - 1 do
		local a = Vector3.new(waypoints[i].X, 0, waypoints[i].Z)
		local b = Vector3.new(waypoints[i + 1].X, 0, waypoints[i + 1].Z)
		local ab = b - a
		local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
		best = math.min(best, (p - (a + ab * t)).Magnitude)
	end
	return best
end

---------------------------------------------------------------- world
local mapInfo = MapBuilder.build(waypoints, distanceToPath, GROUND_Y)
local bounds, baseCenter = mapInfo.bounds, mapInfo.baseCenter

local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
if spawnLoc then
	spawnLoc.Position = Vector3.new(0, 0.5, 82)
end

local enemiesFolder = Util.makeFolder("Enemies", workspace)
local towersFolder = Util.makeFolder("Towers", workspace)

---------------------------------------------------------------- game state
local state = Util.makeFolder("GameState", ReplicatedStorage)
local function setState(key, value)
	state:SetAttribute(key, value)
end

local lives = Config.StartingLives
local currentWave = 0
local difficulty = Config.GetDifficulty("Normal") -- replaced by the party's pick once players arrive
local expectedPlayers = 1
local enemies = {} -- array of enemy records
local towers = {} -- id -> tower record
local nextTowerId = 0

local function getCash(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Cash")
end

-- Gives in-match cash to everyone (scaled by difficulty). Returns the amount given.
local function giveAll(amount)
	amount = math.floor(amount * difficulty.CashMult + 0.5)
	for _, p in Players:GetPlayers() do
		local c = getCash(p)
		if c then c.Value += amount end
	end
	return amount
end

local function setupPlayer(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.StartingCash
	cash.Parent = ls
	ls.Parent = player
end
Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do
	setupPlayer(p)
end

---------------------------------------------------------------- enemies
local function makeHealthBar(body, def, top)
	local bb = Instance.new("BillboardGui")
	bb.Size = if def.IsBoss then UDim2.fromOffset(200, 50) else UDim2.fromOffset(120, 34)
	bb.StudsOffset = Vector3.new(0, top + 1.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 150
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.fromScale(1, 0.55)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = def.DisplayName
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextColor3 = if def.IsBoss then Color3.fromRGB(255, 220, 60) else Color3.new(1, 1, 1)
	nameLbl.TextStrokeTransparency = 0
	nameLbl.Parent = bb
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromScale(0.1, 0.65)
	barBack.Size = UDim2.fromScale(0.8, 0.3)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
	barBack.BorderSizePixel = 0
	barBack.Parent = bb
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
	fill.BorderSizePixel = 0
	fill.Parent = barBack
	bb.Parent = body
	return fill
end

local function spawnEnemy(kind)
	local def = Config.Enemies[kind]
	local halfHeight = (if def.Shape == "Ball" then def.Size.X else def.Size.Y) / 2
	local height = halfHeight + 0.1 + (if def.Flying then Config.FlyingHeight else 0)
	local pos, dir = pointAt(0)
	local cf = CFrame.lookAt(pos, pos + dir) + Vector3.new(0, height, 0)

	local model, body, top = EnemyLooks.build(def, cf)
	local fill = makeHealthBar(body, def, top)
	model.Parent = enemiesFolder

	local maxHp = math.floor(def.Health * Config.HealthScale(math.max(currentWave, 1)) * difficulty.HealthMult + 0.5)
	table.insert(enemies, {
		model = model, body = body, def = def, fill = fill, height = height, speed = def.Speed * difficulty.SpeedMult,
		hp = maxHp, maxHp = maxHp, d = 0, alive = true, seed = math.random() * 10,
		slowUntil = 0, slowMult = 1, tinted = false,
	})
	if def.IsBoss then
		Effects.sound("WaveStart", nil, 0.6, true)
	end
end

local function damageEnemy(e, amount)
	if not e.alive then return end
	e.hp -= math.max(1, amount - (e.def.Armor or 0))
	e.fill.Size = UDim2.fromScale(math.max(e.hp, 0) / e.maxHp, 1)
	if e.hp <= 0 then
		e.alive = false
		local pos = e.body.Position
		local reward = giveAll(e.def.Reward)
		Effects.pop(pos, e.def.Color, e.def.Size.X)
		Effects.confetti(pos, if e.def.IsBoss then 80 else 15)
		Effects.floatText(pos, "+$" .. reward, Color3.fromRGB(120, 255, 120))
		if e.def.IsBoss then
			Effects.sound("Explosion", pos, 0.7, true)
		else
			Effects.sound("Pop", pos, 0.9 + math.random() * 0.4)
		end
		e.model:Destroy()
	end
end

local function slowEnemy(e, mult, duration)
	local now = os.clock()
	if now >= e.slowUntil then
		e.slowMult = mult
	else
		e.slowMult = math.min(e.slowMult, mult)
	end
	e.slowUntil = math.max(e.slowUntil, now + duration)
end

---------------------------------------------------------------- towers
local function towerStats(tw)
	return tw.def.Levels[tw.level]
end

local function buildTowerVisual(tw)
	local model, def, lvl, flat = tw.model, tw.def, tw.level, tw.pos
	model:ClearAllChildren()

	local baseSize = 4 + lvl * 0.5
	local baseCf = CFrame.new(flat + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local towerBase = makePart({
		Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, baseSize, baseSize), CFrame = baseCf,
		Color = Color3.fromRGB(70, 70, 80), Material = Enum.Material.Metal,
	}, model)
	local pillarH = 1 + lvl
	makePart({
		Name = "Pillar", Size = Vector3.new(1.2, pillarH, 1.2), Position = flat + Vector3.new(0, 2 + pillarH / 2, 0),
		Color = Color3.fromRGB(100, 100, 110), Material = Enum.Material.Metal,
	}, model)

	local headSize = 2.2 + lvl * 0.4
	local headPos = flat + Vector3.new(0, 2 + pillarH + headSize / 2, 0)
	local headProps = { Name = "Head", Color = def.Color, Material = Enum.Material.Neon }
	if def.HeadShape == "Cylinder" then
		headProps.Shape = Enum.PartType.Cylinder
		headProps.Size = Vector3.new(headSize * 0.7, headSize, headSize)
		headProps.CFrame = CFrame.new(headPos) * CFrame.Angles(0, 0, math.rad(90))
	elseif def.HeadShape == "Block" then
		headProps.Size = Vector3.one * headSize
		headProps.Position = headPos
	else
		headProps.Shape = Enum.PartType.Ball
		headProps.Size = Vector3.one * headSize
		headProps.Position = headPos
	end
	local head = makePart(headProps, model)

	Util.billboardText(head, string.rep("★", lvl), UDim2.fromOffset(60, 20), Vector3.new(0, headSize / 2 + 0.8, 0),
		Color3.fromRGB(255, 220, 80))

	model.PrimaryPart = towerBase
	model:SetAttribute("Level", lvl)
	tw.muzzle = headPos
end

local function placeTower(player, kind, pos)
	if typeof(kind) ~= "string" or not RateLimit.validVector(pos) or math.abs(pos.Y - GROUND_Y) > 3 then
		return false, "Invalid placement"
	end
	local def = Config.Towers[kind]
	if not def then return false, "Unknown tower" end
	local data = DataService.get(player)
	if not (data and data.Towers[kind]) then
		return false, "Unlock this tower in the lobby shop first!"
	end
	local cost = def.Levels[1].Cost
	local cash = getCash(player)
	if not cash or cash.Value < cost then
		return false, "Not enough cash!"
	end
	local rel = bounds.CFrame:PointToObjectSpace(pos)
	if math.abs(rel.X) > bounds.Size.X / 2 - 2 or math.abs(rel.Z) > bounds.Size.Z / 2 - 2 then
		return false, "Place it on the grass!"
	end
	if distanceToPath(pos) < Config.PathWidth / 2 + 2 then
		return false, "Too close to the path!"
	end
	local flat = Vector3.new(pos.X, GROUND_Y, pos.Z)
	if (flat - baseCenter).Magnitude < 11 then
		return false, "Too close to the base!"
	end
	for _, b in mapInfo.blockers do
		if (b.pos - flat).Magnitude < b.radius + 2 then
			return false, "Something's in the way!"
		end
	end
	for _, tw in towers do
		if (tw.pos - flat).Magnitude < 5 then
			return false, "Too close to another tower!"
		end
	end

	cash.Value -= cost
	nextTowerId += 1
	local model = Instance.new("Model")
	model.Name = def.DisplayName
	model:SetAttribute("Id", nextTowerId)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("Targeting", Config.TargetModes[1])
	local tw = {
		id = nextTowerId, model = model, kind = kind, def = def, level = 1,
		ownerId = player.UserId, pos = flat, cooldown = 0, targetIndex = 1,
	}
	buildTowerVisual(tw)
	model.Parent = towersFolder
	towers[tw.id] = tw
	Effects.pop(flat + Vector3.new(0, 2, 0), def.Color, 3)
	Effects.sound("Pop", flat, 0.7, true)
	return true, "Placed " .. def.DisplayName .. "!"
end

local function towerAction(player, action, id)
	local tw = towers[id]
	if not tw then return false, "Tower not found" end
	if tw.ownerId ~= player.UserId then return false, "That's not your tower!" end
	local cash = getCash(player)
	if not cash then return false, "No cash" end

	if action == "Upgrade" then
		local nextLevel = tw.def.Levels[tw.level + 1]
		if not nextLevel then return false, "Already max level!" end
		if cash.Value < nextLevel.Cost then return false, "Not enough cash!" end
		cash.Value -= nextLevel.Cost
		tw.level += 1
		buildTowerVisual(tw)
		Effects.pop(tw.muzzle, tw.def.Color, 3)
		Effects.confetti(tw.muzzle, 25)
		Effects.sound("Pop", tw.muzzle, 1.4, true)
		return true, tw.def.DisplayName .. " upgraded to level " .. tw.level .. "!"
	elseif action == "Sell" then
		local value = Config.SellValue(tw.kind, tw.level)
		cash.Value += value
		towers[id] = nil
		Effects.floatText(tw.muzzle, "+$" .. value, Color3.fromRGB(255, 220, 60))
		tw.model:Destroy()
		return true, "Sold for $" .. value
	elseif action == "Target" then
		tw.targetIndex = tw.targetIndex % #Config.TargetModes + 1
		tw.model:SetAttribute("Targeting", Config.TargetModes[tw.targetIndex])
		return true, "Targeting: " .. Config.TargetModes[tw.targetIndex]
	end
	return false, "Unknown action"
end

local function makeRemote(name, handler)
	local old = ReplicatedStorage:FindFirstChild(name)
	if old then old:Destroy() end
	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.OnServerInvoke = RateLimit.wrap(handler, 6, 1) -- max 6 calls/second per player
	r.Parent = ReplicatedStorage
end
makeRemote("PlaceTower", placeTower)
makeRemote("TowerAction", towerAction)

local function findTarget(tw, s)
	local mode = Config.TargetModes[tw.targetIndex]
	local r2 = s.Range * s.Range
	local best, bestScore = nil, -math.huge
	for _, e in enemies do
		if e.alive and (tw.def.HitsFlying or not e.def.Flying) then
			local p = e.body.Position
			local dx, dz = p.X - tw.pos.X, p.Z - tw.pos.Z
			local dist2 = dx * dx + dz * dz
			if dist2 <= r2 then
				local score
				if mode == "First" then
					score = e.d
				elseif mode == "Last" then
					score = -e.d
				elseif mode == "Strongest" then
					score = e.hp
				else
					score = -dist2
				end
				if score > bestScore then
					best, bestScore = e, score
				end
			end
		end
	end
	return best
end

local function shoot(tw, s, e)
	local to = e.body.Position
	Effects.sound(tw.def.Sound or "Laser", tw.muzzle, tw.def.Pitch)
	if s.Splash then
		Effects.lob(tw.muzzle, to, tw.def.Color)
		Effects.pop(to, tw.def.Color, s.Splash * 0.6)
		for _, other in enemies do
			if other.alive and not other.def.Flying and (other.body.Position - to).Magnitude <= s.Splash then
				damageEnemy(other, s.Damage)
			end
		end
	else
		Effects.beam(tw.muzzle, to, tw.def.Color, if s.Range >= 40 then 0.6 else 0.3)
		if s.Slow then
			slowEnemy(e, s.Slow, s.SlowTime)
		end
		damageEnemy(e, s.Damage)
	end
end

---------------------------------------------------------------- main update
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for i = #enemies, 1, -1 do
		local e = enemies[i]
		if e.alive then
			local slowed = t < e.slowUntil
			e.d += e.speed * (if slowed then e.slowMult else 1) * dt
			if slowed ~= e.tinted then
				e.tinted = slowed
				e.body.Color = if slowed then e.def.Color:Lerp(ICE_COLOR, 0.6) else e.def.Color
			end
			if e.d >= pathLength then
				e.alive = false
				Effects.pop(e.body.Position, Color3.fromRGB(255, 50, 50), e.def.Size.X)
				Effects.sound("BaseHit", baseCenter, 1, true)
				Effects.flash(mapInfo.basePart, Color3.fromRGB(255, 60, 60), 0.2)
				Effects.floatText(baseCenter + Vector3.new(0, 10, 0), "-" .. e.def.Damage .. " lives", Color3.fromRGB(255, 80, 80))
				e.model:Destroy()
				lives = math.max(0, lives - e.def.Damage)
				setState("Lives", lives)
			else
				local pos, dir = pointAt(e.d)
				local bob = math.abs(math.sin(t * 8 + e.seed)) * 0.6
				e.body.CFrame = CFrame.lookAt(pos, pos + dir) + Vector3.new(0, e.height + bob, 0)
			end
		end
		if not e.alive then
			table.remove(enemies, i)
		end
	end

	for _, tw in towers do
		tw.cooldown -= dt
		if tw.cooldown <= 0 then
			local s = towerStats(tw)
			local target = findTarget(tw, s)
			if target then
				tw.cooldown = s.Cooldown
				shoot(tw, s, target)
			end
		end
	end
end)

---------------------------------------------------------------- wave loop
local function resetGame()
	for _, e in enemies do
		e.alive = false
		e.model:Destroy()
	end
	table.clear(enemies)
	for _, tw in towers do
		tw.model:Destroy()
	end
	table.clear(towers)
	for _, p in Players:GetPlayers() do
		local c = getCash(p)
		if c then c.Value = Config.StartingCash end
	end
	lives = difficulty.Lives
	currentWave = 0
	setState("Lives", lives)
	setState("Wave", 0)
	setState("MaxWave", difficulty.Waves)
	setState("Difficulty", difficulty.Id)
end

local function countdown(seconds, format)
	for s = seconds, 1, -1 do
		setState("Status", string.format(format, s))
		task.wait(1)
	end
end

local function waveHasBoss(w)
	for _, group in Config.Waves[w] do
		local def = Config.Enemies[group[1]]
		if def and def.IsBoss then return true end
	end
	return false
end

local function runWave(w)
	currentWave = w
	setState("Wave", w)
	setState("Status", if waveHasBoss(w) then "BOSS WAVE " .. w .. "! Brace yourself!" else "Wave " .. w .. " incoming!")
	Effects.sound("WaveStart", nil, 1, true)
	local doneSpawning = false
	task.spawn(function()
		for _, group in Config.Waves[w] do
			local kind, count, spacing = group[1], group[2], group[3]
			for _ = 1, count do
				if lives <= 0 then break end
				spawnEnemy(kind)
				task.wait(spacing)
			end
		end
		doneSpawning = true
	end)
	while (not doneSpawning or #enemies > 0) and lives > 0 do
		task.wait(0.25)
	end
	return lives > 0
end

---------------------------------------------------------------- match flow
-- The lobby sends { Difficulty = "Hard", PartySize = 3 } as teleport data.
-- In Studio there is none: set a "TestDifficulty" attribute on Workspace to test other difficulties.
local function chooseDifficulty()
	for _, p in Players:GetPlayers() do
		local joinData = p:GetJoinData()
		local td = joinData and joinData.TeleportData
		if typeof(td) == "table" and td.Difficulty then
			difficulty = Config.GetDifficulty(td.Difficulty)
			expectedPlayers = math.clamp(tonumber(td.PartySize) or 1, 1, Config.MaxPartySize)
			return
		end
	end
	difficulty = Config.GetDifficulty(workspace:GetAttribute("TestDifficulty") or "Normal")
end

local function coinsFor(wavesCleared, won)
	local base = wavesCleared * Config.CoinsPerWave + (if won then Config.WinBonusCoins else 0)
	return math.floor(base * difficulty.CoinMult)
end

local function awardPlayers(wavesCleared, won)
	local coins = coinsFor(wavesCleared, won)
	for _, p in Players:GetPlayers() do
		DataService.update(p, function(data)
			data.Coins += coins
			data.GamesPlayed += 1
			if won then
				data.Wins += 1
				data.Beaten[difficulty.Id] = true
			end
			data.BestWave[difficulty.Id] = math.max(data.BestWave[difficulty.Id] or 0, wavesCleared)
		end)
		task.spawn(DataService.save, p)
	end
	return coins
end

-- Returns true if players were sent back to the lobby (live servers only).
local function returnToLobby()
	local lobbyId = Config.PlaceIds.Lobby
	if RunService:IsStudio() or lobbyId == 0 or game.PlaceId == lobbyId then
		return false
	end
	local players = Players:GetPlayers()
	for _, p in players do
		DataService.save(p, true) -- release the lock so the lobby can load it
	end
	if #players == 0 then return true end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(lobbyId, players)
	end)
	if not ok then
		warn("Teleport to lobby failed: " .. tostring(err))
	end
	return ok
end

-- Wait for the party to arrive (up to 20s) before starting.
while #Players:GetPlayers() == 0 do
	task.wait(0.5)
end
chooseDifficulty()
local waitStart = os.clock()
while #Players:GetPlayers() < expectedPlayers and os.clock() - waitStart < 20 do
	setState("Status", "Waiting for your party...")
	task.wait(0.5)
end

while true do
	resetGame()
	while #Players:GetPlayers() == 0 do
		task.wait(1)
	end
	countdown(Config.FirstIntermission, "[" .. difficulty.DisplayName .. "] Place your towers! Wave 1 in %d")
	local won, cleared = true, 0
	for w = 1, difficulty.Waves do
		if not runWave(w) then
			won = false
			break
		end
		cleared = w
		if w < difficulty.Waves then
			local bonus = giveAll(Config.WaveBonus(w))
			countdown(Config.Intermission, "Wave cleared! +$" .. bonus .. " - next wave in %d")
		end
	end
	local coins = awardPlayers(cleared, won)
	if won then
		setState("Status", "YOU WIN! +" .. coins .. " " .. Config.CurrencyName)
		Effects.confetti(baseCenter + Vector3.new(0, 12, 0), 200)
	else
		setState("Status", "GAME OVER! You survived " .. cleared .. " waves. +" .. coins .. " " .. Config.CurrencyName)
	end
	task.wait(10)
	if returnToLobby() then
		setState("Status", "Returning to lobby...")
		break
	end
end
