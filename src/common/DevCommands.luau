-- Studio-only chat commands for testing. They do nothing in live servers.
--   /coins 1000   -> add coins
--   /resetdata    -> back to a fresh save (starter towers, 0 coins, no pity)
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local DevCommands = {}

local function addCommand(name, alias, handler)
	local folder = TextChatService:FindFirstChild("DevCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DevCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = name
	cmd.PrimaryAlias = alias
	cmd.Parent = folder
	cmd.Triggered:Connect(function(source, text)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then handler(player, text) end
	end)
end

function DevCommands.start()
	if not RunService:IsStudio() then return end

	addCommand("DevCoins", "/coins", function(player, text)
		local amount = tonumber(string.match(text, "%d+")) or 1000
		DataService.update(player, function(d)
			d.Coins += amount
		end)
		print(string.format("[Dev] Gave %s %d %s", player.Name, amount, Config.CurrencyName))
	end)

	addCommand("DevReset", "/resetdata", function(player)
		DataService.update(player, function(d)
			d.Coins = 0
			d.Towers = {}
			for _, kind in Config.StarterTowers do
				d.Towers[kind] = true
			end
			d.Beaten = {}
			d.BestWave = {}
			d.Pity = 0
			d.CratesOpened = 0
		end)
		print("[Dev] Reset data for " .. player.Name)
	end)

	print("[Dev] Studio commands ready: /coins <amount>, /resetdata")
end

return DevCommands
