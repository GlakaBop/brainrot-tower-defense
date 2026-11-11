-- Global leaderboards (OrderedDataStores) for Most Wins and Highest Level.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Leaderboards = {}

Leaderboards.Boards = {
	{ Id = "Wins", Title = "MOST WINS", Store = "LB_Wins_v1", Value = function(d) return d.Wins end },
	{ Id = "Level", Title = "HIGHEST LEVEL", Store = "LB_Level_v1", Value = function(d) return d.Level end },
}

local stores = {}
local lastSubmitted = {} -- userId..board -> value (skip writes when nothing changed)

local function getStore(board)
	if stores[board.Id] == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore(board.Store)
		end)
		stores[board.Id] = if ok then s else false
	end
	return stores[board.Id] or nil
end

-- Called after every successful save. Only writes when the value changed.
function Leaderboards.submit(userId, data)
	for _, board in Leaderboards.Boards do
		local value = math.floor(board.Value(data) or 0)
		local key = userId .. board.Id
		local store = getStore(board)
		if store and value > 0 and lastSubmitted[key] ~= value then
			lastSubmitted[key] = value
			task.spawn(function()
				local ok, err = pcall(function()
					store:SetAsync(tostring(userId), value)
				end)
				if not ok then
					lastSubmitted[key] = nil
					warn("[Leaderboards] submit failed: " .. tostring(err))
				end
			end)
		end
	end
end

local nameCache = {}
local function nameFor(userId)
	if nameCache[userId] then return nameCache[userId] end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = if ok then name else ("Player " .. userId)
	return nameCache[userId]
end

-- Returns { {Rank, Name, Value} } for the top `count` entries, or nil if unavailable.
function Leaderboards.fetch(boardId, count)
	local board
	for _, b in Leaderboards.Boards do
		if b.Id == boardId then board = b end
	end
	local store = board and getStore(board)
	if not store then return nil end
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, count or 10)
	end)
	if not ok then
		warn("[Leaderboards] fetch failed: " .. tostring(pages))
		return nil
	end
	local rows = {}
	for rank, entry in pages:GetCurrentPage() do
		table.insert(rows, { Rank = rank, Name = nameFor(tonumber(entry.key)), Value = entry.value })
	end
	return rows
end

return Leaderboards
