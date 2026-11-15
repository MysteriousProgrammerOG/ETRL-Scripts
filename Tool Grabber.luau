-- ============================================================================
-- CIPHER // TYCOON TOOL GRABBER V6.0 (MODERN RESCRIPT)
-- High-Speed Tycoon Gear Claimer with Smart Debounce & Lightweight UI
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
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

local AutoGrab: boolean = true
local SWEEP_INTERVAL: number = 0.5 -- 2 Hz sweep is more than enough to maintain full gear without network lag

-- Filter Sets
local EXCLUDED_BASES: { [string]: boolean } = {
	["Insanity"] = true,
	["Giant"]    = true,
	["Dark"]     = true,
	["Spike"]    = true,
	["Web"]      = true,
	["Strong"]   = true,
}

local ALLOWED_BASES: { [string]: boolean } = {
	["Stone"]   = true,
	["Magic"]   = true,
	["Storm"]   = true,
	["Robotic"] = true,
}

-- Workspace Targets & Cache
local tycoons: Instance = Workspace:FindFirstChild("Tycoons") or Workspace
local touchableParts: { BasePart } = {}
local currentRoot: BasePart? = nil
local lastSweepTime: number = 0

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
local existing = guiContainer:FindFirstChild("CipherToolGrabberUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherToolGrabberUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 68)
MainCard.Position = UDim2.new(0.03, 0, 0.52, 0)
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
HeaderTitle.Text = "⚡ TYCOON // TOOL GRABBER"
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

-- Action Row (Auto Toggle + Grab Once)
local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -14, 0, 26)
ActionRow.Position = UDim2.new(0, 7, 0, 26)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = MainCard

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0.68, -4, 1, 0)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = THEME.BgCard
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 10
ToggleBtn.TextColor3 = THEME.ActiveGreen
ToggleBtn.Text = "AUTO-GRAB: ON"
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ActionRow

local TbCorner = Instance.new("UICorner")
TbCorner.CornerRadius = UDim.new(0, 6)
TbCorner.Parent = ToggleBtn

local TbStroke = Instance.new("UIStroke")
TbStroke.Thickness = 1
TbStroke.Color = THEME.Border
TbStroke.Transparency = 0.5
TbStroke.Parent = ToggleBtn

local GrabOnceBtn = Instance.new("TextButton")
GrabOnceBtn.Name = "GrabOnceBtn"
GrabOnceBtn.Size = UDim2.new(0.32, 0, 1, 0)
GrabOnceBtn.Position = UDim2.new(0.68, 0, 0, 0)
GrabOnceBtn.BackgroundColor3 = THEME.BgCard
GrabOnceBtn.Font = Enum.Font.GothamBold
GrabOnceBtn.TextSize = 10
GrabOnceBtn.TextColor3 = THEME.TextMain
GrabOnceBtn.Text = "PULSE"
GrabOnceBtn.AutoButtonColor = false
GrabOnceBtn.Parent = ActionRow

local GbCorner = Instance.new("UICorner")
GbCorner.CornerRadius = UDim.new(0, 6)
GbCorner.Parent = GrabOnceBtn

local GbStroke = Instance.new("UIStroke")
GbStroke.Thickness = 1
GbStroke.Color = THEME.BorderDim
GbStroke.Parent = GrabOnceBtn

local PartsCountLabel = Instance.new("TextLabel")
PartsCountLabel.Size = UDim2.new(1, -14, 0, 14)
PartsCountLabel.Position = UDim2.new(0, 7, 0, 52)
PartsCountLabel.BackgroundTransparency = 1
PartsCountLabel.Font = Enum.Font.Gotham
PartsCountLabel.TextSize = 9
PartsCountLabel.TextColor3 = THEME.TextMuted
PartsCountLabel.TextXAlignment = Enum.TextXAlignment.Left
PartsCountLabel.Text = "Discovered Givers: 0"
PartsCountLabel.Parent = MainCard

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
-- GEAR GIVER DISCOVERY & TOUCH ENGINE
-- ============================================================================
local function evaluateAndAdd(descendant: Instance)
	if not descendant:IsA("TouchTransmitter") then return end

	local parent = descendant.Parent
	if not (parent and parent:IsA("BasePart")) then return end

	local gearGiver = parent.Parent
	if not (gearGiver and string.find(gearGiver.Name, "GearGiver", 1, true)) then return end

	local baseFolder = gearGiver.Parent
	local baseName = baseFolder and baseFolder.Name

	if not baseName or (ALLOWED_BASES[baseName] or not EXCLUDED_BASES[baseName]) then
		if not table.find(touchableParts, parent) then
			table.insert(touchableParts, parent)
			PartsCountLabel.Text = string.format("Discovered Givers: %d", #touchableParts)

			parent.AncestryChanged:Connect(function(_, newParent)
				if not newParent then
					local idx = table.find(touchableParts, parent)
					if idx then
						table.remove(touchableParts, idx)
						PartsCountLabel.Text = string.format("Discovered Givers: %d", #touchableParts)
					end
				end
			end)
		end
	end
end

for _, inst in ipairs(tycoons:GetDescendants()) do
	evaluateAndAdd(inst)
end

tycoons.DescendantAdded:Connect(evaluateAndAdd)

local function updateCharacterRoot(character: Model)
	currentRoot = (character:WaitForChild("HumanoidRootPart", 5) 
		or character:FindFirstChildWhichIsA("BasePart")) :: BasePart?
end

if LocalPlayer.Character then
	updateCharacterRoot(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(updateCharacterRoot)
LocalPlayer.CharacterRemoving:Connect(function()
	currentRoot = nil
end)

local function fireAllTouches()
	local root = currentRoot
	if not (root and root.Parent) then return end
	if not fireTouch then return end

	for i = 1, #touchableParts do
		local targetPart = touchableParts[i]
		if targetPart and targetPart.Parent then
			pcall(fireTouch, root, targetPart, 0)
			pcall(fireTouch, root, targetPart, 1)
		end
	end
end

-- Timed periodic grab sweep (2 Hz)
RunService.Heartbeat:Connect(function()
	if not AutoGrab then return end

	local now = os.clock()
	if now - lastSweepTime < SWEEP_INTERVAL then return end
	lastSweepTime = now

	fireAllTouches()
end)

local function updateUI()
	if AutoGrab then
		ToggleBtn.Text = "AUTO-GRAB: ON"
		ToggleBtn.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleBtn.Text = "AUTO-GRAB: OFF"
		ToggleBtn.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
	end
end

ToggleBtn.MouseButton1Click:Connect(function()
	AutoGrab = not AutoGrab
	updateUI()
end)

GrabOnceBtn.MouseButton1Click:Connect(function()
	fireAllTouches()
	TweenService:Create(GrabOnceBtn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.AccentDim}):Play()
	task.delay(0.15, function()
		TweenService:Create(GrabOnceBtn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.BgCard}):Play()
	end)
end)

updateUI()
print("[Tool Grabber] CIPHER // TYCOON TOOL GRABBER V6.0 Loaded.")
