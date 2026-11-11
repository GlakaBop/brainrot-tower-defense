-- Per-player rate limiting for RemoteFunction handlers.
-- Usage: remote.OnServerInvoke = RateLimit.wrap(handler, 5, 1) -- max 5 calls per 1 second
local Players = game:GetService("Players")

local RateLimit = {}

function RateLimit.wrap(handler, maxCalls, window)
	local calls = {}
	Players.PlayerRemoving:Connect(function(p)
		calls[p] = nil
	end)
	return function(player, ...)
		local now = os.clock()
		local list = calls[player]
		if not list then
			list = {}
			calls[player] = list
		end
		while list[1] and now - list[1] > window do
			table.remove(list, 1)
		end
		if #list >= maxCalls then
			return false, "Slow down!"
		end
		table.insert(list, now)
		return handler(player, ...)
	end
end

-- True for a real, finite Vector3 (rejects NaN / infinity exploits).
function RateLimit.validVector(v)
	if typeof(v) ~= "Vector3" then return false end
	for _, n in { v.X, v.Y, v.Z } do
		if n ~= n or n == math.huge or n == -math.huge then return false end
	end
	return true
end

return RateLimit
