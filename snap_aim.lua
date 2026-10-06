-- AimSkill.client.lua
-- Snap Aim + Prediction Marker (только по горизонтали)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

--------------------------------------------------------------------
-- КОНФИГ
--------------------------------------------------------------------
local Config = {
	FOVRadius       = 150,
	FOVColor        = Color3.fromRGB(0, 255, 170),
	FOVThickness    = 2,
	FOVTransparency = 0.4,
	ShowFOV         = true,
	ShowMarker      = true,
	MarkerColor     = Color3.fromRGB(255, 100, 100),
	MarkerSize      = 20,
	MaxDistance     = 300,
	TargetPart      = "Head",
	WallCheck       = false,
	TeamCheck       = true,
	OnlyWithTarget  = true,
	BlockMouse      = true,
	HoldTime        = 0.35,

	-- Предугадывание
	LeadThreshold   = 10,
	LeadAmount      = 50,

	MenuKey         = Enum.KeyCode.RightControl,
}

local SkillBinds = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.R] = true,
	[Enum.KeyCode.F] = true,
	[Enum.KeyCode.C] = true,
}

--------------------------------------------------------------------
-- FOV КРУГ
--------------------------------------------------------------------
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "FovGui"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local fovFrame = Instance.new("Frame")
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Active = false
fovFrame.Selectable = false
fovFrame.Parent = fovGui
Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = Config.FOVThickness
fovStroke.Color = Config.FOVColor
fovStroke.Transparency = Config.FOVTransparency
fovStroke.Parent = fovFrame

local function updateFOV()
	local vp = Camera.ViewportSize
	fovFrame.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
	fovFrame.Size = UDim2.fromOffset(Config.FOVRadius * 2, Config.FOVRadius * 2)
	fovFrame.Visible = Config.ShowFOV
	fovStroke.Color = Config.FOVColor
	fovStroke.Thickness = Config.FOVThickness
	fovStroke.Transparency = Config.FOVTransparency
end

--------------------------------------------------------------------
-- МАРКЕР
--------------------------------------------------------------------
local markerGui = Instance.new("ScreenGui")
markerGui.Name = "MarkerGui"
markerGui.ResetOnSpawn = false
markerGui.IgnoreGuiInset = true
markerGui.DisplayOrder = 5
markerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local marker = Instance.new("Frame")
marker.Size = UDim2.fromOffset(Config.MarkerSize, Config.MarkerSize)
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.BackgroundTransparency = 1
marker.BorderSizePixel = 0
marker.Visible = false
marker.Parent = markerGui
Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)

local markerStroke = Instance.new("UIStroke", marker)
markerStroke.Thickness = 2
markerStroke.Color = Config.MarkerColor
markerStroke.Transparency = 0.2

local markerDot = Instance.new("Frame")
markerDot.Size = UDim2.fromOffset(4, 4)
markerDot.AnchorPoint = Vector2.new(0.5, 0.5)
markerDot.Position = UDim2.fromScale(0.5, 0.5)
markerDot.BackgroundColor3 = Config.MarkerColor
markerDot.BorderSizePixel = 0
markerDot.Parent = marker
Instance.new("UICorner", markerDot).CornerRadius = UDim.new(1, 0)

--------------------------------------------------------------------
-- МЕНЮ
--------------------------------------------------------------------
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "MenuGui"
menuGui.ResetOnSpawn = false
menuGui.IgnoreGuiInset = true
menuGui.DisplayOrder = 10
menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menu = Instance.new("Frame")
menu.Size = UDim2.fromOffset(280, 380)
menu.Position = UDim2.new(0, 20, 0.5, -190)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menu.BorderSizePixel = 0
menu.Active = false
menu.Draggable = false
menu.Parent = menuGui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)
local mStroke = Instance.new("UIStroke", menu)
mStroke.Color = Color3.fromRGB(60, 60, 70)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = true
closeBtn.Parent = menu
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
openBtn.BorderSizePixel = 0
openBtn.Text = "AIM"
openBtn.TextColor3 = Color3.fromRGB(0, 255, 170)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Visible = false
openBtn.Parent = menuGui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", openBtn)
openStroke.Color = Color3.fromRGB(0, 255, 170)

closeBtn.MouseButton1Click:Connect(function()
	menu.Visible = false
	openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
	menu.Visible = true
	openBtn.Visible = false
end)

