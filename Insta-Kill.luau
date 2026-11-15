--!strict
-- ============================================================================
-- CIPHER // INSTA-KILL BURST ENGINE V5.0 (MODERN RESCRIPT)
-- High-Performance Proximity Eliminator with Smart Burst & Lightweight UI
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

local RANGE: number           = 50
local RANGE_SQ: number        = RANGE * RANGE
local TOUCH_BURST: number     = 3      -- 3 double-tap pairs per priority part is optimal & zero-lag
local REMOTE_BURST: number    = 2      -- 2 remote dispatches per cycle prevents server queue drops
local ATTACK_INTERVAL: number = 1 / 30 -- 30 Hz smooth tick loop
local TOGGLE_KEY: Enum.KeyCode = Enum.KeyCode.K
local Active: boolean         = true

-- State
local toolList: { Tool }                   = {}
local touchCache: { [Tool]: BasePart }     = {}
local remoteCache: { [Tool]: RemoteEvent } = {}

local currentTargetPlayer: Player?         = nil
local currentTargetHum: Humanoid?          = nil
local currentTargetRoot: BasePart?         = nil
local currentPriorityParts: { BasePart }   = {}
local lastAttackTime: number               = 0

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
local existing = guiContainer:FindFirstChild("CipherInstaKillUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherInstaKillUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 68)
MainCard.Position = UDim2.new(0.5, -115, 0.09, 0)
MainCard.BackgroundColor3 = THEME.BgPrimary
MainCard.BackgroundTransparency = 0.08
MainCard.BorderSizePixel = 0
MainCard.Active = true
MainCard.Parent = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 8)
CardCorner.Parent = MainCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1
CardStroke.Color = THEME.Border
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Parent = MainCard

-- Header / Drag Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 22)
Header.BackgroundColor3 = THEME.BgCard
Header.BorderSizePixel = 0
Header.Parent = MainCard

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
HeaderTitle.Text = "⚡ INSTA-KILL // BURST ENGINE [K]"
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

-- Interactive Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -14, 0, 24)
ToggleButton.Position = UDim2.new(0, 7, 0, 25)
ToggleButton.BackgroundColor3 = THEME.BgCard
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 10
ToggleButton.TextColor3 = THEME.ActiveGreen
ToggleButton.Text = "BURST: ARMED // 30Hz"
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = MainCard

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleButton

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Thickness = 1
BtnStroke.Color = THEME.Border
BtnStroke.Transparency = 0.5
BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BtnStroke.Parent = ToggleButton

-- Target Status Label
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -14, 0, 16)
TargetLabel.Position = UDim2.new(0, 7, 0, 50)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextSize = 9
TargetLabel.TextColor3 = THEME.TextMuted
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Text = "Target: [Searching...]"
TargetLabel.Parent = MainCard

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

setupDraggable(MainCard, Header)

-- Hover effect
ToggleButton.MouseEnter:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.12), {BackgroundColor3 = THEME.AccentDim}):Play()
end)
ToggleButton.MouseLeave:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.12), {BackgroundColor3 = THEME.BgCard}):Play()
end)

local function updateUI()
	if Active then
		ToggleButton.Text = "BURST: ARMED // 30Hz"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "BURST: STANDBY [K]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
		TargetLabel.Text = "Target: [Disabled]"
	end
end

local function toggleActive()
	Active = not Active
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(toggleActive)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleActive()
	end
end)

-- ============================================================================
-- TOOL CACHING ENGINE
-- ============================================================================
local function findFightRemote(tool: Tool): RemoteEvent?
	local r = tool:FindFirstChild("FightEvent")
	if r and r:IsA("RemoteEvent") then return r end
	for _, o in ipairs(tool:GetChildren()) do
		if o:IsA("RemoteEvent") then
			local n = string.lower(o.Name)
			if string.find(n, "fight", 1, true) or string.find(n, "slap", 1, true) or string.find(n, "event", 1, true) then
				return o
			end
		end
	end
	return nil
end

local function rebuildToolCache()
	table.clear(toolList)
	table.clear(touchCache)
	table.clear(remoteCache)

	local char = LocalPlayer.Character
	if not char then return end

	for _, o in ipairs(char:GetChildren()) do
		if o:IsA("Tool") then
			table.insert(toolList, o)

			local handle = o:FindFirstChild("Handle")
			if not (handle and handle:IsA("BasePart")) then
				handle = o:FindFirstChildWhichIsA("BasePart")
			end

			if handle and handle:IsA("BasePart") then
				touchCache[o] = handle
				handle.CanCollide = false
				handle.Massless = true
				handle.CanTouch = true
			end

			local rem = findFightRemote(o)
			if rem then
				remoteCache[o] = rem
			end
		end
	end
