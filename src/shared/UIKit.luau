-- Reusable UI building blocks styled by Theme.
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local C = Theme.Colors

local UI = {}

function UI.new(className, props, children)
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end
local new = UI.new

-- Corners are capped at Theme.Corner so the whole UI stays blocky. 999 = small round dots only.
function UI.corner(radius)
	local r = if radius and radius >= 999 then 999 else math.min(radius or Theme.Corner, Theme.Corner)
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

function UI.stroke(color, transparency, thickness)
	return new("UIStroke", {
		Color = color or C.Stroke, Transparency = transparency or 0.88, Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.padding(x, y)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x),
		PaddingTop = UDim.new(0, y or x), PaddingBottom = UDim.new(0, y or x),
	})
end

function UI.shine()
	return new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 215)), Rotation = 90 })
end

function UI.list(direction, gap, hAlign, vAlign)
	return new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical, Padding = UDim.new(0, gap or 8),
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Dark cartoon outline around text (pass NoStroke = true to skip it).
function UI.textStroke(parent, thickness)
	return new("UIStroke", {
		Color = Theme.TextStroke, Thickness = thickness or Theme.TextStrokeThickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round, Parent = parent,
	})
end

function UI.label(props)
	local defaults = { BackgroundTransparency = 1, FontFace = Theme.Font, TextColor3 = C.Text, TextSize = 18 }
	local noStroke = props.NoStroke
	for k, v in props do
		if k ~= "NoStroke" then defaults[k] = v end
	end
	local lbl = new("TextLabel", defaults)
	if not noStroke then UI.textStroke(lbl, math.clamp((defaults.TextSize or 18) / 10, 1.2, 3)) end
	return lbl
end

-- Light-to-dark vertical gradient that gives flat colors a glossy cartoon look.
function UI.gloss(parent)
	return new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 210)), Rotation = 90, Parent = parent,
	})
end

function UI.panel(props, children)
	local defaults = { BackgroundColor3 = C.Panel, BackgroundTransparency = Theme.PanelTransparency, BorderSizePixel = 0 }
	for k, v in props do
		defaults[k] = v
	end
	local f = new("Frame", defaults, children)
	UI.corner().Parent = f
	UI.stroke(C.Stroke, 0, 4).Parent = f
	UI.gloss(f)
	return f
end

-- Pop-in animation for windows.
function UI.popIn(frame)
	local s = frame:FindFirstChild("PopScale") or new("UIScale", { Name = "PopScale", Parent = frame })
	s.Scale = 0.85
	UI.tween(s, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Springy hover/press feel for any GuiButton.
function UI.bouncy(btn)
	local s = new("UIScale", { Name = "BounceScale", Parent = btn })
	btn.MouseEnter:Connect(function() UI.tween(s, 0.12, { Scale = 1.06 }) end)
	btn.MouseLeave:Connect(function() UI.tween(s, 0.12, { Scale = 1 }) end)
	btn.MouseButton1Down:Connect(function() UI.tween(s, 0.08, { Scale = 0.93 }) end)
	btn.MouseButton1Up:Connect(function() UI.tween(s, 0.15, { Scale = 1.06 }, Enum.EasingStyle.Back) end)
	return s
end

-- Round icon: image from Theme.Icons if set, otherwise a colored circle with a glyph.
function UI.icon(props)
	local holder = new("Frame", {
		Name = "Icon", Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = props.Color or C.PanelLight, BorderSizePixel = 0, LayoutOrder = props.LayoutOrder or 0, Parent = props.Parent,
	}, { UI.corner() })
	if props.Image and props.Image ~= "" then
		holder.BackgroundTransparency = 1
		new("ImageLabel", {
			Name = "Art", Size = UDim2.fromScale(1.15, 1.15), Position = UDim2.fromScale(-0.075, -0.075),
			BackgroundTransparency = 1, Image = props.Image, ScaleType = Enum.ScaleType.Fit, Parent = holder,
		})
	else
		UI.shine().Parent = holder
		local t = UI.label({ Size = UDim2.fromScale(1, 1), Text = props.Glyph or "?", FontFace = Theme.FontHeavy, TextScaled = true, Parent = holder })
		new("UIPadding", { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0), Parent = t })
	end
	return holder
end

function UI.tween(inst, time, goal, style)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

function UI.button(props)
	local color = props.Color or C.PanelLight
	local btn = new("TextButton", {
		Name = props.Name or "Button", Size = props.Size, Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero, LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = color, AutoButtonColor = false, BorderSizePixel = 0,
		FontFace = Theme.FontBold, TextColor3 = Color3.new(1, 1, 1), TextSize = props.TextSize or 18,
		Text = props.Text or "", Parent = props.Parent,
		TextStrokeColor3 = Theme.TextStroke, TextStrokeTransparency = 0,
	}, { UI.corner(props.Radius or 10), UI.shine() })
	UI.stroke(C.Stroke, 0, 3).Parent = btn
	btn:SetAttribute("BaseColor", color)
	UI.bouncy(btn)
	return btn
end

function UI.setButtonColor(btn, color)
	btn:SetAttribute("BaseColor", color)
	btn.BackgroundColor3 = color
end

-- ScreenGui with a UIScale that keeps everything readable on any screen size.
function UI.screen(name, parent)
	local gui = new("ScreenGui", { Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent })
	local scale = new("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function update()
		local vp = camera.ViewportSize
		scale.Scale = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.15)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return gui
end

-- Small fading message pill at the bottom of the screen.
function UI.toast(gui)
	local frame = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Panel, BackgroundTransparency = 0.05,
		GroupTransparency = 1, ZIndex = 50, Parent = gui,
	}, { UI.corner(), UI.padding(18, 0) })
	local text = UI.label({ Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, FontFace = Theme.FontBold, TextSize = 17, Parent = frame })
	local token = 0
	return function(message, good)
		token += 1
		local my = token
		text.Text = message
		text.TextColor3 = if good then C.Good else C.Bad
		UI.tween(frame, 0.15, { GroupTransparency = 0 })
		task.delay(1.8, function()
			if my == token then UI.tween(frame, 0.3, { GroupTransparency = 1 }) end
		end)
	end
end

return UI