local draggingOpen = false
local openDragStart, openStartPos
openBtn.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		draggingOpen = true
		openDragStart = input.Position
		openStartPos = openBtn.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingOpen = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingOpen then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		local d = input.Position - openDragStart
		openBtn.Position = UDim2.new(
			openStartPos.X.Scale, openStartPos.X.Offset + d.X,
			openStartPos.Y.Scale, openStartPos.Y.Offset + d.Y)
	end
end)

local title = Instance.new("TextButton")
title.Size = UDim2.new(1, -36, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
title.BorderSizePixel = 0
title.Text = "  DASH AIM"
title.TextColor3 = Color3.fromRGB(0, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.AutoButtonColor = false
title.Active = true
title.Parent = menu
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -16, 1, -44)
list.Position = UDim2.new(0, 8, 0, 40)
list.BackgroundTransparency = 1
list.Parent = menu
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local isDraggingMenu, isDraggingSlider = false, false
local dragStart, startPos

title.InputBegan:Connect(function(input, gpe)
	if gpe or isDraggingSlider then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingMenu = true
		dragStart = input.Position
		startPos = menu.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				isDraggingMenu = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not isDraggingMenu or isDraggingSlider then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		local d = input.Position - dragStart
		menu.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingMenu = false
	end
end)

local function makeToggle(text, key, order)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = true
	row.LayoutOrder = order
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local state = Instance.new("TextLabel")
	state.Size = UDim2.new(0, 50, 1, 0)
	state.Position = UDim2.new(1, -55, 0, 0)
	state.BackgroundTransparency = 1
	state.Text = Config[key] and "ON" or "OFF"
	state.TextColor3 = Config[key] and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(200, 80, 80)
	state.Font = Enum.Font.GothamBold
	state.TextSize = 12
	state.Parent = row

	row.MouseButton1Click:Connect(function()
		Config[key] = not Config[key]
		state.Text = Config[key] and "ON" or "OFF"
		state.TextColor3 = Config[key] and Color3.fromRGB(0, 255, 170) or Color3.fromRGB(200, 80, 80)
	end)
end

local function makeSlider(text, key, min, max, order, onChanged)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 18)
	label.Position = UDim2.new(0, 10, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. tostring(Config[key])
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, -20, 0, 6)
	bar.Position = UDim2.new(0, 10, 1, -14)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Active = true
	bar.Parent = row
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local function update(input)
		local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = math.floor(min + (max - min) * rel)
		Config[key] = v
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = text .. ": " .. tostring(v)
		if onChanged then onChanged(v) end
	end

	bar.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			isDraggingSlider = true
			update(input)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					isDraggingSlider = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			update(input)
		end
	end)
end

local function makeSliderFloat(text, key, min, max, order, onChanged)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 0, 18)
	label.Position = UDim2.new(0, 10, 0, 2)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. string.format("%.2f", Config[key])
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, -20, 0, 6)
	bar.Position = UDim2.new(0, 10, 1, -14)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Active = true
	bar.Parent = row
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local function update(input)
		local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = min + (max - min) * rel
		Config[key] = v
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = text .. ": " .. string.format("%.2f", v)
		if onChanged then onChanged(v) end
	end

	bar.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			isDraggingSlider = true
			update(input)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					isDraggingSlider = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			update(input)
		end
	end)
end

makeToggle("Show FOV", "ShowFOV", 1)
makeToggle("Show marker", "ShowMarker", 2)
makeToggle("Wall check", "WallCheck", 3)
makeToggle("Team check", "TeamCheck", 4)
makeToggle("Only with target", "OnlyWithTarget", 5)
makeToggle("Block mouse", "BlockMouse", 6)
makeSlider("FOV radius", "FOVRadius", 20, 500, 7, updateFOV)
makeSlider("Max distance", "MaxDistance", 50, 1000, 8)
makeSliderFloat("Hold time", "HoldTime", 0.05, 0.8, 9)
makeSlider("Lead threshold", "LeadThreshold", 1, 60, 10)
makeSlider("Lead amount", "LeadAmount", 0, 150, 11)

--------------------------------------------------------------------
-- Поиск цели
--------------------------------------------------------------------
local function getTargetPart(char)
	return char:FindFirstChild(Config.TargetPart) or char:FindFirstChild("HumanoidRootPart")
end

local function isAlly(p)
	if not Config.TeamCheck then return false end
	return p.Team ~= nil and p.Team == LocalPlayer.Team
end

local function hasLOS(part)
	if not Config.WallCheck then return true end
	local origin = Camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
	local hit = workspace:Raycast(origin, part.Position - origin, params)
	return hit == nil or hit.Instance:IsDescendantOf(part.Parent)
