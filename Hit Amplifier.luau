-- ============================================================================
-- CIPHER // HIT AMPLIFIER V5.0 (MODERN RESCRIPT)
-- High-Performance Combat Multiplier with Remote Caching & Zero-Lag Spatial Sweep
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local RANGE_STUDS: number = 45
local RANGE_SQ: number    = RANGE_STUDS * RANGE_STUDS
local BURST_COUNT: number = 4
local SCAN_INTERVAL: number = 1 / 30 -- 30 Hz check is buttery smooth and eliminates CPU overhead
local TOGGLE_KEY: Enum.KeyCode = Enum.KeyCode.H
local Active: boolean     = true

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
local existing = guiContainer:FindFirstChild("CipherHitAmpUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherHitAmpUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 62)
MainCard.Position = UDim2.new(0.5, -115, 0.18, 0)
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
HeaderTitle.Text = "⚔️ HIT AMPLIFIER [H]"
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
ToggleButton.Text = "AMPLIFIER: ACTIVE // 4x BURST"
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
		ToggleButton.Text = "AMPLIFIER: ACTIVE // 4x BURST"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "AMPLIFIER: STANDBY [H]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
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
-- TOOL CACHING & FAST COMBAT ENGINE
-- ============================================================================
type ToolEntry = {
	Tool: Tool,
	Handle: BasePart?,
	Remote: RemoteEvent?,
}

local cachedTools: { ToolEntry } = {}

local function findFightRemote(tool: Tool): RemoteEvent?
	local r = tool:FindFirstChild("FightEvent")
	if r and r:IsA("RemoteEvent") then
		return r
	end
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

local function rebuildTools()
	table.clear(cachedTools)
	local char = LocalPlayer.Character
	if not char then return end

	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Tool") then
			local h = obj:FindFirstChild("Handle")
			local handlePart = (h and h:IsA("BasePart")) and h or nil
			if handlePart then
				handlePart.CanCollide = false
				handlePart.Massless = true
				handlePart.CanTouch = true
			end

			local rem = findFightRemote(obj)
			table.insert(cachedTools, {
				Tool = obj,
				Handle = handlePart,
				Remote = rem,
			})
		end
	end
end

local function hookCharacter(char: Model)
	rebuildTools()
	char.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildTools)
		end
	end)
	char.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildTools)
		end
	end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- Rapid Burst Pulse
local function pulseCombat()
	for i = 1, #cachedTools do
		local entry = cachedTools[i]
		local tool = entry.Tool
		if tool and tool.Parent then
			for _ = 1, BURST_COUNT do
				pcall(tool.Activate, tool)
			end
			local rem = entry.Remote
			if rem and rem.Parent then
				pcall(rem.FireServer, rem)
			end
		end
	end
end

-- ============================================================================
-- ZERO-LAG SPATIAL SWEEP
-- ============================================================================
local lastScanTime: number = 0

RunService.Heartbeat:Connect(function()
	if not Active then return end
	if #cachedTools == 0 then return end

	local now = os.clock()
	if now - lastScanTime < SCAN_INTERVAL then return end
	lastScanTime = now

	local char = LocalPlayer.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) then return end

	local myPos = hrp.Position
	local enemyInRange = false

	-- Fast distance scan against other players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local pChar = player.Character
			if pChar then
				local hum = pChar:FindFirstChildOfClass("Humanoid")
				local pRoot = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Torso")
				if hum and hum.Health > 0 and pRoot and pRoot:IsA("BasePart") then
					local diff = pRoot.Position - myPos
					if (diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z) <= RANGE_SQ then
						enemyInRange = true
						break
					end
				end
			end
		end
	end

	if enemyInRange then
		pulseCombat()
	end
end)

updateUI()
print("[Hit Amplifier] CIPHER // HIT AMPLIFIER V5.0 Loaded successfully.")
