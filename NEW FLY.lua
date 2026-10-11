print("Warpah Fly start")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GUI_NAME = "WarpahFlyGui"
local WINDOW_TITLE = "Warpah Fly"
local VERSION = "1.0"
local LOGO_ID = "rbxassetid://77482003578660"
local TITLE_H = 36
local SIDE_W = 92
local TAB_H = 30
local TAB_NAMES = { "Fly", "Metode", "Cahaya" }

local executorName = "Unknown"
if identifyexecutor then
	local ok, name = pcall(identifyexecutor)
	if ok and name then executorName = tostring(name) end
end

local WHITE = Color3.new(1, 1, 1)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function lum(c) return c.R * 0.299 + c.G * 0.587 + c.B * 0.114 end
local function round(n) return math.floor(n + 0.5) end

local function tween(obj, time, props, style, dir, delay)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out, 0, false, delay or 0)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function create(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function getGuiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then
		local writable = pcall(function()
			local f = Instance.new("Folder")
			f.Parent = core
			f:Destroy()
		end)
		if writable then return core end
	end
	return player:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
for _, p in ipairs({ guiParent, player:FindFirstChild("PlayerGui") }) do
	if p then
		local old = p:FindFirstChild(GUI_NAME)
		if old then old:Destroy() end
	end
end

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local conns = {}
local cleanupFns = {}
local function bind(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function isPointerMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerDown(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function mk(name, bg, accent, light)
	local text = light and rgb(20, 28, 24) or rgb(232, 244, 236)
	return {
		name = name,
		bg = bg,
		top = bg:Lerp(accent, 0.07),
		item = bg:Lerp(accent, 0.12),
		itemHover = bg:Lerp(accent, 0.22),
		accent = accent,
		text = text,
		subtext = text:Lerp(bg, 0.45),
		onAccent = lum(accent) > 0.55 and rgb(8, 18, 12) or WHITE,
	}
end

local THEMES = {
	mk("Neon Green",      rgb(7, 24, 15),    rgb(57, 255, 20)),
	mk("Matrix",          rgb(0, 12, 4),     rgb(0, 255, 65)),
	mk("Emerald",         rgb(10, 28, 24),   rgb(46, 230, 160)),
	mk("Forest",          rgb(14, 28, 16),   rgb(140, 230, 90)),
	mk("Toxic Lime",      rgb(14, 20, 6),    rgb(200, 255, 0)),
	mk("Mint",            rgb(12, 28, 26),   rgb(130, 255, 215)),
	mk("Cyber Teal",      rgb(6, 22, 28),    rgb(0, 229, 255)),
	mk("Aqua",            rgb(6, 20, 36),    rgb(60, 200, 255)),
	mk("Ocean",           rgb(8, 16, 34),    rgb(64, 150, 255)),
	mk("Midnight Purple", rgb(16, 10, 32),   rgb(170, 100, 255)),
	mk("Synthwave",       rgb(22, 8, 30),    rgb(255, 60, 200)),
	mk("Rose",            rgb(28, 10, 20),   rgb(255, 120, 170)),
	mk("Crimson",         rgb(26, 8, 10),    rgb(255, 70, 85)),
	mk("Sunset",          rgb(28, 14, 8),    rgb(255, 140, 40)),
	mk("Gold",            rgb(24, 20, 8),    rgb(255, 205, 50)),
	mk("Hacker Amber",    rgb(12, 9, 0),     rgb(255, 176, 0)),
	mk("Mono Dark",       rgb(14, 14, 14),   rgb(230, 230, 230)),
	mk("Snow (Light)",    rgb(238, 244, 240), rgb(0, 170, 90), true),
}

local THEME = {}
for k, v in pairs(THEMES[1]) do THEME[k] = v end
local currentThemeName = THEMES[1].name
local neonBorder = true

local registry = {}

local function regFn(inst, prop, getter, deps)
	local depSet = {}
	for _, d in ipairs(deps) do depSet[d] = true end
	table.insert(registry, { inst = inst, prop = prop, get = getter, deps = depSet })
	inst[prop] = getter()
end

local function reg(inst, prop, role)
	regFn(inst, prop, function() return THEME[role] end, { role })
end

local function refresh(changed, time)
	for _, e in ipairs(registry) do
		local hit = changed == nil
		if not hit then
			for d in pairs(e.deps) do
				if changed[d] then hit = true break end
			end
		end
		if hit and e.inst.Parent then
			local v = e.get()
			if time and time > 0 then
				tween(e.inst, time, { [e.prop] = v }, Enum.EasingStyle.Quad)
			else
				e.inst[e.prop] = v
			end
		end
	end
end

local ACCENT_SET = { accent = true, onAccent = true }
local function setAccent(c, time)
	THEME.accent = c
	THEME.onAccent = lum(c) > 0.55 and rgb(8, 18, 12) or WHITE
	refresh(ACCENT_SET, time or 0)
end

local MIN_W, MIN_H = 320, 190

local function getDefaultSize()
	local vp = camera.ViewportSize
	local w, h
	if isMobile() then
		w = math.clamp(vp.X * 0.58, 340, 480)
		h = math.clamp(vp.Y * 0.80, 200, 300)
	else
		w, h = 460, 300
	end
	return Vector2.new(math.min(w, vp.X - 16), math.min(h, vp.Y - 16))
end

local function clampSize(s)
	local vp = camera.ViewportSize
	return Vector2.new(
		math.clamp(s.X, MIN_W, math.max(MIN_W, vp.X - 8)),
		math.clamp(s.Y, MIN_H, math.max(MIN_H, vp.Y - 8))
	)
end

local function clampPos(p, size)
	local vp = camera.ViewportSize
	return Vector2.new(
		math.clamp(p.X, 0, math.max(0, vp.X - size.X)),
		math.clamp(p.Y, 0, math.max(0, vp.Y - size.Y))
	)
end

local fullSize = getDefaultSize()
local function getMinimizedSize()
	return Vector2.new(math.min(fullSize.X, 210), TITLE_H)
end

local minimized, closing, ready = false, false, false

local screen = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local main = create("CanvasGroup", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(fullSize.X, fullSize.Y),
	GroupTransparency = 1,
	Parent = screen,
})
reg(main, "BackgroundColor3", "bg")
create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = main })
local mainStroke = create("UIStroke", { Thickness = 1.5, Transparency = 0.2, Parent = main })
regFn(mainStroke, "Color", function()
	return neonBorder and THEME.accent or THEME.itemHover
end, { "accent", "itemHover" })
local scale = create("UIScale", { Scale = 0.8, Parent = main })

