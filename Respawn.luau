-- ============================================================================
-- CIPHER // FAST RESPAWN ENGINE V6.1 (MODERN RESCRIPT)
-- Guaranteed Guide() Remote Detection & Ultra-Early Death Insta-Spawn
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

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

local TOGGLE_KEY: Enum.KeyCode = Enum.KeyCode.R
local HEALTH_THRESHOLD: number = 40     -- Early trigger threshold
local BURST_DROP_THRESHOLD: number = 15  -- Sudden frame damage drop threshold
local MIN_RETRIGGER_DELAY: number = 0.25 -- Minimal debounce between pulses

local Active: boolean          = true
local isFiring: boolean        = false
local lastRequestTime: number  = 0
local characterToken: number   = 0
local lastObservedHealth: number = 100
local activeCharConns: { RBXScriptConnection } = {}

-- Caches for Guide() and Respawn remotes
local guideRemotes: { Instance } = {}

local function disconnectCharConns()
	for _, c in ipairs(activeCharConns) do
		if c and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(activeCharConns)
end

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
local existingUI = guiContainer:FindFirstChild("CipherRespawnUI")
if existingUI then
	existingUI:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherRespawnUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(240, 78)
MainCard.Position = UDim2.new(1, -255, 0.65, 0)
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
HeaderTitle.Text = "⚡ FAST RESPAWN // GUIDE() [R]"
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

-- Action Row (Toggle + Manual Test Respawn)
local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -14, 0, 26)
ActionRow.Position = UDim2.new(0, 7, 0, 26)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = MainCard

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0.68, -4, 1, 0)
ToggleButton.Position = UDim2.new(0, 0, 0, 0)
ToggleButton.BackgroundColor3 = THEME.BgCard
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 10
ToggleButton.TextColor3 = THEME.ActiveGreen
ToggleButton.Text = "RESPAWN: ACTIVE"
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = ActionRow

local TbCorner = Instance.new("UICorner")
TbCorner.CornerRadius = UDim.new(0, 6)
TbCorner.Parent = ToggleButton

local TbStroke = Instance.new("UIStroke")
TbStroke.Thickness = 1
TbStroke.Color = THEME.Border
TbStroke.Transparency = 0.5
TbStroke.Parent = ToggleButton

local TestBtn = Instance.new("TextButton")
TestBtn.Name = "TestBtn"
TestBtn.Size = UDim2.new(0.32, 0, 1, 0)
TestBtn.Position = UDim2.new(0.68, 0, 0, 0)
TestBtn.BackgroundColor3 = THEME.BgCard
TestBtn.Font = Enum.Font.GothamBold
TestBtn.TextSize = 10
TestBtn.TextColor3 = THEME.TextMain
TestBtn.Text = "SPAWN"
TestBtn.AutoButtonColor = false
TestBtn.Parent = ActionRow

local TestCorner = Instance.new("UICorner")
TestCorner.CornerRadius = UDim.new(0, 6)
TestCorner.Parent = TestBtn

local TestStroke = Instance.new("UIStroke")
TestStroke.Thickness = 1
TestStroke.Color = THEME.BorderDim
TestStroke.Parent = TestBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -14, 0, 18)
StatusLabel.Position = UDim2.new(0, 7, 0, 54)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 9
StatusLabel.TextColor3 = THEME.TextMuted
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Text = "Remotes: [Scanning for Guide()]"
StatusLabel.Parent = MainCard

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

