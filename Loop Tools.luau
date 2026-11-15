--!strict
-- ============================================================================
-- CIPHER // LOOP TOOLS V5.0 (MODERN RESCRIPT)
-- High-Speed Tool Attachment & Target Follower with Clean Dropdown UI
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Executor API Resolver
local fireTouch: ((BasePart, BasePart, number) -> ())? = (firetouchinterest :: any)
	or (getgenv and (getgenv().firetouchinterest or getgenv().fire_touch_interest))
	or (syn and syn.firetouchinterest)

-- ============================================================================
-- THEME & CONFIGURATION
-- ============================================================================
local THEME = {
	BgPrimary   = Color3.fromRGB(13, 14, 18),
	BgCard      = Color3.fromRGB(20, 22, 28),
	Accent      = Color3.fromRGB(255, 45, 70),
	AccentHover = Color3.fromRGB(255, 75, 98),
	AccentDim   = Color3.fromRGB(70, 18, 26),
	ActiveGreen = Color3.fromRGB(46, 213, 115),
	Border      = Color3.fromRGB(255, 45, 70),
	BorderDim   = Color3.fromRGB(45, 48, 58),
	TextMain    = Color3.fromRGB(240, 242, 248),
	TextMuted   = Color3.fromRGB(130, 135, 150),
}

local TOGGLE_KEY = Enum.KeyCode.L
local FollowOffset = Vector3.new(0, 0.6, 0)
local AvoidCollisionOffset = Vector3.new(0, 0, 0.4)
local TICK_INTERVAL = 1 / 45 -- 45 Hz tick for smooth positioning without physics hitching

local targetPlayers: { [string]: boolean } = {}
local cachedToolParts: { BasePart } = {}
local Active: boolean = true

-- ============================================================================
-- SAFE GUI RESOLVER
-- ============================================================================
local function getGuiContainer(): Instance
	local success, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if success and core then
		local canWrite = pcall(function()
			local test = Instance.new("Folder")
			test.Parent = core
			test:Destroy()
		end)
		if canWrite then
			return core
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local guiContainer = getGuiContainer()
local existing = guiContainer:FindFirstChild("CipherLoopToolsUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherLoopToolsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(250, 36)
MainCard.Position = UDim2.new(1, -260, 0.35, 0)
MainCard.BackgroundColor3 = THEME.BgPrimary
MainCard.BackgroundTransparency = 0.08
MainCard.BorderSizePixel = 0
MainCard.Active = true
MainCard.ClipsDescendants = false
MainCard.Parent = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 8)
CardCorner.Parent = MainCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1
CardStroke.Color = THEME.Border
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Parent = MainCard

-- Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, -8, 0, 28)
Header.Position = UDim2.new(0, 4, 0, 4)
Header.BackgroundTransparency = 1
Header.Parent = MainCard

local HeaderLayout = Instance.new("UIListLayout")
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HeaderLayout.Padding = UDim.new(0, 4)
HeaderLayout.Parent = Header

local function createHeaderButton(text: string, width: number, order: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width, 0, 26)
	btn.BackgroundColor3 = THEME.BgCard
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = Header

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.Color = THEME.BorderDim
	s.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.AccentDim}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.BgCard}):Play()
	end)

	return btn
end

local ToggleButton = createHeaderButton("⚡ LOOP TOOLS [L]", 136, 1)
local SelectAllBtn  = createHeaderButton("ALL", 48, 2)
local ClearAllBtn   = createHeaderButton("CLR", 48, 3)

ToggleButton.TextColor3 = THEME.Accent

-- Dropdown Roster Panel
local DropPanel = Instance.new("Frame")
DropPanel.Name = "DropPanel"
DropPanel.Size = UDim2.new(1, 0, 0, 0)
DropPanel.Position = UDim2.new(0, 0, 0, 42)
DropPanel.BackgroundColor3 = THEME.BgPrimary
DropPanel.BackgroundTransparency = 0.05
DropPanel.BorderSizePixel = 0
DropPanel.ClipsDescendants = true
DropPanel.Visible = false
DropPanel.Parent = MainCard

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 8)
DropCorner.Parent = DropPanel

local DropStroke = Instance.new("UIStroke")
DropStroke.Thickness = 1
DropStroke.Color = THEME.Border
DropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DropStroke.Parent = DropPanel

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -12, 1, -12)
ScrollList.Position = UDim2.new(0, 6, 0, 6)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 3
ScrollList.ScrollBarImageColor3 = THEME.Accent
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.Parent = DropPanel

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Parent = ScrollList