local titleBar = create("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, TITLE_H),
	BorderSizePixel = 0,
	Parent = main,
})
reg(titleBar, "BackgroundColor3", "top")

create("ImageLabel", {
	Name = "Logo",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(22, 22),
	BackgroundTransparency = 1,
	Image = LOGO_ID,
	ScaleType = Enum.ScaleType.Fit,
	Parent = titleBar,
})

local titleLabel = create("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 38, 0, 0),
	Size = UDim2.fromOffset(88, TITLE_H),
	Text = WINDOW_TITLE,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Parent = titleBar,
})
reg(titleLabel, "TextColor3", "text")

local statsHolder = create("Frame", {
	Name = "Stats",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 130, 0, 0),
	Size = UDim2.new(1, -130 - 76, 1, 0),
	ClipsDescendants = true,
	Parent = titleBar,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = statsHolder,
})

local function statLabel(order, text, color)
	return create("TextLabel", {
		LayoutOrder = order,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Text = text,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Parent = statsHolder,
	})
end

local fpsTitle = statLabel(1, "FPS: -", rgb(255, 150, 40))
statLabel(2, player.Name, rgb(255, 70, 85))
local pingTitle = statLabel(3, "Ping: -", rgb(80, 255, 100))
statLabel(4, executorName, rgb(70, 150, 255))

local function pressEffect(btn, scaleObj)
	btn.MouseButton1Down:Connect(function()
		tween(scaleObj, 0.1, { Scale = 0.92 })
	end)
	local function release()
		tween(scaleObj, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	btn.MouseButton1Up:Connect(release)
	btn.MouseLeave:Connect(release)
end

local function hoverColor(btn, getNormal, getHover)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.18, { BackgroundColor3 = getHover() })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.25, { BackgroundColor3 = getNormal() })
	end)
end

local function titleButton(text, xOffset, hoverCol)
	local b = create("TextButton", {
		Name = "Btn_" .. text,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		AutoButtonColor = false,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Parent = titleBar,
	})
	reg(b, "BackgroundColor3", "item")
	reg(b, "TextColor3", "text")
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
	local s = create("UIScale", { Parent = b })
	hoverColor(b, function() return THEME.item end, function() return hoverCol end)
	pressEffect(b, s)
	return b
end

local closeBtn = titleButton("×", -8, rgb(235, 87, 87))
local minBtn = titleButton("–", -40, rgb(240, 190, 70))

local body = create("CanvasGroup", {
	Name = "Body",
	Position = UDim2.new(0, 0, 0, TITLE_H),
	Size = UDim2.new(1, 0, 1, -TITLE_H),
	BackgroundTransparency = 1,
	Parent = main,
})

local sidebar = create("ScrollingFrame", {
	Name = "Sidebar",
	Size = UDim2.new(0, SIDE_W, 1, 0),
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.fromOffset(0, 16 + #TAB_NAMES * (TAB_H + 4)),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = body,
})
reg(sidebar, "BackgroundColor3", "top")

local content = create("Frame", {
	Name = "Content",
	Position = UDim2.new(0, SIDE_W, 0, 0),
	Size = UDim2.new(1, -SIDE_W, 1, 0),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = body,
})

local indicator = create("Frame", {
	Position = UDim2.fromOffset(2, 8 + 6),
	Size = UDim2.fromOffset(3, TAB_H - 12),
	Parent = sidebar,
})
reg(indicator, "BackgroundColor3", "accent")
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })

local grip = create("TextButton", {
	Name = "ResizeGrip",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.fromOffset(28, 28),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 20,
	Parent = main,
})
for _, spec in ipairs({ { 8, 18 }, { 16, 10 } }) do
	local ln = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(spec[2] + 4, spec[2] + 4),
		Size = UDim2.fromOffset(spec[1], 2),
		Rotation = -45,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = grip,
	})
	reg(ln, "BackgroundColor3", "accent")
end

local target = clampPos((camera.ViewportSize - fullSize) / 2, fullSize)
local current = target
main.Position = UDim2.fromOffset(current.X + fullSize.X / 2, current.Y + fullSize.Y / 2)

bind(RunService.RenderStepped, function(dt)
	local a = 1 - math.exp(-dt * 20)
	current = current:Lerp(target, a)
	main.Position = UDim2.fromOffset(
		current.X + main.Size.X.Offset / 2,
		current.Y + main.Size.Y.Offset / 2
	)
end)

local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

