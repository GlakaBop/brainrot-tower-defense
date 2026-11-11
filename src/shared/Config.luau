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

-- Towers everyone owns from the start; others are bought in the lobby shop (UnlockPrice on each tower).
Config.StarterTowers = { "RizzBlaster" }

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
Config.Path = {
	Vector3.new(-92, 0, -50),
	Vector3.new(-50, 0, -50),
	Vector3.new(-50, 0, 30),
	Vector3.new(-10, 0, 30),
	Vector3.new(-10, 0, -40),
	Vector3.new(35, 0, -40),
	Vector3.new(35, 0, 45),
	Vector3.new(88, 0, 45),
}

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
	},
	GigaBoss = {
		DisplayName = "GIGA BRAINROT",
		Health = 2500, Speed = 3, Reward = 500, Damage = 20, Armor = 5, IsBoss = true,
		Size = Vector3.new(12, 12, 12), Color = Color3.fromRGB(255, 30, 30),
		Accessories = { "Horns", "Sunglasses", "GoldChain", "Crown", "Aura" },
	},
}

-- Each tower has Levels: Levels[1].Cost is the placement price, later Costs are upgrade prices.
-- Optional per-level stats: Splash (radius), Slow (speed multiplier), SlowTime (seconds).
Config.Towers = {
	RizzBlaster = {
		DisplayName = "Rizz Blaster",
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
		Description = "Splash damage. Can't hit flying.", UnlockPrice = 300,
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
		Description = "Slows enemies down.", UnlockPrice = 150,
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
		Description = "Huge range, huge damage, slow.", UnlockPrice = 500,
		Color = Color3.fromRGB(200, 80, 255), HeadShape = "Ball", HitsFlying = true,
		Sound = "Laser", Pitch = 0.6,
		Levels = {
			{ Cost = 250, Damage = 20, Range = 45, Cooldown = 2.5 },
			{ Cost = 200, Damage = 35, Range = 50, Cooldown = 2.2 },
			{ Cost = 400, Damage = 60, Range = 60, Cooldown = 2.0 },
		},
	},
}
Config.TowerOrder = { "RizzBlaster", "BrainFreeze", "YapCannon", "SigmaSniper" }

-- Each wave is a list of groups spawned in order: { enemy, count, secondsBetween }
Config.Waves = {
	{ { "Noodle", 6, 1.5 } },
	{ { "Noodle", 10, 1 } },
	{ { "Noodle", 8, 1 }, { "Zoomer", 5, 0.8 } },
	{ { "Zoomer", 12, 0.6 } },
	{ { "Noodle", 10, 0.8 }, { "Toast", 3, 2 } },
	{ { "Flyer", 6, 1 }, { "Noodle", 8, 0.7 } },
	{ { "Knight", 4, 2 }, { "Zoomer", 10, 0.5 } },
	{ { "Toast", 6, 1.2 }, { "Flyer", 8, 0.8 } },
	{ { "Knight", 8, 1.2 }, { "Zoomer", 15, 0.4 }, { "Flyer", 6, 0.8 } },
	{ { "Toast", 6, 1 }, { "Boss", 1, 0 } },
	{ { "Noodle", 25, 0.4 }, { "Flyer", 10, 0.6 } },
	{ { "Knight", 12, 1 }, { "Toast", 6, 1 } },
	{ { "Zoomer", 30, 0.3 } },
	{ { "Flyer", 20, 0.5 }, { "Knight", 8, 0.8 } },
	{ { "Toast", 15, 0.8 }, { "Boss", 1, 0 } },
	{ { "Knight", 20, 0.7 }, { "Flyer", 15, 0.4 } },
	{ { "Zoomer", 40, 0.25 }, { "Toast", 10, 0.7 } },
	{ { "Knight", 15, 0.6 }, { "Toast", 15, 0.6 }, { "Flyer", 20, 0.4 } },
	{ { "Boss", 2, 6 }, { "Knight", 15, 0.6 } },
	{ { "Toast", 20, 0.5 }, { "Flyer", 20, 0.4 }, { "GigaBoss", 1, 0 } },
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