-- Draggable implementation
local function setupDraggable(targetFrame: Frame, dragAnchor: Frame)
	local dragging = false
	local dragStartPos = Vector2.zero
	local frameStartPos = UDim2.new()

	dragAnchor.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
			frameStartPos = targetFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
			targetFrame.Position = UDim2.new(
				frameStartPos.X.Scale,
				frameStartPos.X.Offset + delta.X,
				frameStartPos.Y.Scale,
				frameStartPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

setupDraggable(MainCard, MainCard)

-- Dropdown Toggle
local isPanelOpen = false
local function togglePanel()
	isPanelOpen = not isPanelOpen
	local targetSize = isPanelOpen and UDim2.new(1, 0, 0, 190) or UDim2.new(1, 0, 0, 0)

	if isPanelOpen then
		DropPanel.Visible = true
	end

	local tween = TweenService:Create(DropPanel, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize})
	tween:Play()
	tween.Completed:Connect(function()
		if not isPanelOpen then
			DropPanel.Visible = false
		end
	end)
end

local function updateUI()
	if Active then
		ToggleButton.TextColor3 = THEME.ActiveGreen
		ToggleButton.Text = "⚡ LOOP TOOLS: ON"
		CardStroke.Color = THEME.Border
	else
		ToggleButton.TextColor3 = THEME.TextMuted
		ToggleButton.Text = "⚡ LOOP TOOLS: OFF [L]"
		CardStroke.Color = THEME.BorderDim
	end
end

local function toggleActive()
	Active = not Active
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(togglePanel)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleActive()
	end
end)

-- ============================================================================
-- TOOL CACHING ENGINE
-- ============================================================================
local function updateToolCache()
	table.clear(cachedToolParts)
	local char = LocalPlayer.Character
	if not char then return end

	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
			if handle and handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Massless = true
				handle.CanTouch = true
				if not table.find(cachedToolParts, handle) then
					table.insert(cachedToolParts, handle)
				end
			end
		end
	end
end

local function hookCharacter(char: Model)
	updateToolCache()
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.defer(updateToolCache) end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.defer(updateToolCache) end end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- ============================================================================
-- PLAYER ROSTER CONTROLS
-- ============================================================================
local function updatePlayerList()
	for _, child in ipairs(ScrollList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local isTargeted = targetPlayers[player.Name] == true

			local btn = Instance.new("TextButton")
			btn.Name = player.Name
			btn.Size = UDim2.new(1, -4, 0, 24)
			btn.BackgroundColor3 = isTargeted and THEME.AccentDim or THEME.BgCard
			btn.TextColor3 = isTargeted and THEME.Accent or THEME.TextMain
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 10
			btn.AutoButtonColor = false
			btn.Text = (isTargeted and "★ " or "") .. player.DisplayName .. (isTargeted and " [FOLLOWING]" or "")
			btn.Parent = ScrollList

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent = btn

			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = isTargeted and THEME.Border or THEME.BorderDim
			s.Parent = btn

			btn.MouseButton1Click:Connect(function()
				if targetPlayers[player.Name] then
					targetPlayers[player.Name] = nil
				else
					targetPlayers[player.Name] = true
				end
				updatePlayerList()
			end)
		end
	end
end

SelectAllBtn.MouseButton1Click:Connect(function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			targetPlayers[p.Name] = true
		end
	end
	updatePlayerList()
end)

ClearAllBtn.MouseButton1Click:Connect(function()
	table.clear(targetPlayers)
	updatePlayerList()
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(player: Player)
	targetPlayers[player.Name] = nil
	updatePlayerList()
end)

updatePlayerList()

-- ============================================================================
-- TOOL FOLLOW EXECUTION
-- ============================================================================
local lastFollowTick: number = 0

local function moveToolsToTarget(targetChar: Model)
	local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("HumanoidRootPart")
	if not (torso and torso:IsA("BasePart")) then return end

	local targetPos = torso.Position + FollowOffset + AvoidCollisionOffset

	for i = 1, #cachedToolParts do
		local part = cachedToolParts[i]
		if part and part.Parent then
			part.Position = targetPos

			if fireTouch then
				local hrp = targetChar:FindFirstChild("HumanoidRootPart")
				for _ = 1, 2 do
					pcall(fireTouch, part, torso, 0)
					pcall(fireTouch, part, torso, 1)
					if hrp and hrp:IsA("BasePart") then
						pcall(fireTouch, part, hrp, 0)
						pcall(fireTouch, part, hrp, 1)
					end
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	if not Active then return end
	if not next(targetPlayers) then return end
	if #cachedToolParts == 0 then return end

	local now = os.clock()
	if now - lastFollowTick < TICK_INTERVAL then return end
	lastFollowTick = now

	for name, isTargeted in pairs(targetPlayers) do
		if isTargeted then
			local plr = Players:FindFirstChild(name)
			if plr and plr:IsA("Player") and plr.Character then
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					moveToolsToTarget(plr.Character)
				end
			end
		end
	end
end)

updateUI()
print("[Loop Tools] CIPHER // LOOP TOOLS V5.0 Loaded.")