bind(titleBar.InputBegan, function(input)
	if isPointerDown(input) then
		dragging = true
		dragStart = input.Position
		startPos = target
		tween(titleBar, 0.2, { BackgroundColor3 = THEME.itemHover })
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				tween(titleBar, 0.3, { BackgroundColor3 = THEME.top })
			end
		end)
	end
end)
bind(titleBar.InputChanged, function(input)
	if isPointerMove(input) then dragInput = input end
end)

local resizing, resizeInput, resizeStart, resizeStartSize = false, nil, nil, nil
local syncSizeSliders

bind(grip.InputBegan, function(input)
	if minimized or closing then return end
	if isPointerDown(input) then
		resizing = true
		resizeStart = input.Position
		resizeStartSize = fullSize
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
				if syncSizeSliders then syncSizeSliders() end
			end
		end)
	end
end)
bind(grip.InputChanged, function(input)
	if isPointerMove(input) then resizeInput = input end
end)

bind(UserInputService.InputChanged, function(input)
	if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = input.Position - dragStart
		local size = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
		target = clampPos(startPos + Vector2.new(d.X, d.Y), size)
	elseif resizing and (input == resizeInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = input.Position - resizeStart
		local vp = camera.ViewportSize
		local maxW = math.max(MIN_W, vp.X - target.X)
		local maxH = math.max(MIN_H, vp.Y - target.Y)
		local w = math.clamp(resizeStartSize.X + d.X, MIN_W, maxW)
		local h = math.clamp(resizeStartSize.Y + d.Y, MIN_H, maxH)
		fullSize = Vector2.new(w, h)
		main.Size = UDim2.fromOffset(w, h)
		target = clampPos(target, fullSize)
	end
end)

local function setFullSize(sz, time)
	fullSize = clampSize(sz)
	target = clampPos(target, fullSize)
	if not minimized then
		local u = UDim2.fromOffset(fullSize.X, fullSize.Y)
		if time and time > 0 then
			tween(main, time, { Size = u }, Enum.EasingStyle.Quad)
		else
			main.Size = u
		end
	end
end

local function setMinimized(state)
	if closing or not ready then return end
	minimized = state
	resizing = false

	if state then
		minBtn.Text = "+"
		tween(minBtn, 0.4, { Rotation = 180 })
		grip.Visible = false
		tween(body, 0.2, { GroupTransparency = 1 })
		local sz = getMinimizedSize()
		local t = tween(main, 0.45, { Size = UDim2.fromOffset(sz.X, sz.Y) }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		t.Completed:Connect(function()
			if minimized then body.Visible = false end
		end)
	else
		minBtn.Text = "–"
		tween(minBtn, 0.4, { Rotation = 0 })
		body.Visible = true
		target = clampPos(target, fullSize)
		tween(main, 0.5, { Size = UDim2.fromOffset(fullSize.X, fullSize.Y) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween(body, 0.35, { GroupTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0.12)
		task.delay(0.4, function()
			if not minimized and not closing then grip.Visible = true end
		end)
	end
end

local function closeGui()
	if closing then return end
	closing = true
	dragging, resizing = false, false

	for _, fn in ipairs(cleanupFns) do pcall(fn) end

	tween(scale, 0.4, { Scale = 0.75 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local t = tween(main, 0.35, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0.05)
	t.Completed:Connect(function()
		for _, c in ipairs(conns) do c:Disconnect() end
		screen:Destroy()
	end)
end

bind(minBtn.Activated, function() setMinimized(not minimized) end)
bind(closeBtn.Activated, closeGui)

-- ===== KEYBIND =====
local keyCapture = nil
local toggleKey = Enum.KeyCode.RightShift
local flyKey = Enum.KeyCode.F
local flyToggle

bind(UserInputService.InputBegan, function(input, processed)
	if keyCapture then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			local fn = keyCapture
			keyCapture = nil
			fn(input.KeyCode)
		end
		return
	end
	if processed or closing then return end
	if input.KeyCode == toggleKey then
		setMinimized(not minimized)
	elseif input.KeyCode == flyKey and flyToggle then
		flyToggle.Set(not flyToggle.Get())
	end
end)

local infoScreenRow
bind(camera:GetPropertyChangedSignal("ViewportSize"), function()
	if closing then return end
	fullSize = clampSize(fullSize)
	local sz = minimized and getMinimizedSize() or fullSize
	tween(main, 0.3, { Size = UDim2.fromOffset(sz.X, sz.Y) }, Enum.EasingStyle.Quad)
	target = clampPos(target, sz)
	if syncSizeSliders then syncSizeSliders() end
	if infoScreenRow then
		local vp = camera.ViewportSize
		infoScreenRow.Set(round(vp.X) .. " x " .. round(vp.Y))
	end
end)

local toastHolder = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -12),
	Size = UDim2.fromOffset(240, 300),
	Parent = screen,
})
create("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Parent = toastHolder,
})
local toastOrder = 0

local function notify(text)
	if closing then return end
	toastOrder += 1
	local t = create("CanvasGroup", {
		Size = UDim2.fromOffset(230, 38),
		BackgroundColor3 = THEME.item,
		GroupTransparency = 1,
		LayoutOrder = toastOrder,
		Parent = toastHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = t })
	create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.5, Parent = t })
	create("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = THEME.accent, BorderSizePixel = 0, Parent = t })
	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = text,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		Parent = t,
	})
	local sc = create("UIScale", { Scale = 0.85, Parent = t })
	tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(t, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)

	task.delay(2.6, function()
		if not t.Parent then return end
		tween(t, 0.3, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		local o = tween(sc, 0.3, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		o.Completed:Connect(function() t:Destroy() end)
	end)
end

-- ===== PAGES & TABS =====
local pages = {}
local tabButtons = {}
local currentTab = nil

local function tabColor(name)
	return currentTab == name and THEME.accent or THEME.subtext
end

local function newPage(name)
	local holder = create("CanvasGroup", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = content,
	})
	local scroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = holder,
	})
	reg(scroll, "ScrollBarImageColor3", "accent")
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 28),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
		Parent = scroll,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	local page = { name = name, holder = holder, scroll = scroll, order = 0 }
	pages[name] = page
	return page