end

local function getBestTarget()
	local best, bestScore = nil, math.huge
	local center = Camera.ViewportSize / 2
	local camPos = Camera.CFrame.Position

	for _, p in Players:GetPlayers() do
		if p == LocalPlayer or isAlly(p) then continue end
		local char = p.Character
		if not char then continue end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end

		local part = getTargetPart(char)
		if not part then continue end

		local dist = (part.Position - camPos).Magnitude
		if dist > Config.MaxDistance then continue end

		local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end

		local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
		if screenDist > Config.FOVRadius then continue end

		if not hasLOS(part) then continue end

		local score = screenDist + dist * 0.5
		if score < bestScore then
			bestScore = score
			best = part
		end
	end
	return best
end

--------------------------------------------------------------------
-- ПРЕДУГАДЫВАНИЕ (только по горизонтали)
--------------------------------------------------------------------
local lastPos = {}
local lastTime = {}

local function predictPosition(part)
	if not part or not part.Parent then return part.Position end

	local id = part:GetFullName()
	local now = tick()
	local vel = Vector3.zero

	if lastPos[id] and lastTime[id] then
		local dt = now - lastTime[id]
		if dt > 0.001 then
			vel = (part.Position - lastPos[id]) / dt
		end
	end

	lastPos[id] = part.Position
	lastTime[id] = now

	-- Стоит — маркер на игроке
	if vel.Magnitude < Config.LeadThreshold then
		return part.Position
	end

	-- Двигается — сдвиг ТОЛЬКО по горизонтали (X, Z)
	local flatDir = Vector3.new(vel.X, 0, vel.Z)
	if flatDir.Magnitude < 0.01 then
		return part.Position
	end
	flatDir = flatDir.Unit

	local offset = flatDir * Config.LeadAmount
	return Vector3.new(
		part.Position.X + offset.X,
		part.Position.Y,
		part.Position.Z + offset.Z
	)
end

--------------------------------------------------------------------
-- МАРКЕР (обновляется каждый кадр)
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not Config.ShowMarker then
		marker.Visible = false
		return
	end

	local target = getBestTarget()
	if not target then
		marker.Visible = false
		return
	end

	local predictedPos = predictPosition(target)
	local sp, onScreen = Camera:WorldToViewportPoint(predictedPos)
	if not onScreen then
		marker.Visible = false
		return
	end

	marker.Position = UDim2.fromOffset(sp.X, sp.Y)
	marker.Size = UDim2.fromOffset(Config.MarkerSize, Config.MarkerSize)
	markerStroke.Color = Config.MarkerColor
	markerDot.BackgroundColor3 = Config.MarkerColor
	marker.Visible = true
end)

--------------------------------------------------------------------
-- SNAP КАМЕРЫ
--------------------------------------------------------------------
local snapTarget = nil
local snapUntil = 0
local savedCFrame = nil
local savedMouseBehavior = nil

local function startSnap(part)
	snapTarget = part
	snapUntil = tick() + Config.HoldTime
	savedCFrame = Camera.CFrame

	if Config.BlockMouse then
		savedMouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

local function stopSnap()
	snapTarget = nil
	snapUntil = 0
	if savedCFrame then
		Camera.CFrame = savedCFrame
		savedCFrame = nil
	end
	if Config.BlockMouse and savedMouseBehavior then
		UserInputService.MouseBehavior = savedMouseBehavior
		savedMouseBehavior = nil
	end
end

RunService:BindToRenderStep("AimSnap", Enum.RenderPriority.Camera.Value + 1000, function()
	if not snapTarget then return end
	if not snapTarget.Parent then
		stopSnap()
		return
	end
	if tick() > snapUntil then
		stopSnap()
		return
	end

	local targetPos = predictPosition(snapTarget)
	Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
end)

--------------------------------------------------------------------
-- ХОТКЕИ СКИЛЛОВ
--------------------------------------------------------------------
local busy = false

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Config.MenuKey then
		menu.Visible = not menu.Visible
		openBtn.Visible = not menu.Visible
		return
	end

	if not SkillBinds[input.KeyCode] then return end
	if busy then return end

	local target = getBestTarget()
	if not target then return end

	busy = true
	startSnap(target)
	task.wait(Config.HoldTime + 0.05)
	busy = false
end)

--------------------------------------------------------------------
-- Рендер кружка
--------------------------------------------------------------------
RunService.RenderStepped:Connect(updateFOV)
