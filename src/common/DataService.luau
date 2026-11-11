-- Saved player progress, shared by the lobby and match places.
-- Mirrors the important bits onto player attributes so clients can display them:
--   Coins (number), OwnedTowers ("A,B,C"), BeatenDifficulties ("Easy,Normal")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 60

local storeOk, store = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if not storeOk then
	warn("[DataService] DataStores unavailable - progress will NOT save. In Studio, enable Game Settings > Security > API Services.")
	store = nil
end

local DataService = {}
local profiles = {} -- player -> { data = table, canSave = bool }

local function defaultData()
	local towers = {}
	for _, kind in Config.StarterTowers do
		towers[kind] = true
	end
	return {
		Coins = 0,
		Towers = towers,
		Beaten = {}, -- difficultyId -> true
		BestWave = {}, -- difficultyId -> number
		Wins = 0,
		GamesPlayed = 0,
		Pity = 0, -- crates opened since the last Legendary+
		CratesOpened = 0,
	}
end

local function reconcile(data)
	local template = defaultData()
	for k, v in template do
		if data[k] == nil then data[k] = v end
	end
	for _, kind in Config.StarterTowers do
		data.Towers[kind] = true
	end
	return data
end

local function keyFor(player)
	return "player_" .. player.UserId
end

local function setsToString(set)
	local list = {}
	for k, v in set do
		if v then table.insert(list, k) end
	end
	table.sort(list)
	return table.concat(list, ",")
end

local function syncAttributes(player, data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("OwnedTowers", setsToString(data.Towers))
	player:SetAttribute("BeatenDifficulties", setsToString(data.Beaten))
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Pity", data.Pity)
end

-- Session lock: while a server has a player's data loaded, it stamps { job, time } on the save.
-- Other servers (e.g. the match place during a teleport) wait for the lock to be released
-- so an older copy can never overwrite newer progress.
local LOCK_STALE = 180 -- seconds; a lock older than this is from a crashed server
local LOAD_ATTEMPTS = 12 -- x 3s = wait up to ~36s for another server to release

local function lockedByOther(saved)
	local lock = saved and saved.__lock
	return lock ~= nil and lock.job ~= game.JobId and os.time() - (lock.time or 0) < LOCK_STALE
end

function DataService.load(player)
	local data, canSave = nil, false
	if store then
		for attempt = 1, LOAD_ATTEMPTS do
			local blocked = false
			local force = attempt == LOAD_ATTEMPTS -- last resort: take over the lock
			local ok, err = pcall(function()
				store:UpdateAsync(keyFor(player), function(saved)
					if lockedByOther(saved) and not force then
						blocked = true
						return nil -- don't write; try again shortly
					end
					saved = saved or defaultData()
					saved.__lock = { job = game.JobId, time = os.time() }
					data = saved
					return saved
				end)
			end)
			if ok and not blocked then
				canSave = true
				break
			end
			if not ok then
				warn("[DataService] load failed (attempt " .. attempt .. "): " .. tostring(err))
				if attempt >= 3 then break end -- DataStores are down/disabled: play offline
			end
			if not player.Parent then return nil end
			task.wait(if blocked then 3 else 1)
		end
	end
	data = reconcile(data or defaultData())
	profiles[player] = { data = data, canSave = canSave }
	syncAttributes(player, data)
	player:SetAttribute("DataLoaded", true)
	if not player.Parent then
		DataService.release(player) -- left while loading: free the lock right away
	end
	return data
end

function DataService.get(player)
	local p = profiles[player]
	return p and p.data
end

-- Mutate a player's data: DataService.update(player, function(data) data.Coins += 10 end)
function DataService.update(player, fn)
	local p = profiles[player]
	if not p then return false end
	fn(p.data)
	syncAttributes(player, p.data)
	return true
end

-- Saves the player's data. With release = true, also frees the session lock
-- (do this right before teleporting a player or when they leave).
function DataService.save(player, release)
	local p = profiles[player]
	if not (p and p.canSave and store) then return false end
	local stolen = false
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(saved)
			if lockedByOther(saved) then
				stolen = true
				return nil -- another server owns this data now; never overwrite it
			end
			p.data.__lock = if release then nil else { job = game.JobId, time = os.time() }
			return p.data
		end)
	end)
	if not ok then
		warn("[DataService] save failed: " .. tostring(err))
	elseif stolen then
		warn("[DataService] save skipped for " .. player.Name .. ": data is locked by another server")
		p.canSave = false
	end
	return ok and not stolen
end

function DataService.release(player)
	DataService.save(player, true)
	profiles[player] = nil
end

function DataService.start()
	Players.PlayerAdded:Connect(DataService.load)
	for _, p in Players:GetPlayers() do
		task.spawn(DataService.load, p)
	end
	Players.PlayerRemoving:Connect(DataService.release)
	game:BindToClose(function()
		for player in profiles do
			task.spawn(DataService.save, player, true)
		end
		task.wait(3)
	end)
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.save, player)
			end
		end
	end)
end

function DataService.waitForData(player)
	while player.Parent and not profiles[player] do
		task.wait(0.1)
	end
	return DataService.get(player)
end

return DataService