end

local function selectTab(name)
	if currentTab == name then return end
	local newP = pages[name]
	local oldName = currentTab
	local oldP = oldName and pages[oldName]
	currentTab = name

	local idx = table.find(TAB_NAMES, name)
	tween(indicator, 0.4, { Position = UDim2.fromOffset(2, 8 + (idx - 1) * (TAB_H + 4) + 6) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	for n, b in pairs(tabButtons) do
		tween(b, 0.25, { TextColor3 = tabColor(n), BackgroundTransparency = (n == name) and 0 or 1 }, Enum.EasingStyle.Quad)
	end

	if oldP then
		oldP.holder.ZIndex = 1
		tween(oldP.holder, 0.15, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		task.delay(0.17, function()
			if currentTab ~= oldName then oldP.holder.Visible = false end
		end)
	end
	newP.holder.ZIndex = 2
	newP.holder.Visible = true
	newP.holder.Position = UDim2.fromOffset(0, 14)
	tween(newP.holder, 0.4, { Position = UDim2.fromOffset(0, 0) })
	tween(newP.holder, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
end

for i, name in ipairs(TAB_NAMES) do
	local b = create("TextButton", {
		Name = name,
		Position = UDim2.fromOffset(8, 8 + (i - 1) * (TAB_H + 4)),
		Size = UDim2.new(1, -14, 0, TAB_H),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		Parent = sidebar,
	})
	reg(b, "BackgroundColor3", "item")
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = b })
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = b })
	regFn(b, "TextColor3", function() return tabColor(name) end, { "accent", "subtext" })
	b.MouseEnter:Connect(function()
		if currentTab ~= name then tween(b, 0.15, { BackgroundTransparency = 0.6 }) end
	end)
	b.MouseLeave:Connect(function()
		if currentTab ~= name then tween(b, 0.2, { BackgroundTransparency = 1 }) end
	end)
	b.Activated:Connect(function() selectTab(name) end)
	tabButtons[name] = b
	newPage(name)
end

-- ===== KOMPONEN =====
local function nextOrder(page)
	page.order += 1
	return page.order
end

local function card(page, height)
	local f = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = nextOrder(page),
		Parent = page.scroll,
	})
	reg(f, "BackgroundColor3", "item")
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = f })
	return f
end

local function cardText(parent, text, pos, size, role, font, textSize, align)
	local l = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = pos,
		Size = size,
		Text = text,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = font or Enum.Font.GothamMedium,
		TextSize = textSize or 13,
		Parent = parent,
	})
	reg(l, "TextColor3", role)
	return l
end

local function addLabel(page, text)
	local l = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = string.upper(text),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		LayoutOrder = nextOrder(page),
		Parent = page.scroll,
	})
	reg(l, "TextColor3", "subtext")
	return l
end

local function addParagraph(page, text)
	local f = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(page),
		Parent = page.scroll,
	})
	reg(f, "BackgroundColor3", "item")
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = f })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
		Parent = f,
	})
	local l = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Parent = f,
	})
	reg(l, "TextColor3", "text")
	return f
end

local function addButton(page, text, callback)
	local b = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		AutoButtonColor = false,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		LayoutOrder = nextOrder(page),
		Parent = page.scroll,
	})
	reg(b, "BackgroundColor3", "accent")
	reg(b, "TextColor3", "onAccent")
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = b })
	local s = create("UIScale", { Parent = b })
	hoverColor(b, function() return THEME.accent end, function() return THEME.accent:Lerp(WHITE, 0.2) end)
	pressEffect(b, s)
	b.Activated:Connect(function()
		if callback then task.spawn(callback) end
	end)
	return b
end

