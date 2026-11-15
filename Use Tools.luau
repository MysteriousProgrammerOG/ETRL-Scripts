--!strict
-- ============================================================================
-- CIPHER // USE TOOLS & COMBAT ENGINE V6.0 (MODERN RESCRIPT)
-- High-Performance Multi-Tool Auto-Equipper, Rapid Activator & Proximity Assist
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

-- Settings
local APS: number                = 60      -- Activations per second (10 - 200)
local MAX_TOOLS: number          = 5       -- Concurrent equipped tools (1 - 10)
local TOUCH_ASSIST_RANGE: number = 24
local TOUCH_ASSIST_SQ: number    = TOUCH_ASSIST_RANGE * TOUCH_ASSIST_RANGE

-- Modes: "Normal" (Activate only), "Event" (Remote only), "Max" (Both)
local MODES = { "Normal", "Event", "Max" }
local currentModeIndex: number = 1
local Mode: string = "Normal"
local Active: boolean = true

local KEY_TOGGLE: Enum.KeyCode = Enum.KeyCode.E
local KEY_MODE: Enum.KeyCode   = Enum.KeyCode.F

-- Cache & State
type CachedTool = {
	Tool: Tool,
	Handle: BasePart?,
	Remote: RemoteEvent?,
}

local equippedCache: { CachedTool } = {}
local isEquipping: boolean = false
local pulseAccumulator: number = 0

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
local existing = guiContainer:FindFirstChild("CipherUseToolsUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherUseToolsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.fromOffset(230, 178)
MainPanel.Position = UDim2.new(1, -245, 0.45, -89)
MainPanel.BackgroundColor3 = THEME.BgPrimary
MainPanel.BackgroundTransparency = 0.08
MainPanel.BorderSizePixel = 0
MainPanel.Active = true
MainPanel.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainPanel

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = THEME.Border
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainPanel

-- Header / Drag Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 22)
Header.BackgroundColor3 = THEME.BgCard
Header.BorderSizePixel = 0
Header.Parent = MainPanel

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -24, 1, 0)
HeaderTitle.Position = UDim2.new(0, 8, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 10
HeaderTitle.TextColor3 = THEME.Accent
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Text = "⚡ USE TOOLS // COMBAT [E]"
HeaderTitle.Parent = Header

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(7, 7)
StatusDot.Position = UDim2.new(1, -14, 0.5, -3)
StatusDot.BackgroundColor3 = THEME.ActiveGreen
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Header

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

-- Content Stack
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -14, 1, -30)
Content.Position = UDim2.new(0, 7, 0, 26)
Content.BackgroundTransparency = 1
Content.Parent = MainPanel

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 4)
ContentLayout.Parent = Content

-- Button Helper
local function createButton(text: string, height: number, order: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, height)
	btn.BackgroundColor3 = THEME.BgCard
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = Content

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
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

-- Primary Toggle Button
local ToggleButton = createButton("STATUS: ACTIVE", 24, 1)
ToggleButton.TextColor3 = THEME.ActiveGreen

-- Mode Selector Button
local ModeButton = createButton("MODE: NORMAL [F]", 22, 2)

-- Stepper Row Factory
local function createStepperRow(title: string, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = THEME.BgCard
	row.LayoutOrder = order
	row.Parent = Content

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 5)
	rc.Parent = row

	local rs = Instance.new("UIStroke")
	rs.Thickness = 1
	rs.Color = THEME.BorderDim
	rs.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.Position = UDim2.new(0, 6, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = title
	label.Parent = row

	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.new(0, 20, 0, 18)
	minusBtn.Position = UDim2.new(0.52, 0, 0.5, -9)
	minusBtn.BackgroundColor3 = THEME.BgPrimary
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 12
	minusBtn.TextColor3 = THEME.Accent
	minusBtn.Text = "-"
	minusBtn.AutoButtonColor = false
	minusBtn.Parent = row
	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 4)
	mc.Parent = minusBtn

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0.24, 0, 1, 0)
	valLabel.Position = UDim2.new(0.62, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.Code
	valLabel.TextSize = 10
	valLabel.TextColor3 = THEME.TextMain
	valLabel.Text = "0"
	valLabel.Parent = row

	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 20, 0, 18)
	plusBtn.Position = UDim2.new(1, -24, 0.5, -9)
	plusBtn.BackgroundColor3 = THEME.BgPrimary
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 12
	plusBtn.TextColor3 = THEME.Accent
	plusBtn.Text = "+"
	plusBtn.AutoButtonColor = false
	plusBtn.Parent = row
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 4)
	pc.Parent = plusBtn

	return valLabel, minusBtn, plusBtn
