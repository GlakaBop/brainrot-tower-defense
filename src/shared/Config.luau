-- Brainrot Tower Defense: all tunable game data lives here.
-- Names, colors and stats are placeholders - rename/retune freely.
local Config = {}

-- Places in this experience.
Config.PlaceIds = {
	Lobby = 101377258170674,
	Match = 123125275296479,
}

-- Meta-progression currency earned per match, spent in the lobby shop.
Config.CurrencyName = "Coins"
Config.CoinsPerWave = 5
Config.WinBonusCoins = 100
Config.MaxPartySize = 4

-- Player levels. XP earned per match is multiplied by the difficulty's CoinMult.
Config.Progression = {
	XPPerKill = 1,
	XPPerBossKill = 25,
	XPPerWave = 10,
	XPWinBonus = 100,
	MaxLevel = 100,
	CoinsPerLevel = 25,
	BasicCrateEvery = 5, -- free Basic Crate every 5 levels
	BrainrotCrateEvery = 10, -- free Brainrot Crate every 10 levels (instead of the Basic one)
}

-- XP needed to go from `level` to `level + 1`.
function Config.XPForLevel(level: number): number
	return 100 + (level - 1) * 50
end

-- What you get for reaching `level`: { Coins = n, Crate = "Basic"/"Brainrot"/nil }
function Config.LevelReward(level: number)
	local p = Config.Progression
	local crate = nil
	if level % p.BrainrotCrateEvery == 0 then
		crate = "Brainrot"
	elseif level % p.BasicCrateEvery == 0 then
		crate = "Basic"
	end
	return { Coins = p.CoinsPerLevel, Crate = crate }
end

-- Difficulties, in unlock order. Requires = difficulty you must win first.
Config.Difficulties = {
	{
		Id = "Easy", DisplayName = "Easy", Color = Color3.fromRGB(110, 235, 130),
		HealthMult = 0.75, SpeedMult = 0.9, CashMult = 1.25, Lives = 30, Waves = 15, CoinMult = 0.6,
	},
	{
		Id = "Normal", DisplayName = "Normal", Color = Color3.fromRGB(90, 160, 255),
		HealthMult = 1, SpeedMult = 1, CashMult = 1, Lives = 20, Waves = 20, CoinMult = 1,
	},
	{
		Id = "Hard", DisplayName = "Hard", Color = Color3.fromRGB(255, 150, 60), Requires = "Normal",
		HealthMult = 1.5, SpeedMult = 1.1, CashMult = 0.9, Lives = 10, Waves = 20, CoinMult = 1.75,
	},
	{
		Id = "Brainrot", DisplayName = "BRAINROT", Color = Color3.fromRGB(255, 60, 200), Requires = "Hard",
		HealthMult = 2.2, SpeedMult = 1.25, CashMult = 0.8, Lives = 5, Waves = 20, CoinMult = 3,
	},
}

function Config.GetDifficulty(id: string?)
	for _, d in Config.Difficulties do
		if d.Id == id then return d end
	end
	return Config.Difficulties[2] -- Normal
end

-- Towers everyone owns from the start; the rest come from crates.
Config.StarterTowers = { "RizzBlaster" }

-- Rarities, lowest to highest. Each tower has a Rarity. Refund = coins for a duplicate.
Config.Rarities = {
	{ Id = "Common", Color = Color3.fromRGB(190, 190, 200), Refund = 15 },
	{ Id = "Rare", Color = Color3.fromRGB(80, 160, 255), Refund = 40 },
	{ Id = "Epic", Color = Color3.fromRGB(180, 90, 255), Refund = 100 },
	{ Id = "Legendary", Color = Color3.fromRGB(255, 190, 40), Refund = 250 },
	{ Id = "Mythic", Color = Color3.fromRGB(255, 60, 120), Refund = 600 },
}

function Config.GetRarity(id: string)
	for i, r in Config.Rarities do
		if r.Id == id then return r, i end
	end
	return Config.Rarities[1], 1
end