local function addToggle(page, text, default, callback)
	local item = card(page, 38)
	cardText(item, text, UDim2.new(0, 12, 0, 0), UDim2.new(1, -70, 1, 0), "text")

	local track = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		AutoButtonColor = false,
		Text = "",
		Parent = item,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = WHITE,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local knobScale = create("UIScale", { Parent = knob })

	local state = default and true or false
	regFn(track, "BackgroundColor3", function()
		return state and THEME.accent or THEME.bg
	end, { "accent", "bg" })

	local function render(animate)
		local pos = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local col = state and THEME.accent or THEME.bg
		if animate then
			tween(knob, 0.3, { Position = pos }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			tween(track, 0.25, { BackgroundColor3 = col })
		else
			knob.Position = pos
			track.BackgroundColor3 = col
		end
	end
	render(false)

	local obj = { Frame = item }
	function obj.Get() return state end
	function obj.Set(v, silent)
		state = v and true or false
		render(true)
		if not silent and callback then task.spawn(callback, state) end
	end

	track.MouseButton1Down:Connect(function()
		tween(knobScale, 0.1, { Scale = 1.2 })
	end)
	track.Activated:Connect(function()
		obj.Set(not state)
		tween(knobScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	track.MouseLeave:Connect(function()
		tween(knobScale, 0.2, { Scale = 1 })
	end)
	return obj
end

local function addSlider(page, text, min, max, default, callback)
	local item = card(page, 56)
	cardText(item, text, UDim2.new(0, 12, 0, 6), UDim2.new(1, -80, 0, 18), "text")
	local valueLabel = cardText(item, tostring(default), UDim2.new(1, -72, 0, 6), UDim2.fromOffset(60, 18),
		"accent", Enum.Font.GothamBold, 13, Enum.TextXAlignment.Right)

	local hit = create("TextButton", {
		Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = item,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		Parent = hit,
	})
	reg(bar, "BackgroundColor3", "bg")
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
	local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = bar })
	reg(fill, "BackgroundColor3", "accent")
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = WHITE,
		Parent = bar,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local knobScale = create("UIScale", { Parent = knob })

	local value = math.clamp(default, min, max)
	local function setAlpha(alpha)
		alpha = math.clamp(alpha, 0, 1)
		tween(fill, 0.08, { Size = UDim2.new(alpha, 0, 1, 0) }, Enum.EasingStyle.Linear)
		tween(knob, 0.08, { Position = UDim2.new(alpha, 0, 0.5, 0) }, Enum.EasingStyle.Linear)
	end
	local function setInstant(alpha)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end
	setInstant((value - min) / (max - min))
	valueLabel.Text = tostring(value)

	local obj = { Frame = item }
	function obj.Set(v, silent)
		v = math.clamp(round(v), min, max)
		value = v
		valueLabel.Text = tostring(v)
		setAlpha((v - min) / (max - min))
		if not silent and callback then task.spawn(callback, v) end
	end

	local sliding, slideInput = false, nil
	local function update(input)
		local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = round(min + (max - min) * alpha)
		setAlpha(alpha)
		if v ~= value then
			value = v
			valueLabel.Text = tostring(v)
			if callback then task.spawn(callback, v) end
		end
	end

	hit.InputBegan:Connect(function(input)
		if isPointerDown(input) then
			sliding = true
			slideInput = input
			page.scroll.ScrollingEnabled = false
			tween(knobScale, 0.15, { Scale = 1.3 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			update(input)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					sliding = false
					page.scroll.ScrollingEnabled = true
					tween(knobScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end
	end)
	hit.InputChanged:Connect(function(input)
		if isPointerMove(input) then slideInput = input end
	end)
	bind(UserInputService.InputChanged, function(input)
		if sliding and (input == slideInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			update(input)
		end
	end)
	return obj
end

local function addKeybind(page, text, getKey, onSet)
	local item = card(page, 38)
	cardText(item, text, UDim2.new(0, 12, 0, 0), UDim2.new(1, -140, 1, 0), "text")
	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(110, 24),
		AutoButtonColor = false,
		Text = getKey().Name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Parent = item,
	})
	reg(btn, "BackgroundColor3", "accent")
	reg(btn, "TextColor3", "onAccent")
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
	local s = create("UIScale", { Parent = btn })
	pressEffect(btn, s)

	btn.Activated:Connect(function()
		if keyCapture then return end
		btn.Text = "Tekan tombol..."
		keyCapture = function(keyCode)
			if keyCode == Enum.KeyCode.Escape then
				btn.Text = getKey().Name
				return
			end
			onSet(keyCode)
			btn.Text = keyCode.Name
		end
	end)
	return { Set = function(name) btn.Text = name end }
end

local function addInfoRow(page, key, value)
	local item = card(page, 30)
	cardText(item, key, UDim2.new(0, 12, 0, 0), UDim2.new(0.4, 0, 1, 0), "subtext", Enum.Font.GothamMedium, 12)
	local v = cardText(item, tostring(value), UDim2.new(0.4, 0, 0, 0), UDim2.new(0.6, -12, 1, 0),
		"accent", Enum.Font.GothamBold, 12, Enum.TextXAlignment.Right)
	return {
		Frame = item,
		Set = function(t) v.Text = tostring(t) end,
	}
end

-- ===== FLY ENGINE =====
local function getChar()
	local c = player.Character
	if not c then return nil end
	return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local METHODS = {
	{ "Smooth",      "BodyVelocity + BodyGyro, gerak halus ala admin fly." },
	{ "Modern",      "LinearVelocity + AlignOrientation (constraint baru)." },
	{ "CFrame",      "Geser posisi lewat CFrame tiap frame, tanpa fisika." },
	{ "SmoothCF",    "CFrame dengan akselerasi halus." },
	{ "Lerp",        "CFrame:Lerp ke titik di depan, mulus dan responsif." },
	{ "Tween",       "TweenService menggeser karakter tiap 0.1 detik." },
	{ "Blink",       "Lompat-lompat teleport pendek tiap 0.25 detik." },
	{ "Safe",        "Set kecepatan fisika + anti gravitasi, tetap nabrak tembok." },
	{ "NoClip",      "CFrame + tembus tembok." },
	{ "VectorForce", "Didorong gaya VectorForce (fisika murni)." },
	{ "AlignPos",    "AlignPosition mengejar titik di depan karakter." },
	{ "BodyPos",     "BodyPosition (spring) mengejar titik di depan." },
	{ "Impulse",     "Dorongan ApplyImpulse tiap frame." },
	{ "Rocket",      "Momentum: makin lama makin cepat, meluncur saat dilepas." },
	{ "Hover",       "Ketinggian terkunci, NAIK/TURUN ubah tinggi." },
	{ "Glide",       "Meluncur turun pelan, tekan NAIK untuk naik." },
	{ "Jetpack",     "Jalan horizontal biasa, naik/turun halus." },
}
local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
local NO_PLATFORM = { Safe = true, Rocket = true, Hover = true, Jetpack = true, Impulse = true }

local Fly = { on = false, method = "Smooth", speed = 60, noclip = false, up = false, down = false, light = 0, lightRange = 10, spot = true, pad = true }

local flyObjs, noclipParts = {}, {}
local flyConn, noclipConn
local bvObj, bgObj, lvObj, aoObj, bfObj, bpObj, apObj, vfObj
local flyVel = Vector3.zero
local hoverY, stepAcc = 0, 0
local methodInfoRow

local function noclipActive()
	return Fly.on and (Fly.noclip or Fly.method == "NoClip")
end

local function restoreCollide()
	for part in pairs(noclipParts) do
		if part.Parent then part.CanCollide = true end
	end
	table.clear(noclipParts)
end

local function noclipStep()
	local c = player.Character
	if not c then return end
	if noclipActive() then
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") and d.CanCollide then
				noclipParts[d] = true
				d.CanCollide = false
			end
		end
	elseif next(noclipParts) then
		restoreCollide()
	end
end

local function cameraDir(md, cf)
	if md.Magnitude < 0.05 then return Vector3.zero end
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 0.01 then return md end
	look = look.Unit
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
	return cf.LookVector * md:Dot(look) + cf.RightVector * md:Dot(right)
end

local function flatCF(cf, r, pos)
	local fl = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if fl.Magnitude > 0.01 then
		return CFrame.lookAt(pos, pos + fl)
	end
	return CFrame.new(pos) * (r.CFrame - r.CFrame.Position)
end

local function flyStep(dt)
	local c, h, r = getChar()
	if not (h and r) or h.Health <= 0 then return end
	local cf = camera.CFrame
	local m = Fly.method
	local sp = Fly.speed
	local upHeld = Fly.up or UserInputService:IsKeyDown(Enum.KeyCode.Space)
	local downHeld = Fly.down or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local v = (upHeld and 1 or 0) - (downHeld and 1 or 0)
	local md = h.MoveDirection

	if bfObj then
		bfObj.Force = Vector3.new(0, workspace.Gravity * r.AssemblyMass, 0)
	end

	local dir = cameraDir(md, cf) + Vector3.yAxis * v
	if dir.Magnitude > 1 then dir = dir.Unit end

	if m == "Smooth" or m == "Modern" then
		flyVel = flyVel:Lerp(dir * sp, 1 - math.exp(-dt * 8))
		if m == "Modern" then
			if lvObj then lvObj.VectorVelocity = flyVel end
			if aoObj then aoObj.CFrame = cf end
		else
			if bvObj then bvObj.Velocity = flyVel end
			if bgObj then bgObj.CFrame = cf end
		end
	elseif m == "CFrame" or m == "NoClip" then
		r.AssemblyLinearVelocity = Vector3.zero
		r.CFrame = flatCF(cf, r, r.Position + dir * sp * dt)
	elseif m == "SmoothCF" then
		flyVel = flyVel:Lerp(dir * sp, 1 - math.exp(-dt * 6))
		r.AssemblyLinearVelocity = Vector3.zero
		r.CFrame = flatCF(cf, r, r.Position + flyVel * dt)
	elseif m == "Lerp" then
		r.AssemblyLinearVelocity = Vector3.zero
		r.CFrame = r.CFrame:Lerp(flatCF(cf, r, r.Position + dir * sp * 0.1), 1 - math.exp(-dt * 10))
	elseif m == "Tween" then
		stepAcc += dt
		r.AssemblyLinearVelocity = Vector3.zero
		if stepAcc >= 0.1 then
			stepAcc = 0
			if dir.Magnitude > 0.01 then
				TweenService:Create(r, TWEEN_INFO, { CFrame = flatCF(cf, r, r.Position + dir * sp * 0.1) }):Play()
			end
		end
	elseif m == "Blink" then
		stepAcc += dt
		r.AssemblyLinearVelocity = Vector3.zero
		if stepAcc >= 0.25 then
			stepAcc = 0
			if dir.Magnitude > 0.01 then
				r.CFrame = flatCF(cf, r, r.Position + dir * sp * 0.25)
			end
		end
	elseif m == "Safe" then
		r.AssemblyLinearVelocity = dir * sp
	elseif m == "VectorForce" then
		if vfObj then
			vfObj.Force = r.AssemblyMass * (Vector3.new(0, workspace.Gravity, 0) + 6 * (dir * sp - r.AssemblyLinearVelocity))
		end
	elseif m == "AlignPos" then
		if apObj then
			apObj.Position = r.Position + dir * sp * 0.5
			apObj.MaxVelocity = sp
		end
		if aoObj then aoObj.CFrame = cf end
	elseif m == "BodyPos" then
		if bpObj then bpObj.Position = r.Position + dir * sp * 0.1 end
		if bgObj then bgObj.CFrame = cf end
	elseif m == "Impulse" then
		r:ApplyImpulse(r.AssemblyMass * (dir * sp - r.AssemblyLinearVelocity) * math.min(1, dt * 8))
	elseif m == "Rocket" then
		flyVel = (flyVel + dir * sp * dt * 2.5) * math.max(0, 1 - dt)
		if flyVel.Magnitude > sp * 1.5 then flyVel = flyVel.Unit * sp * 1.5 end
		r.AssemblyLinearVelocity = flyVel
	elseif m == "Hover" then
		hoverY += v * sp * 0.6 * dt
		local vy = math.clamp((hoverY - r.Position.Y) * 8, -sp, sp)
		r.AssemblyLinearVelocity = Vector3.new(md.X * sp, vy, md.Z * sp)
	elseif m == "Glide" then
		local vy = upHeld and sp * 0.7 or (downHeld and -sp or -10)
		r.AssemblyLinearVelocity = Vector3.new(md.X * sp, vy, md.Z * sp)
	elseif m == "Jetpack" then
		flyVel = flyVel:Lerp(Vector3.new(md.X * sp, v * sp, md.Z * sp), 1 - math.exp(-dt * 5))
		r.AssemblyLinearVelocity = flyVel
	end
end

local function stopFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	for _, o in ipairs(flyObjs) do
		if o then o:Destroy() end
	end
	table.clear(flyObjs)
	bvObj, bgObj, lvObj, aoObj, bfObj, bpObj, apObj, vfObj = nil, nil, nil, nil, nil, nil, nil, nil
	restoreCollide()
	flyVel = Vector3.zero
	local _, h = getChar()
	if h then
		h.PlatformStand = false
		h:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function startFly()
	stopFly()
	local c, h, r = getChar()
	if not (c and h and r) then return false end
	local m = Fly.method
	local function track(o)
		table.insert(flyObjs, o)
		return o
	end
	local function newAttachment()
		local at = track(Instance.new("Attachment"))
		at.Parent = r
		return at
	end
	local function newBodyForce()
		bfObj = track(Instance.new("BodyForce"))
		bfObj.Parent = r
	end
	local function newGyro()
		bgObj = track(Instance.new("BodyGyro"))
		bgObj.MaxTorque = Vector3.one * 9e9
		bgObj.P = 1e4
		bgObj.CFrame = r.CFrame
		bgObj.Parent = r
	end
	local function newAlignOrientation(at)
		aoObj = track(Instance.new("AlignOrientation"))
		aoObj.Mode = Enum.OrientationAlignmentMode.OneAttachment
		aoObj.Attachment0 = at
		aoObj.MaxTorque = 9e9
		aoObj.Responsiveness = 40
		aoObj.CFrame = r.CFrame
		aoObj.Parent = r
	end

	if not NO_PLATFORM[m] then h.PlatformStand = true end

	if m == "Smooth" then
		bvObj = track(Instance.new("BodyVelocity"))
		bvObj.MaxForce = Vector3.one * 9e9
		bvObj.Velocity = Vector3.zero
		bvObj.Parent = r
		newGyro()
	elseif m == "Modern" then
		local at = newAttachment()
		lvObj = track(Instance.new("LinearVelocity"))
		lvObj.Attachment0 = at
		lvObj.RelativeTo = Enum.ActuatorRelativeTo.World
		lvObj.MaxForce = 9e9
		lvObj.VectorVelocity = Vector3.zero
		lvObj.Parent = r
		newAlignOrientation(at)
	elseif m == "VectorForce" then
		local at = newAttachment()
		vfObj = track(Instance.new("VectorForce"))
		vfObj.Attachment0 = at
		vfObj.RelativeTo = Enum.ActuatorRelativeTo.World
		vfObj.ApplyAtCenterOfMass = true
		vfObj.Force = Vector3.zero
		vfObj.Parent = r
	elseif m == "AlignPos" then
		local at = newAttachment()
		apObj = track(Instance.new("AlignPosition"))
		apObj.Mode = Enum.PositionAlignmentMode.OneAttachment
		apObj.Attachment0 = at
		apObj.RigidityEnabled = false
		apObj.MaxForce = 9e9
		apObj.Responsiveness = 25
		apObj.MaxVelocity = Fly.speed
		apObj.Position = r.Position
		apObj.Parent = r
		newAlignOrientation(at)
		newBodyForce()
	elseif m == "BodyPos" then
		bpObj = track(Instance.new("BodyPosition"))
		bpObj.MaxForce = Vector3.one * 9e9
		bpObj.P = 1e4
		bpObj.D = 1e3
		bpObj.Position = r.Position
		bpObj.Parent = r
		newGyro()
		newBodyForce()
	else
		newBodyForce()
	end

	hoverY = r.Position.Y
	stepAcc = 0
	flyConn = RunService.Heartbeat:Connect(flyStep)
	noclipConn = RunService.Stepped:Connect(noclipStep)
	return true
end

-- tombol naik / turun (HP)
local flyPad = create("Frame", {
	Name = "FlyPad",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(60, 128),
	Visible = false,
	Parent = screen,
})
local function padBtn(txt, y, key)
	local b = create("TextButton", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(60, 60),
		AutoButtonColor = false,
		BackgroundTransparency = 0.15,
		Text = txt,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Parent = flyPad,
	})
	reg(b, "BackgroundColor3", "item")
	reg(b, "TextColor3", "accent")
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
	local st = create("UIStroke", { Thickness = 2, Parent = b })
	reg(st, "Color", "accent")
	b.InputBegan:Connect(function(i)
		if isPointerDown(i) then
			Fly[key] = true
			tween(b, 0.1, { BackgroundTransparency = 0.6 })
		end
	end)
	b.InputEnded:Connect(function(i)
		if isPointerDown(i) then
			Fly[key] = false
			tween(b, 0.15, { BackgroundTransparency = 0.15 })
		end
	end)
end
padBtn("NAIK", 0, "up")
padBtn("TURUN", 68, "down")

local function updatePad()
	flyPad.Visible = Fly.on and Fly.pad
end

local function setFly(on)
	Fly.on = on
	Fly.up, Fly.down = false, false
	if on then
		if not startFly() then
			Fly.on = false
			notify("Karakter belum siap")
			if flyToggle then flyToggle.Set(false, true) end
		end
	else
		stopFly()
	end
	updatePad()
end

local function setLight(n)
	if n ~= nil then Fly.light = n end
	n = Fly.light
	local _, _, r = getChar()
	if not r then return end
	for _, nm in ipairs({ "WarpahGlow", "WarpahSpot" }) do
		local o = r:FindFirstChild(nm)
		if o then o:Destroy() end
	end
	if n > 0 then
		local col = Color3.fromRGB(255, 248, 220)
		local rg = Fly.lightRange
		create("PointLight", { Name = "WarpahGlow", Brightness = n * 0.8, Range = n * rg * 1.2, Color = col, Parent = r })
		if Fly.spot then
			create("SpotLight", {
				Name = "WarpahSpot", Brightness = n * 0.6, Range = n * rg * 1.5,
				Angle = math.min(60 + n * 5, 90), Face = Enum.NormalId.Front, Color = col, Parent = r,
			})
		end
	end
end

bind(player.CharacterAdded, function()
	task.wait(0.8)
	if closing then return end
	Fly.up, Fly.down = false, false
	if Fly.on then startFly() end
	setLight()
end)

table.insert(cleanupFns, function()
	Fly.on = false
	stopFly()
	Fly.light = 0
	setLight()
end)

-- ===== TAB FLY =====
do
	local p = pages["Fly"]
	addLabel(p, "Fly")
	flyToggle = addToggle(p, "Aktifkan Fly", false, function(on)
		setFly(on)
		notify(on and ("Fly ON - " .. Fly.method) or "Fly OFF")
	end)
	methodInfoRow = addInfoRow(p, "Metode aktif", Fly.method)
	addSlider(p, "Kecepatan", 5, 300, Fly.speed, function(v) Fly.speed = v end)
	addToggle(p, "NoClip (tembus tembok)", false, function(on) Fly.noclip = on end)
	addToggle(p, "Tombol Naik/Turun", true, function(on)
		Fly.pad = on
		updatePad()
	end)
	addParagraph(p, "HP: joystick maju = arah kamera, pakai tombol NAIK / TURUN di kanan layar.\nPC: WASD, Space naik, LeftShift turun, F on/off.\nPilih metode di tab Metode.")
end

-- ===== TAB METODE =====
do
	local p = pages["Metode"]
	addLabel(p, "Pilih metode fly")
	local cells = {}
	local function refreshCells()
		for name, c in pairs(cells) do
			local sel = name == Fly.method
			tween(c.name, 0.2, { TextColor3 = sel and THEME.accent or THEME.text }, Enum.EasingStyle.Quad)
			tween(c.stroke, 0.25, { Transparency = sel and 0 or 1 }, Enum.EasingStyle.Quad)
		end
	end
	for _, mt in ipairs(METHODS) do
		local name, desc = mt[1], mt[2]
		local item = card(p, 48)
		local stroke = create("UIStroke", {
			Thickness = 1.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = (name == Fly.method) and 0 or 1,
			Parent = item,
		})
		reg(stroke, "Color", "accent")
		local nm = cardText(item, name, UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 18), "text", Enum.Font.GothamBold, 13)
		regFn(nm, "TextColor3", function() return name == Fly.method and THEME.accent or THEME.text end, { "accent", "text" })
		cardText(item, desc, UDim2.new(0, 12, 0, 25), UDim2.new(1, -24, 0, 16), "subtext", Enum.Font.Gotham, 11)
		local hit = create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = item,
		})
		local s = create("UIScale", { Parent = item })
		pressEffect(hit, s)
		hit.Activated:Connect(function()
			Fly.method = name
			if Fly.on then startFly() end
			if methodInfoRow then methodInfoRow.Set(name) end
			refreshCells()
			notify("Metode fly: " .. name)
		end)
		cells[name] = { name = nm, stroke = stroke }
	end