end

local APSLabel, APSMinus, APSPlus = createStepperRow("RATE (APS)", 3)
local ToolsLabel, ToolsMinus, ToolsPlus = createStepperRow("MAX TOOLS", 4)

-- Sub-badge status
local InfoBadge = Instance.new("TextLabel")
InfoBadge.Size = UDim2.new(1, 0, 0, 16)
InfoBadge.BackgroundTransparency = 1
InfoBadge.Font = Enum.Font.Code
InfoBadge.TextSize = 9
InfoBadge.TextColor3 = THEME.TextMuted
InfoBadge.Text = "// SPAM: ACTIVE • TOUCH: ON"
InfoBadge.LayoutOrder = 5
InfoBadge.Parent = Content

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

setupDraggable(MainPanel, Header)

-- UI Sync
local function updateUI()
	if Active then
		ToggleButton.Text = "STATUS: ACTIVE"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		MainStroke.Color = THEME.Border
	else
		ToggleButton.Text = "STATUS: STANDBY [E]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		MainStroke.Color = THEME.BorderDim
	end

	Mode = MODES[currentModeIndex]
	ModeButton.Text = string.format("MODE: %s [F]", string.upper(Mode))
	APSLabel.Text = string.format("%d/s", APS)
	ToolsLabel.Text = string.format("%d", MAX_TOOLS)
end

-- ============================================================================
-- TOOL CACHING & FAST EQUIP LOGIC
-- ============================================================================
local function findFightRemote(tool: Tool): RemoteEvent?
	local r = tool:FindFirstChild("FightEvent")
	if r and r:IsA("RemoteEvent") then return r end
	for _, child in ipairs(tool:GetChildren()) do
		if child:IsA("RemoteEvent") then
			local n = string.lower(child.Name)
			if string.find(n, "fight", 1, true) or string.find(n, "slap", 1, true) or string.find(n, "hit", 1, true) then
				return child
			end
		end
	end
	return nil
end

local function sanitizeToolPhysics(tool: Tool)
	local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
	if handle and handle:IsA("BasePart") then
		handle.CanCollide = false
		handle.Massless = true
		handle.CanTouch = true
	end
end

local function rebuildEquippedCache()
	table.clear(equippedCache)
	local char = LocalPlayer.Character
	if not char then return end

	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			sanitizeToolPhysics(child)
			local handle = child:FindFirstChild("Handle") or child:FindFirstChildWhichIsA("BasePart")
			local rem = findFightRemote(child)
			table.insert(equippedCache, {
				Tool = child,
				Handle = (handle and handle:IsA("BasePart")) and handle or nil,
				Remote = rem,
			})
			if #equippedCache >= MAX_TOOLS then
				break
			end
		end
	end
end

local function fastEquipTools()
	if not Active or isEquipping then return end
	isEquipping = true

	local char = LocalPlayer.Character
	local bp = LocalPlayer:FindFirstChildOfClass("Backpack")

	if char and bp then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local equippedCount = 0
			for _, c in ipairs(char:GetChildren()) do
				if c:IsA("Tool") then
					equippedCount += 1
				end
			end

			-- Move tools from Backpack to Character
			if equippedCount < MAX_TOOLS then
				local needed = MAX_TOOLS - equippedCount
				for _, tool in ipairs(bp:GetChildren()) do
					if tool:IsA("Tool") then
						sanitizeToolPhysics(tool)
						tool.Parent = char
						needed -= 1
						if needed <= 0 then break end
					end
				end
			end
		end
	end

	rebuildEquippedCache()
	isEquipping = false