-- Crates. Weights are relative chances per rarity (rarities with no towers are skipped automatically).
Config.Crates = {
	{
		Id = "Basic", DisplayName = "Basic Crate", Price = 100, Color = Color3.fromRGB(90, 160, 255),
		Weights = { Common = 35, Rare = 45, Epic = 15, Legendary = 4, Mythic = 1 },
	},
	{
		Id = "Brainrot", DisplayName = "Brainrot Crate", Price = 350, Color = Color3.fromRGB(255, 60, 200),
		Weights = { Common = 0, Rare = 50, Epic = 32, Legendary = 14, Mythic = 4 },
	},
}

-- Pity: after this many crates in a row without Legendary or better, the next one is guaranteed Legendary+.
Config.PityThreshold = 30

function Config.GetCrate(id: string)
	for _, c in Config.Crates do
		if c.Id == id then return c end
	end
	return nil
end

-- Real chance (0-1) of each rarity from a crate, after skipping rarities that have no towers.
function Config.CrateOdds(crate)
	local hasTower = {}
	for _, def in Config.Towers do
		hasTower[def.Rarity or "Common"] = true
	end
	local total = 0
	for _, r in Config.Rarities do
		if hasTower[r.Id] then total += crate.Weights[r.Id] or 0 end
	end
	local odds = {}
	for _, r in Config.Rarities do
		odds[r.Id] = if hasTower[r.Id] and total > 0 then (crate.Weights[r.Id] or 0) / total else 0
	end
	return odds
end

function Config.TowersOfRarity(rarityId: string)
	local list = {}
	for _, kind in Config.TowerOrder do
		if (Config.Towers[kind].Rarity or "Common") == rarityId then table.insert(list, kind) end
	end
	return list
end

Config.StartingCash = 250
Config.StartingLives = 20
Config.FirstIntermission = 15 -- seconds before wave 1
Config.Intermission = 6 -- seconds between waves
Config.PathWidth = 8
Config.SellRefund = 0.6 -- fraction of total spent returned when selling
Config.FlyingHeight = 6
Config.TargetModes = { "First", "Last", "Strongest", "Closest" }

-- Free Creator Store sounds. Swap any ID to change a sound; set to "" to mute it.
Config.Sounds = {
	Laser = { Id = "rbxassetid://115842676995967", Volume = 0.35 },
	Pop = { Id = "rbxassetid://106984966606682", Volume = 0.6 },
	Explosion = { Id = "rbxassetid://138533090376585", Volume = 0.35 },
	WaveStart = { Id = "rbxassetid://132844961288199", Volume = 0.5 },
	BaseHit = { Id = "rbxassetid://74283879394082", Volume = 0.7 },
}

