--!strict
-- ============================================================================
-- CIPHER // FAST RESPAWN ENGINE V6.0 (MODERN RESCRIPT)
-- Pre-Emptive Lethal-Damage Monitor & Rapid Recovery Dispatcher
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
local HEALTH_THRESHOLD: number = 40    -- Triggers when HP drops below 40
local BURST_DROP_THRESHOLD: number = 15 -- Triggers on sudden >= 15 burst damage
local MIN_FIRE_INTERVAL: number = 0.5   -- Debounce to prevent remote spam

local Active: boolean          = true
local isFiring: boolean        = false
local lastRequestTime: number  = 0
local characterToken: number   = 0
local lastObservedHealth: number = 100
local activeCharConns: { RBXScriptConnection } = {}

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
MainCard.Size = UDim2.fromOffset(230, 62)
MainCard.Position = UDim2.new(1, -245, 0.65, 0)
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
HeaderTitle.Text = "⚡ FAST RESPAWN [R]"
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
ToggleButton.Size = UDim2.new(1, -14, 0, 28)
ToggleButton.Position = UDim2.new(0, 7, 0, 26)
ToggleButton.BackgroundColor3 = THEME.BgCard
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 11
ToggleButton.TextColor3 = THEME.ActiveGreen
ToggleButton.Text = "RESPAWN: ACTIVE // <40 HP"
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
		ToggleButton.Text = "RESPAWN: ACTIVE // <40 HP"
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

-- ============================================================================
-- TARGETED RESPAWN REMOTE CACHING
-- ============================================================================
local cachedRemotes: { RemoteEvent } = {}

local function checkRemote(inst: Instance)
	if inst:IsA("RemoteEvent") then
		local n = string.lower(inst.Name)
		if string.find(n, "respawn", 1, true)
			or string.find(n, "reset", 1, true)
			or string.find(n, "death", 1, true)
			or string.find(n, "spawn", 1, true) then
			if not table.find(cachedRemotes, inst) then
				table.insert(cachedRemotes, inst)
			end
		end
	end
end

-- Scan top-level and common remote folders in ReplicatedStorage without scanning all map geometry
local function discoverRemotes()
	table.clear(cachedRemotes)
	for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		checkRemote(child)
		if child:IsA("Folder") or child:IsA("Configuration") then
			for _, sub in ipairs(child:GetChildren()) do
				checkRemote(sub)
			end
		end
	end
end

discoverRemotes()

-- ============================================================================
-- RESPAWN EXECUTION LOGIC
-- ============================================================================
local function fireRespawn()
	if isFiring then return end
	local now = os.clock()
	if now - lastRequestTime < MIN_FIRE_INTERVAL then return end

	isFiring = true
	lastRequestTime = now
	characterToken += 1
	disconnectCharConns()

	-- 1. Trigger Guide() or FastEquip if exposed by Use Tools
	pcall(function()
		local genv = typeof(getgenv) == "function" and getgenv()
		if genv and typeof(genv.Guide) == "function" then
			task.spawn(genv.Guide)
		end
	end)

	-- 2. Dispatch to discovered respawn remotes
	for _, r in ipairs(cachedRemotes) do
		if r and r.Parent then
			task.spawn(function()
				pcall(r.FireServer, r)
			end)
		end
	end

	-- 3. Reset local humanoid to trigger instant respawn
	task.spawn(function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				hum.Health = 0
			end
		end
	end)

	task.delay(0.5, function()
		isFiring = false
	end)
end

-- ============================================================================
-- HEALTH & STATE MONITOR
-- ============================================================================
local function hookCharacter(char: Model)
	characterToken += 1
	local myToken = characterToken
	disconnectCharConns()

	local hum = char:WaitForChild("Humanoid", 5)
	if not (hum and hum:IsA("Humanoid")) then return end

	lastObservedHealth = hum.Health
	local triggered = false

	local function trigger()
		if triggered then return end
		if not Active then return end
		if characterToken ~= myToken then return end
		triggered = true
		fireRespawn()
	end

	table.insert(activeCharConns, hum.HealthChanged:Connect(function(hp: number)
		local drop = lastObservedHealth - hp
		lastObservedHealth = hp

		if hp <= HEALTH_THRESHOLD or drop >= BURST_DROP_THRESHOLD then
			trigger()
		end
	end))

	table.insert(activeCharConns, hum.StateChanged:Connect(function(_, newState: Enum.HumanoidStateType)
		if newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.Ragdoll
			or newState == Enum.HumanoidStateType.FallingDown then
			trigger()
		end
	end))

	table.insert(activeCharConns, hum.Died:Connect(trigger))
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

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleActive()
	end
end)

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

updateUI()
print("[Respawn] CIPHER // FAST RESPAWN V6.0 Loaded.")