end

local function hookCharacter(char: Model)
	rebuildToolCache()
	char.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildToolCache)
		end
	end)
	char.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildToolCache)
		end
	end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- Priority Parts (Essential hit registry)
local PRIORITY_NAMES = { "HumanoidRootPart", "Head", "UpperTorso", "Torso", "LowerTorso" }

local function buildPriorityParts(char: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, name in ipairs(PRIORITY_NAMES) do
		local p = char:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			table.insert(parts, p)
		end
	end
	return parts
end

-- ============================================================================
-- TARGET ACQUISITION & EXECUTION ENGINE
-- ============================================================================
local function updateTarget()
	local myChar = LocalPlayer.Character
	if not myChar then
		currentTargetPlayer = nil
		currentTargetHum = nil
		currentTargetRoot = nil
		table.clear(currentPriorityParts)
		return
	end

	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not (myRoot and myRoot:IsA("BasePart")) then
		currentTargetPlayer = nil
		currentTargetHum = nil
		currentTargetRoot = nil
		table.clear(currentPriorityParts)
		return
	end

	local myPos = myRoot.Position
	local closestPlayer: Player? = nil
	local closestRoot: BasePart? = nil
	local closestHum: Humanoid? = nil
	local closestDistSq: number = RANGE_SQ

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local pChar = player.Character
			if pChar then
				local hum = pChar:FindFirstChildOfClass("Humanoid")
				local pRoot = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Torso")
				if hum and hum.Health > 0 and pRoot and pRoot:IsA("BasePart") then
					local diff = pRoot.Position - myPos
					local dsq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z
					if dsq < closestDistSq then
						closestDistSq = dsq
						closestPlayer = player
						closestRoot = pRoot
						closestHum = hum
					end
				end
			end
		end
	end

	if closestPlayer and closestPlayer.Character then
		currentTargetPlayer = closestPlayer
		currentTargetHum = closestHum
		currentTargetRoot = closestRoot
		currentPriorityParts = buildPriorityParts(closestPlayer.Character)
		TargetLabel.Text = string.format("Target: %s (%.1fm)", closestPlayer.DisplayName, math.sqrt(closestDistSq))
		TargetLabel.TextColor3 = THEME.Accent
	else
		currentTargetPlayer = nil
		currentTargetHum = nil
		currentTargetRoot = nil
		table.clear(currentPriorityParts)
		TargetLabel.Text = "Target: [Searching...]"
		TargetLabel.TextColor3 = THEME.TextMuted
	end
end

local function executeBurst()
	if not currentTargetPlayer or not currentTargetHum or currentTargetHum.Health <= 0 then
		return
	end

	-- Tool Activation & Remote Bursts
	for i = 1, #toolList do
		local tool = toolList[i]
		if tool and tool.Parent then
			pcall(tool.Activate, tool)

			local rem = remoteCache[tool]
			local root = currentTargetRoot
			if rem and root and rem.Parent then
				for _ = 1, REMOTE_BURST do
					pcall(rem.FireServer, rem, root)
				end
			end

			-- Touch Interest Burst
			if fireTouch then
				local touch = touchCache[tool]
				if touch and touch.Parent then
					for p = 1, #currentPriorityParts do
						local targetPart = currentPriorityParts[p]
						if targetPart and targetPart.Parent then
							for _ = 1, TOUCH_BURST do
								pcall(fireTouch, touch, targetPart, 0)
								pcall(fireTouch, touch, targetPart, 1)
							end
						end
					end
				end
			end
		end
	end
end

-- Main tick connection (Smooth 30 Hz loop)
RunService.Heartbeat:Connect(function()
	if not Active then return end

	local now = os.clock()
	if now - lastAttackTime < ATTACK_INTERVAL then return end
	lastAttackTime = now

	updateTarget()
	if currentTargetPlayer then
		executeBurst()
	end
end)

updateUI()
print("[Insta-Kill] CIPHER // INSTA-KILL BURST ENGINE V5.0 Loaded.")