-- Enemy path (X/Z only; Y is the ground height). First point = spawn, last = base.
-- Maps. The field is 200 x 140 studs (X from -100 to 100, Z from -70 to 70).
-- Path: enemy route (X/Z only), first point = spawn portal, last point = your base.
-- Theme: colors, lighting and which decorations to scatter (see MapBuilder for decor types).
Config.Maps = {
	{
		Id = "Meadow", DisplayName = "Brainrot Meadow", CoinMult = 1, Color = Color3.fromRGB(120, 210, 90),
		Path = {
			Vector3.new(-92, 0, -50), Vector3.new(-50, 0, -50), Vector3.new(-50, 0, 30), Vector3.new(-10, 0, 30),
			Vector3.new(-10, 0, -40), Vector3.new(35, 0, -40), Vector3.new(35, 0, 45), Vector3.new(88, 0, 45),
		},
		Theme = {
			TileA = Color3.fromRGB(120, 210, 90), TileB = Color3.fromRGB(100, 190, 75), Cliff = Color3.fromRGB(120, 80, 60),
			Path = Color3.fromRGB(235, 205, 150), CurbA = Color3.fromRGB(255, 120, 220), CurbB = Color3.fromRGB(150, 110, 255),
			ClockTime = 15, Ambient = Color3.fromRGB(90, 70, 110), OutdoorAmbient = Color3.fromRGB(150, 130, 170),
			AtmoColor = Color3.fromRGB(255, 200, 240), AtmoDecay = Color3.fromRGB(120, 80, 200), AtmoDensity = 0.25,
			Decor = { "Mushroom", "CandyTree", "FloatingBrain", "Lollipop", "Rock", "CandyTree", "Mushroom" },
		},
	},
	{
		Id = "Swamp", DisplayName = "Spooky Swamp", CoinMult = 1, Color = Color3.fromRGB(120, 200, 120),
		Path = {
			Vector3.new(-92, 0, -50), Vector3.new(70, 0, -50), Vector3.new(70, 0, -10),
			Vector3.new(-70, 0, -10), Vector3.new(-70, 0, 30), Vector3.new(88, 0, 30),
		},
		Theme = {
			TileA = Color3.fromRGB(60, 85, 60), TileB = Color3.fromRGB(50, 72, 55), Cliff = Color3.fromRGB(45, 35, 40),
			Path = Color3.fromRGB(95, 75, 60), CurbA = Color3.fromRGB(120, 255, 120), CurbB = Color3.fromRGB(180, 90, 255),
			ClockTime = 19.2, Ambient = Color3.fromRGB(70, 60, 100), OutdoorAmbient = Color3.fromRGB(90, 90, 130),
			AtmoColor = Color3.fromRGB(150, 200, 160), AtmoDecay = Color3.fromRGB(60, 40, 90), AtmoDensity = 0.4,
			Decor = { "DeadTree", "GlowShroom", "Rock", "FloatingBrain", "DeadTree", "GlowShroom" },
		},
	},
	{
		Id = "Lava", DisplayName = "Lava Land", CoinMult = 1.25, Color = Color3.fromRGB(255, 120, 40),
		Path = {
			Vector3.new(-92, 0, 0), Vector3.new(-40, 0, 0), Vector3.new(-40, 0, -45), Vector3.new(20, 0, -45),
			Vector3.new(20, 0, 45), Vector3.new(60, 0, 45), Vector3.new(60, 0, 0), Vector3.new(88, 0, 0),
		},
		Theme = {
			TileA = Color3.fromRGB(70, 50, 50), TileB = Color3.fromRGB(58, 42, 44), Cliff = Color3.fromRGB(40, 25, 25),
			Path = Color3.fromRGB(255, 120, 40), PathNeon = true, CurbA = Color3.fromRGB(30, 20, 20), CurbB = Color3.fromRGB(30, 20, 20),
			ClockTime = 17.6, Ambient = Color3.fromRGB(110, 60, 50), OutdoorAmbient = Color3.fromRGB(150, 90, 70),
			AtmoColor = Color3.fromRGB(255, 160, 120), AtmoDecay = Color3.fromRGB(150, 50, 30), AtmoDensity = 0.35,
			Decor = { "Volcano", "LavaCrystal", "Rock", "LavaCrystal", "Rock" },
		},
	},
}

function Config.GetMap(id: string?)
	for _, m in Config.Maps do
		if m.Id == id then return m end
	end
	return Config.Maps[1]
end