-- ============================================================================
-- GUIDE() & RESPAWN REMOTE DISCOVERY (ALL CONTAINERS)
-- ============================================================================
local function evaluateRemote(inst: Instance)
	if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
		local n = string.lower(inst.Name)
		if n == "guide"
			or string.find(n, "guide", 1, true)
			or string.find(n, "respawn", 1, true)
			or string.find(n, "loadchar", 1, true)
			or string.find(n, "spawn", 1, true) then
			if not table.find(guideRemotes, inst) then
				table.insert(guideRemotes, inst)
				StatusLabel.Text = string.format("Guide Remotes: %d Active // Watching HP", #guideRemotes)
				StatusLabel.TextColor3 = THEME.ActiveGreen
			end
		end
	end
end

local function discoverAllRemotes()
	table.clear(guideRemotes)

	-- 1. Direct search in ReplicatedStorage
	for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
		evaluateRemote(inst)
	end

	-- 2. Direct search in Workspace
	for _, inst in ipairs(Workspace:GetDescendants()) do
		evaluateRemote(inst)
	end

	-- 3. Search in LocalPlayer (Backpack, PlayerGui, PlayerScripts)
	for _, inst in ipairs(LocalPlayer:GetDescendants()) do
		evaluateRemote(inst)
	end

	if #guideRemotes > 0 then
		StatusLabel.Text = string.format("Guide Remotes: %d Active // Watching HP", #guideRemotes)
		StatusLabel.TextColor3 = THEME.ActiveGreen
	else
		StatusLabel.Text = "Remotes: Guide() searching..."
		StatusLabel.TextColor3 = THEME.TextMuted
	end
end

discoverAllRemotes()

ReplicatedStorage.DescendantAdded:Connect(evaluateRemote)
Workspace.DescendantAdded:Connect(evaluateRemote)

-- ============================================================================
-- INSTA-SPAWN GUIDE DISPATCHER
-- ============================================================================
local function fireRespawn()
	local now = os.clock()
	if now - lastRequestTime < MIN_RETRIGGER_DELAY then return end
	lastRequestTime = now
	isFiring = true

	print("[Respawn] Early death triggered! Firing Guide() remote to insta-spawn character.")

	-- 1. Directly fire all discovered Guide / Respawn remotes with multiple payload signatures
	if #guideRemotes == 0 then
		discoverAllRemotes()
	end

	for _, r in ipairs(guideRemotes) do
		if r and r.Parent then
			task.spawn(function()
				if r:IsA("RemoteEvent") then
					pcall(r.FireServer, r)
					pcall(r.FireServer, r, LocalPlayer)
					pcall(r.FireServer, r, "Respawn")
					pcall(r.FireServer, r, true)
				elseif r:IsA("RemoteFunction") then
					pcall(r.InvokeServer, r)
					pcall(r.InvokeServer, r, LocalPlayer)
				end
			end)
		end
	end

	-- 2. Direct fallback find if remote is named "Guide"
	local directGuide = ReplicatedStorage:FindFirstChild("Guide", true) 
		or Workspace:FindFirstChild("Guide", true)
	if directGuide then
		task.spawn(function()
			if directGuide:IsA("RemoteEvent") then
				pcall(directGuide.FireServer, directGuide)
			elseif directGuide:IsA("RemoteFunction") then
				pcall(directGuide.InvokeServer, directGuide)
			end
		end)
	end

	-- 3. Call fast-equip hook (Guide() in Use Tools or environment)
	pcall(function()
		local g = _G.Guide or _G.FastEquip
		if typeof(g) == "function" then
			task.spawn(g)
		end
		local genv = typeof(getgenv) == "function" and getgenv()
		if genv and typeof(genv.Guide) == "function" then
			task.spawn(genv.Guide)
		end
	end)

	task.delay(0.2, function()
		isFiring = false
	end)
end

-- ============================================================================
-- ULTRA-EARLY HEALTH DROP & DEATH MONITOR
-- ============================================================================
local function hookCharacter(char: Model)
	characterToken += 1
	local myToken = characterToken
	disconnectCharConns()

	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not (hum and hum:IsA("Humanoid")) then return end

	lastObservedHealth = hum.Health

	local function checkAndTrigger(currentHp: number, cause: string)
		if not Active then return end
		if characterToken ~= myToken then return end

		local drop = lastObservedHealth - currentHp
		lastObservedHealth = currentHp

		-- Triggers on:
		-- 1. Any health <= 0 (instant death)
		-- 2. Health drops below threshold (<= 40)
		-- 3. Sudden lethal burst damage (drop >= 15 in one frame)
		-- 4. Died / Ragdoll / FallingDown states
		if currentHp <= 0 or currentHp <= HEALTH_THRESHOLD or drop >= BURST_DROP_THRESHOLD or cause == "Died" or cause == "State" then
			fireRespawn()
		end
	end

	-- Event 1: HealthChanged (fires immediately upon damage)
	table.insert(activeCharConns, hum.HealthChanged:Connect(function(hp: number)
		checkAndTrigger(hp, "HealthChanged")
	end))

	-- Event 2: Humanoid.Died (native engine death signal)
	table.insert(activeCharConns, hum.Died:Connect(function()
		checkAndTrigger(0, "Died")
	end))

	-- Event 3: StateChanged (detects ragdoll or death state before health reaches 0)
	table.insert(activeCharConns, hum.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.Ragdoll
			or newState == Enum.HumanoidStateType.FallingDown then
			checkAndTrigger(hum.Health, "State")
		end
	end))
end

-- Per-Frame Microsecond Heartbeat Watchdog
-- Guarantees early trigger even if custom scripts disconnect or delay Died events
RunService.Heartbeat:Connect(function()
	if not Active then return end
	local char = LocalPlayer.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
			fireRespawn()
		elseif hum.Health <= HEALTH_THRESHOLD then
			fireRespawn()
		end
	end
end)

-- UI Sync
local function updateUI()
	if Active then
		ToggleButton.Text = "RESPAWN: ACTIVE"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "RESPAWN: STANDBY [R]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
	end
end

local function toggleActive()
	Active = not Active
	if Active then
		if LocalPlayer.Character then
			hookCharacter(LocalPlayer.Character)
		end
	else
		disconnectCharConns()
	end
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(toggleActive)

-- Manual Spawn / Test Button
TestBtn.MouseButton1Click:Connect(function()
	fireRespawn()
	TweenService:Create(TestBtn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.AccentDim}):Play()
	task.delay(0.15, function()
		TweenService:Create(TestBtn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.BgCard}):Play()
	end)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleActive()
	end
end)

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
	task.defer(function()
		hookCharacter(char)
	end)
end)

updateUI()
print("[Respawn] CIPHER // FAST RESPAWN V6.1 Loaded (Guide() Insta-Spawn Active).")
