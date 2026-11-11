-- Shows "Lv 12" over every player's head (reads the Level attribute set by DataService).
local Players = game:GetService("Players")

local LevelTags = {}

local function attach(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head then return end
	local old = head:FindFirstChild("LevelTag")
	if old then old:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "LevelTag"
	bb.Size = UDim2.fromOffset(90, 26)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 20, 38)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.fromRGB(255, 205, 70)
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
	label.TextSize = 16
	label.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = label
	bb.Parent = head

	local function update()
		label.Text = "Lv " .. (player:GetAttribute("Level") or 1)
	end
	update()
	local conn = player:GetAttributeChangedSignal("Level"):Connect(update)
	bb.Destroying:Once(function() conn:Disconnect() end)
end

function LevelTags.start()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char) attach(player, char) end)
		if player.Character then task.spawn(attach, player, player.Character) end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do onPlayer(p) end
end

return LevelTags