-- Damage = lives lost if it reaches your base.
-- Armor = flat damage blocked per hit (min 1 damage). Flying = only some towers can hit it.
-- Shape = "Block" (default), "Ball" or "Toast". Accessories are built in the server script:
--   Noodles, Tongue, Sunglasses, BackwardsCap, SpeedTrail, Butter, Propeller,
--   Helmet, GoldChain, Brain, Crown, Horns, Aura
Config.Enemies = {
	Noodle = {
		DisplayName = "Noodle Goblin",
		Health = 10, Speed = 8, Reward = 5, Damage = 1,
		Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(255, 170, 60),
		Shape = "Ball", Accessories = { "Noodles", "Tongue" },
	},
	Zoomer = {
		DisplayName = "Zoomer Zoom",
		Health = 6, Speed = 16, Reward = 6, Damage = 1,
		Size = Vector3.new(2.5, 2, 3), Color = Color3.fromRGB(80, 220, 255),
		Accessories = { "Sunglasses", "BackwardsCap", "SpeedTrail" },
	},
	Toast = {
		DisplayName = "Thicc Toast",
		Health = 50, Speed = 5, Reward = 15, Damage = 2,
		Size = Vector3.new(5, 4.5, 3), Color = Color3.fromRGB(245, 215, 160),
		Shape = "Toast", Accessories = { "Butter", "Tongue" },
	},
	Flyer = {
		DisplayName = "Sky Snacc",
		Health = 14, Speed = 10, Reward = 8, Damage = 1, Flying = true,
		Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(150, 255, 150),
		Shape = "Ball", Accessories = { "Propeller" },
	},
	Knight = {
		DisplayName = "Drip Knight",
		Health = 30, Speed = 6, Reward = 12, Damage = 2, Armor = 3,
		Size = Vector3.new(3.5, 4, 3.5), Color = Color3.fromRGB(120, 120, 160),
		Accessories = { "Helmet", "Sunglasses", "GoldChain" },
	},
	Boss = {
		DisplayName = "MEGA BRAINROT",
		Health = 400, Speed = 4, Reward = 100, Damage = 10, Armor = 2, IsBoss = true,
		Size = Vector3.new(8, 8, 8), Color = Color3.fromRGB(255, 60, 200),
		Shape = "Ball", Accessories = { "Brain", "Crown", "Tongue", "Aura" },
		-- Stun: freezes towers within Radius for Duration seconds. Summon: spawns minions behind it.
		Abilities = {
			{ Type = "Stun", Every = 8, Radius = 16, Duration = 2.5 },
			{ Type = "Summon", Every = 10, Enemy = "Noodle", Count = 3 },
		},
	},
	GigaBoss = {
		DisplayName = "GIGA BRAINROT",
		Health = 2500, Speed = 3, Reward = 500, Damage = 20, Armor = 5, IsBoss = true,
		Size = Vector3.new(12, 12, 12), Color = Color3.fromRGB(255, 30, 30),
		Accessories = { "Horns", "Sunglasses", "GoldChain", "Crown", "Aura" },
		-- Rage: below Below (fraction of health) it speeds up by SpeedMult.
		Abilities = {
			{ Type = "Stun", Every = 7, Radius = 20, Duration = 3 },
			{ Type = "Summon", Every = 9, Enemy = "Zoomer", Count = 4 },
			{ Type = "Rage", Below = 0.5, SpeedMult = 1.6 },
		},
	},

	-- Step 7 enemies --------------------------------------------------
	-- SplitInto: on death, splits into SplitCount of another enemy.
	Splitter = {
		DisplayName = "Split Splat",
		Health = 24, Speed = 7, Reward = 6, Damage = 2,
		Size = Vector3.new(3.5, 3.5, 3.5), Color = Color3.fromRGB(255, 90, 90),
		Shape = "Ball", Accessories = { "Tongue" }, SplitInto = "Mini", SplitCount = 3,
	},
	Mini = {
		DisplayName = "Lil Splat",
		Health = 5, Speed = 11, Reward = 2, Damage = 1,
		Size = Vector3.new(1.8, 1.8, 1.8), Color = Color3.fromRGB(255, 150, 150), Shape = "Ball",
	},
	-- Heal: every Interval seconds, heals enemies within Radius by Percent of their max health.
	Healer = {
		DisplayName = "Nurse Nugget",
		Health = 28, Speed = 6, Reward = 10, Damage = 1,
		Size = Vector3.new(3, 3.5, 3), Color = Color3.fromRGB(120, 255, 180),
		Accessories = { "NurseHat" }, Heal = { Radius = 10, Percent = 0.06, Interval = 2 },
	},
	-- Shield: extra health that must be broken first (shown as a bubble + blue bar).
	Shielded = {
		DisplayName = "Bubble Boi",
		Health = 25, Shield = 40, Speed = 6, Reward = 12, Damage = 2,
		Size = Vector3.new(3.5, 3.5, 3.5), Color = Color3.fromRGB(90, 200, 255),
		Shape = "Ball", Accessories = { "Sunglasses" },
	},
	-- Hidden: towers can only hit it inside a Sus Radar's range.
	Ghost = {
		DisplayName = "Sneaky Sus",
		Health = 18, Speed = 10, Reward = 10, Damage = 2, Hidden = true,
		Size = Vector3.new(3, 3, 3), Color = Color3.fromRGB(200, 200, 255),
		Accessories = { "Sunglasses" },
	},
}