end

-- FastEquip Hook for Respawn synergy
_G.Guide = fastEquipTools
_G.FastEquip = fastEquipTools
if typeof(getgenv) == "function" then
	pcall(function()
		getgenv().Guide = fastEquipTools
	end)
end

-- ============================================================================
-- ATTACK PULSE & PROXIMITY TOUCH ASSIST
-- ============================================================================
local function pulseCombat()
	local char = LocalPlayer.Character
	if not char or #equippedCache == 0 then return end

	-- 1. Tool Activation & Remote Dispatch
	for i = 1, #equippedCache do
		local entry = equippedCache[i]
		local tool = entry.Tool
		if tool and tool.Parent == char then
			if Mode == "Normal" or Mode == "Max" then
				pcall(tool.Activate, tool)
			end
			if (Mode == "Event" or Mode == "Max") and entry.Remote and entry.Remote.Parent then
				pcall(entry.Remote.FireServer, entry.Remote)
			end
		end
	end

	-- 2. Proximity Touch Assist
	if fireTouch then
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		if root and root:IsA("BasePart") then
			local myPos = root.Position

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local pChar = player.Character
					if pChar then
						local hum = pChar:FindFirstChildOfClass("Humanoid")
						local pRoot = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Torso")
						if hum and hum.Health > 0 and pRoot and pRoot:IsA("BasePart") then
							local diff = pRoot.Position - myPos
							if (diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z) <= TOUCH_ASSIST_SQ then
								for i = 1, #equippedCache do
									local handle = equippedCache[i].Handle
									if handle and handle.Parent then
										pcall(fireTouch, handle, pRoot, 0)
										pcall(fireTouch, handle, pRoot, 1)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Smooth delta-accumulated clock loop
RunService.Heartbeat:Connect(function(dt: number)
	if not Active then return end

	pulseAccumulator += dt
	local targetInterval = 1 / math.clamp(APS, 10, 200)

	if pulseAccumulator >= targetInterval then
		pulseAccumulator %= targetInterval
		pulseCombat()
	end
end)

-- Character & Backpack monitoring
local function hookCharacter(char: Model)
	task.defer(fastEquipTools)

	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then
			rebuildEquippedCache()
		end
	end)

	char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then
			task.defer(fastEquipTools)
		end
	end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
if bp then
	bp.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then
			task.defer(fastEquipTools)
		end
	end)
end
LocalPlayer.ChildAdded:Connect(function(c)
	if c:IsA("Backpack") then
		c.ChildAdded:Connect(function(tool)
			if tool:IsA("Tool") then
				task.defer(fastEquipTools)
			end
		end)
	end
end)

-- UI Actions
local function toggleActive()
	Active = not Active
	if Active then
		fastEquipTools()
	end
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(toggleActive)

ModeButton.MouseButton1Click:Connect(function()
	currentModeIndex = (currentModeIndex % #MODES) + 1
	updateUI()
end)

APSMinus.MouseButton1Click:Connect(function()
	APS = math.clamp(APS - 10, 10, 200)
	updateUI()
end)

APSPlus.MouseButton1Click:Connect(function()
	APS = math.clamp(APS + 10, 10, 200)
	updateUI()
end)

ToolsMinus.MouseButton1Click:Connect(function()
	MAX_TOOLS = math.clamp(MAX_TOOLS - 1, 1, 10)
	fastEquipTools()
	updateUI()
end)

ToolsPlus.MouseButton1Click:Connect(function()
	MAX_TOOLS = math.clamp(MAX_TOOLS + 1, 1, 10)
	fastEquipTools()
	updateUI()
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == KEY_TOGGLE then
		toggleActive()
	elseif input.KeyCode == KEY_MODE then
		currentModeIndex = (currentModeIndex % #MODES) + 1
		updateUI()
	end
end)

updateUI()
print("[Use Tools] CIPHER // USE TOOLS COMBAT ENGINE V6.0 Loaded.")
