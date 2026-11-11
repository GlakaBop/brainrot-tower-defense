-- Small shared helpers for building parts and folders.
local Util = {}

function Util.makePart(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then p.Shape = props.Shape end
	if props.Size then p.Size = props.Size end
	for k, v in props do
		if k ~= "Shape" and k ~= "Size" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

function Util.weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

function Util.makeFolder(name, parent)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Util.billboardText(parent, text, size, offset, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = size
	bb.StudsOffset = offset
	bb.AlwaysOnTop = true
	bb.MaxDistance = 150
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Parent = bb
	bb.Parent = parent
	return bb, t
end

return Util