-- Each tower has Levels: Levels[1].Cost is the placement price, later Costs are upgrade prices.
-- Optional per-level stats: Splash (radius), Slow (speed multiplier), SlowTime (seconds).
Config.Towers = {
	RizzBlaster = {
		DisplayName = "Rizz Blaster", Rarity = "Common",
		Description = "Reliable single-target laser.",
		Color = Color3.fromRGB(255, 230, 60), HeadShape = "Ball", HitsFlying = true,
		Sound = "Laser", Pitch = 1.2,
		Levels = {
			{ Cost = 100, Damage = 4, Range = 18, Cooldown = 0.6 },
			{ Cost = 90, Damage = 6, Range = 20, Cooldown = 0.5 },
			{ Cost = 180, Damage = 10, Range = 22, Cooldown = 0.4 },
		},
	},
	YapCannon = {
		DisplayName = "Yap Cannon",
		Description = "Splash damage. Can't hit flying.", Rarity = "Epic",
		Color = Color3.fromRGB(255, 120, 40), HeadShape = "Block", HitsFlying = false,
		Sound = "Explosion", Pitch = 1.3,
		Levels = {
			{ Cost = 175, Damage = 6, Range = 15, Cooldown = 1.6, Splash = 6 },
			{ Cost = 150, Damage = 9, Range = 16, Cooldown = 1.4, Splash = 7 },
			{ Cost = 275, Damage = 15, Range = 17, Cooldown = 1.2, Splash = 8 },
		},
	},
	BrainFreeze = {
		DisplayName = "Brain Freeze",
		Description = "Slows enemies down.", Rarity = "Rare",
		Color = Color3.fromRGB(120, 200, 255), HeadShape = "Cylinder", HitsFlying = true,
		Sound = "Laser", Pitch = 1.8,
		Levels = {
			{ Cost = 125, Damage = 1, Range = 14, Cooldown = 0.8, Slow = 0.5, SlowTime = 1.5 },
			{ Cost = 100, Damage = 2, Range = 16, Cooldown = 0.7, Slow = 0.4, SlowTime = 2 },
			{ Cost = 200, Damage = 3, Range = 18, Cooldown = 0.6, Slow = 0.3, SlowTime = 2.5 },
		},
	},
	SigmaSniper = {
		DisplayName = "Sigma Sniper",
		Description = "Huge range, huge damage, slow.", Rarity = "Legendary",
		Color = Color3.fromRGB(200, 80, 255), HeadShape = "Ball", HitsFlying = true,
		Sound = "Laser", Pitch = 0.6,
		Levels = {
			{ Cost = 250, Damage = 20, Range = 45, Cooldown = 2.5 },
			{ Cost = 200, Damage = 35, Range = 50, Cooldown = 2.2 },
			{ Cost = 400, Damage = 60, Range = 60, Cooldown = 2.0 },
		},
	},

	-- Type = "Farm": no attack, pays its owner Income cash at the end of every wave.
	BagChaser = {
		DisplayName = "Bag Chaser", Rarity = "Rare", Type = "Farm", Limit = 6,
		Description = "Earns extra cash every wave. Doesn't attack.",
		Color = Color3.fromRGB(255, 215, 0), HeadShape = "Block", HitsFlying = false,
		Levels = {
			{ Cost = 250, Range = 5, Income = 40 },
			{ Cost = 225, Range = 5, Income = 90 },
			{ Cost = 400, Range = 5, Income = 180 },
		},
	},
	-- RevealsHidden: towers in this tower's range can target hidden enemies.
	SusRadar = {
		DisplayName = "Sus Radar", Rarity = "Rare", RevealsHidden = true,
		Description = "Lets nearby towers see hidden enemies. Weak attack.",
		Color = Color3.fromRGB(120, 255, 160), HeadShape = "Cylinder", HitsFlying = true,
		Sound = "Laser", Pitch = 1.5,
		Levels = {
			{ Cost = 200, Damage = 2, Range = 16, Cooldown = 0.8 },
			{ Cost = 175, Damage = 3, Range = 19, Cooldown = 0.7 },
			{ Cost = 300, Damage = 5, Range = 22, Cooldown = 0.6 },
		},
	},
	-- Type = "Support": boosts towers inside its range (strongest boost applies, they don't stack).
	AuraFarmer = {
		DisplayName = "Aura Farmer", Rarity = "Epic", Type = "Support", Limit = 4,
		Description = "Boosts damage and fire rate of nearby towers.",
		Color = Color3.fromRGB(255, 120, 200), HeadShape = "Ball", HitsFlying = false,
		Levels = {
			{ Cost = 300, Range = 12, DamageBuff = 0.15, SpeedBuff = 0 },
			{ Cost = 275, Range = 14, DamageBuff = 0.25, SpeedBuff = 0.1 },
			{ Cost = 450, Range = 16, DamageBuff = 0.4, SpeedBuff = 0.2 },
		},
	},
	-- Type = "Chain": hits a target, then jumps to up to Chains more enemies within ChainRange.
	MewingTesla = {
		DisplayName = "Mewing Tesla", Rarity = "Mythic", Type = "Chain",
		Description = "Lightning that chains between enemies.",
		Color = Color3.fromRGB(120, 230, 255), HeadShape = "Ball", HitsFlying = true,
		Sound = "Laser", Pitch = 2.2,
		Levels = {
			{ Cost = 400, Damage = 6, Range = 16, Cooldown = 1.1, Chains = 3, ChainRange = 9 },
			{ Cost = 350, Damage = 9, Range = 17, Cooldown = 1.0, Chains = 4, ChainRange = 10 },
			{ Cost = 600, Damage = 14, Range = 19, Cooldown = 0.85, Chains = 6, ChainRange = 11 },
		},
	},
}
Config.TowerOrder = {
	"RizzBlaster", "BrainFreeze", "BagChaser", "SusRadar",
	"YapCannon", "AuraFarmer", "SigmaSniper", "MewingTesla",
}
Config.LoadoutSize = 5

-- Each wave is a list of groups spawned in order: { enemy, count, secondsBetween }
Config.Waves = {
	{ { "Noodle", 6, 1.5 } },
	{ { "Noodle", 10, 1 } },
	{ { "Noodle", 8, 1 }, { "Zoomer", 5, 0.8 } },
	{ { "Zoomer", 12, 0.6 } },
	{ { "Noodle", 10, 0.8 }, { "Toast", 3, 2 } },
	{ { "Flyer", 6, 1 }, { "Splitter", 4, 1.5 }, { "Noodle", 8, 0.7 } }, -- 6: splitters appear
	{ { "Knight", 4, 2 }, { "Zoomer", 10, 0.5 }, { "Splitter", 5, 1 } },
	{ { "Toast", 6, 1.2 }, { "Healer", 2, 2 }, { "Flyer", 8, 0.8 } }, -- 8: healers appear
	{ { "Knight", 8, 1.2 }, { "Healer", 2, 1.5 }, { "Zoomer", 15, 0.4 }, { "Flyer", 6, 0.8 } },
	{ { "Toast", 6, 1 }, { "Boss", 1, 0 } },
	{ { "Shielded", 6, 1.2 }, { "Noodle", 20, 0.4 }, { "Flyer", 10, 0.6 } }, -- 11: shields appear
	{ { "Knight", 12, 1 }, { "Healer", 3, 1.5 }, { "Toast", 6, 1 } },
	{ { "Ghost", 4, 1.5 }, { "Zoomer", 25, 0.3 } }, -- 13: hidden enemies appear (bring a Sus Radar!)
	{ { "Flyer", 20, 0.5 }, { "Shielded", 8, 0.8 }, { "Knight", 8, 0.8 } },
	{ { "Toast", 15, 0.8 }, { "Splitter", 8, 0.6 }, { "Boss", 1, 0 } },
	{ { "Knight", 20, 0.7 }, { "Ghost", 8, 0.8 }, { "Flyer", 15, 0.4 } },
	{ { "Zoomer", 35, 0.25 }, { "Healer", 4, 1 }, { "Toast", 10, 0.7 } },
	{ { "Shielded", 15, 0.6 }, { "Toast", 15, 0.6 }, { "Ghost", 10, 0.6 }, { "Flyer", 20, 0.4 } },
	{ { "Boss", 2, 6 }, { "Splitter", 12, 0.5 }, { "Knight", 15, 0.6 } },
	{ { "Toast", 20, 0.5 }, { "Shielded", 10, 0.5 }, { "Flyer", 20, 0.4 }, { "GigaBoss", 1, 0 } },
}

function Config.WaveBonus(wave: number): number
	return 25 + wave * 10
end

-- Enemies get a bit tougher every wave.
function Config.HealthScale(wave: number): number
	return 1 + (wave - 1) * 0.04
end

function Config.SellValue(kind: string, level: number): number
	local total = 0
	for i = 1, level do
		total += Config.Towers[kind].Levels[i].Cost
	end
	return math.floor(total * Config.SellRefund)
end

return Config
