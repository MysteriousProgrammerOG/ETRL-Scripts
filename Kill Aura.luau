-- ============================================================================
-- CIPHER // KILL AURA V6.1 (MODERN RESCRIPT)
-- 10-Stud Melee Combat Aura Triggered on Attack/Swing (Zero-Ping Overhead)
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

-- Settings (10 Stud Radius, No Auto-Attack, Ping-Safe)
local RANGE: number            = 10     -- Exactly 10 studs as requested
local RANGE_SQ: number         = RANGE * RANGE
local TOUCH_BURST: number      = 3      -- 3 clean touch pairs per swing
local TOGGLE_KEY: Enum.KeyCode = Enum.KeyCode.X
local Active: boolean          = true

-- State
local toolParts: { BasePart } = {}
local toolRemotes: { RemoteEvent } = {}
local equippedTools: { Tool } = {}
local toolConnections: { [Tool]: RBXScriptConnection } = {}
local inRangeEnemies: { { Character: Model, Parts: { BasePart }, Root: BasePart } } = {}
local lastScanTime: number = 0

-- Priority Parts for reliable hit registration
local PRIORITY_PARTS = {
	"HumanoidRootPart",
	"Head",
	"UpperTorso",
	"Torso",
}

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
local existing = guiContainer:FindFirstChild("CipherKillAuraUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherKillAuraUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 68)
MainCard.Position = UDim2.new(0.5, -115, 0.01, 0)
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
HeaderTitle.Text = "⚡ KILL AURA // 10 STUD RADIUS [X]"
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
ToggleButton.Text = "AURA: ARMED // ON ATTACK"
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

-- Targets In Range Label
local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(1, -14, 0, 16)
CountLabel.Position = UDim2.new(0, 7, 0, 50)
CountLabel.BackgroundTransparency = 1
CountLabel.Font = Enum.Font.Gotham
CountLabel.TextSize = 9
CountLabel.TextColor3 = THEME.TextMuted
CountLabel.TextXAlignment = Enum.TextXAlignment.Left
CountLabel.Text = "In 10 stud range: 0 (No Auto-Spam)"
CountLabel.Parent = MainCard

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
		ToggleButton.Text = "AURA: ARMED // ON ATTACK"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "AURA: OFF [X]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
		CountLabel.Text = "In range: [Offline]"
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
-- RANGE SCANNER (PASSIVE - ZERO AUTO-ATTACK PING IMPACT)
-- ============================================================================
local function updateTargets()
	table.clear(inRangeEnemies)

	local char = LocalPlayer.Character
	if not char then return end

	local myRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if not (myRoot and myRoot:IsA("BasePart")) then return end

	local myPos = myRoot.Position

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local pChar = p.Character
			if pChar then
				local hum = pChar:FindFirstChildOfClass("Humanoid")
				local r = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Torso")
				if hum and r and r:IsA("BasePart") and hum.Health > 0 then
					local dx = r.Position.X - myPos.X
					local dy = r.Position.Y - myPos.Y
					local dz = r.Position.Z - myPos.Z
					if (dx * dx + dy * dy + dz * dz) <= RANGE_SQ then
						local parts: { BasePart } = {}
						for _, partName in ipairs(PRIORITY_PARTS) do
							local bp = pChar:FindFirstChild(partName)
							if bp and bp:IsA("BasePart") then
								table.insert(parts, bp)
							end
						end
						table.insert(inRangeEnemies, {
							Character = pChar,
							Parts = parts,
							Root = r,
						})
					end
				end
			end
		end
	end

	if Active then
		CountLabel.Text = string.format("In 10 stud range: %d (Swing to strike)", #inRangeEnemies)
	end
end

-- Passive sweep every 0.1s to keep in-range count updated without attacking
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastScanTime < 0.1 then return end
	lastScanTime = now

	if Active then
		updateTargets()
	end
end)

-- ============================================================================
-- AURA HIT EXECUTION (CALLED ON ATTACK / SWING ONLY)
-- ============================================================================
local function executeAuraStrike()
	if not Active then return end
	updateTargets()
	if #inRangeEnemies == 0 then return end

	for i = 1, #inRangeEnemies do
		local enemy = inRangeEnemies[i]
		local root = enemy.Root

		-- 1. Melee Combat Remotes
		for r = 1, #toolRemotes do
			local rem = toolRemotes[r]
			if rem and rem.Parent and root and root.Parent then
				pcall(rem.FireServer, rem, root)
			end
		end

		-- 2. Melee Touch Interests (Registered on swing)
		if fireTouch then
			for p = 1, #enemy.Parts do
				local enemyPart = enemy.Parts[p]
				if enemyPart and enemyPart.Parent then
					for t = 1, #toolParts do
						local toolPart = toolParts[t]
						if toolPart and toolPart.Parent then
							for _ = 1, TOUCH_BURST do
								pcall(fireTouch, toolPart, enemyPart, 0)
								pcall(fireTouch, toolPart, enemyPart, 1)
							end
						end
					end
				end
			end
		end
	end
end

-- ============================================================================
-- TOOL CACHING & ATTACK HOOKING (MELEE TOOLS)
-- ============================================================================
local function findFightRemote(tool: Tool): RemoteEvent?
	local r = tool:FindFirstChild("FightEvent")
	if r and r:IsA("RemoteEvent") then return r end
	for _, o in ipairs(tool:GetChildren()) do
		if o:IsA("RemoteEvent") then
			local n = string.lower(o.Name)
			if string.find(n, "fight", 1, true)
				or string.find(n, "slap", 1, true)
				or string.find(n, "hit", 1, true)
				or string.find(n, "attack", 1, true)
				or string.find(n, "combat", 1, true)
				or string.find(n, "event", 1, true) then
				return o
			end
		end
	end
	return nil
end

local function hookToolAttack(tool: Tool)
	if toolConnections[tool] then
		toolConnections[tool]:Disconnect()
		toolConnections[tool] = nil
	end

	-- Trigger damage when the tool is swung/activated
	toolConnections[tool] = tool.Activated:Connect(function()
		executeAuraStrike()
	end)
end

local function rebuildToolParts()
	table.clear(toolParts)
	table.clear(toolRemotes)
	table.clear(equippedTools)

	local char = LocalPlayer.Character
	if not char then return end

	for _, t in ipairs(char:GetChildren()) do
		if t:IsA("Tool") then
			table.insert(equippedTools, t)
			hookToolAttack(t)

			local handle = t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart")
			if handle and handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Massless = true
				handle.CanTouch = true
				if not table.find(toolParts, handle) then
					table.insert(toolParts, handle)
				end
			end

			local rem = findFightRemote(t)
			if rem and not table.find(toolRemotes, rem) then
				table.insert(toolRemotes, rem)
			end
		end
	end
end

-- Fallback attack trigger on mouse click / screen tap when melee tool is equipped
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		if #equippedTools > 0 and Active then
			executeAuraStrike()
		end
	end
end)

local function hookCharacter(char: Model)
	for _, conn in pairs(toolConnections) do
		conn:Disconnect()
	end
	table.clear(toolConnections)

	rebuildToolParts()
	char.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildToolParts)
		end
	end)
	char.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildToolParts)
		end
	end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

updateUI()
print("[Kill Aura] CIPHER // KILL AURA V6.1 Loaded (10-Stud On-Attack Edition).")