end

-- ===== TAB CAHAYA =====
do
	local p = pages["Cahaya"]
	addLabel(p, "Cahaya tubuh")
	addSlider(p, "Kecerahan", 0, 10, 0, function(v) setLight(v) end)
	addSlider(p, "Jangkauan", 1, 30, Fly.lightRange, function(v)
		Fly.lightRange = v
		setLight()
	end)
	addToggle(p, "Senter (SpotLight)", true, function(on)
		Fly.spot = on
		setLight()
	end)
	addParagraph(p, "Cahaya menempel di karakter dan ikut menyala lagi setelah respawn.")
end

local frames, acc = 0, 0
bind(RunService.RenderStepped, function(dt)
	frames += 1
	acc += dt
	if acc >= 0.5 then
		fpsTitle.Text = "FPS: " .. round(frames / acc)
		local ok, ping = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		pingTitle.Text = ok and ("Ping: " .. round(ping) .. " ms") or "Ping: -"
		frames, acc = 0, 0
	end
end)

selectTab("Fly")
screen.Parent = guiParent

ready = true
main.Visible = true
tween(scale, 0.55, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
tween(main, 0.4, { GroupTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
task.delay(0.5, function() notify(WINDOW_TITLE .. " siap") end)
print("Warpah Fly Loaded")