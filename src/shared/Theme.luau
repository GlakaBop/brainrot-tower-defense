-- UI look & feel. Change colors/fonts here; paste image IDs into Icons to replace the text icons.
local Theme = {}

-- Chunky cartoon font. Every label also gets a dark outline (Theme.TextStroke).
local CARTOON = Font.fromEnum(Enum.Font.FredokaOne)
Theme.Font = CARTOON
Theme.FontBold = CARTOON
Theme.FontHeavy = CARTOON

Theme.TextStroke = Color3.fromRGB(30, 18, 50)
Theme.TextStrokeThickness = 2

Theme.Colors = {
	Panel = Color3.fromRGB(62, 46, 128),
	PanelLight = Color3.fromRGB(96, 76, 180),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(205, 195, 245),
	Good = Color3.fromRGB(110, 235, 130),
	Bad = Color3.fromRGB(255, 95, 110),
	Gold = Color3.fromRGB(255, 205, 70),
	Lives = Color3.fromRGB(255, 85, 110),
	Cash = Color3.fromRGB(80, 210, 110),
	Wave = Color3.fromRGB(90, 160, 255),
	Upgrade = Color3.fromRGB(60, 190, 95),
	Sell = Color3.fromRGB(225, 70, 90),
	Target = Color3.fromRGB(80, 120, 230),
	Disabled = Color3.fromRGB(70, 68, 90),
}

Theme.PanelTransparency = 0
Theme.Corner = 16

-- Lobby menu tiles (left side). Background colors, like the bright pastel tiles in popular sims.
Theme.Tiles = {
	Shop = Color3.fromRGB(110, 225, 245),
	Towers = Color3.fromRGB(255, 150, 200),
	Slot = Color3.fromRGB(70, 200, 245),
	EmptySlot = Color3.fromRGB(150, 95, 55),
	Play = Color3.fromRGB(120, 225, 110),
}

-- Image slots: paste "rbxassetid://123..." to use your own icon art instead of the text glyphs.
Theme.Icons = {
	Lives = "rbxassetid://84951212199562",
	Cash = "rbxassetid://134939571061578",
	Wave = "rbxassetid://102950342215299",
	Towers = {
		RizzBlaster = "rbxassetid://118621044792447",
		BrainFreeze = "rbxassetid://104923947695218",
		YapCannon = "rbxassetid://122455259914881",
		SigmaSniper = "rbxassetid://97520522995430",
		BagChaser = "",
		SusRadar = "",
		AuraFarmer = "",
		MewingTesla = "",
	},
	-- Crate art (square, transparent PNG). Empty = drawn placeholder box.
	Crates = {
		Basic = "",
		Brainrot = "",
	},
}

-- Text glyphs used while an icon slot is empty.
Theme.Glyphs = {
	Lives = "♥",
	Cash = "$",
	Wave = "W",
	Towers = {
		RizzBlaster = "R",
		BrainFreeze = "F",
		YapCannon = "Y",
		SigmaSniper = "S",
		BagChaser = "$",
		SusRadar = "?",
		AuraFarmer = "A",
		MewingTesla = "T",
	},
}

return Theme
