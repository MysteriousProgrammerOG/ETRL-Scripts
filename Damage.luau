-- ============================================================================
-- CIPHER // HITBOX EXPANDER V4.1 (MODERN RESCRIPT)
-- Persistent Hitbox Expander with Guaranteed Respawn & Loopbring Synergy
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Global API compatibility
_G.HitboxSize = _G.HitboxSize or 12
_G.Enabled = if _G.Enabled ~= nil then _G.Enabled else true

local CONFIG = {
	MinSize = 2,
	MaxSize = 30,
	Step = 2,
	ToggleKey = Enum.KeyCode.H,
}

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

-- Anti-Jitter Zero-Mass Physical Properties (Eliminates all Loopbring physics conflict)
local ZERO_PHYSICS = PhysicalProperties.new(0.0001, 0, 0, 0, 0)

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
local existing = guiContainer:FindFirstChild("CipherDamageUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherDamageUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 78)
MainCard.Position = UDim2.new(0.03, 0, 0.40, 0)
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

-- Header (Drag Bar)
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
HeaderTitle.Text = "⚔️ HITBOX EXPANDER [H]"
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

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0.58, -10, 0, 26)
ToggleButton.Position = UDim2.new(0, 7, 0, 26)
ToggleButton.BackgroundColor3 = THEME.BgCard
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 11
ToggleButton.TextColor3 = THEME.ActiveGreen
ToggleButton.Text = "HITBOX: ON"
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

-- Size Control Stepper
local SizeControl = Instance.new("Frame")
SizeControl.Name = "SizeControl"
SizeControl.Size = UDim2.new(0.42, -5, 0, 26)
SizeControl.Position = UDim2.new(0.58, 0, 0, 26)
SizeControl.BackgroundColor3 = THEME.BgCard
SizeControl.Parent = MainCard

local SizeCorner = Instance.new("UICorner")
SizeCorner.CornerRadius = UDim.new(0, 6)
SizeCorner.Parent = SizeControl

local SizeMinus = Instance.new("TextButton")
SizeMinus.Size = UDim2.new(0, 22, 1, 0)
SizeMinus.Position = UDim2.new(0, 0, 0, 0)
SizeMinus.BackgroundTransparency = 1
SizeMinus.Font = Enum.Font.GothamBold
SizeMinus.TextSize = 14
SizeMinus.TextColor3 = THEME.Accent
SizeMinus.Text = "-"
SizeMinus.Parent = SizeControl

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -44, 1, 0)
SizeLabel.Position = UDim2.new(0, 22, 0, 0)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Font = Enum.Font.GothamBold
SizeLabel.TextSize = 11
SizeLabel.TextColor3 = THEME.TextMain
SizeLabel.Text = tostring(_G.HitboxSize) .. " studs"
SizeLabel.Parent = SizeControl

local SizePlus = Instance.new("TextButton")
SizePlus.Size = UDim2.new(0, 22, 1, 0)
SizePlus.Position = UDim2.new(1, -22, 0, 0)
SizePlus.BackgroundTransparency = 1
SizePlus.Font = Enum.Font.GothamBold
SizePlus.TextSize = 14
SizePlus.TextColor3 = THEME.Accent
SizePlus.Text = "+"
SizePlus.Parent = SizeControl

-- Subtitle status row
local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -14, 0, 16)
SubLabel.Position = UDim2.new(0, 7, 0, 56)
SubLabel.BackgroundTransparency = 1
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 9
SubLabel.TextColor3 = THEME.TextMuted
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Text = "Persistent Respawn // Loopbring Anti-Fling"
SubLabel.Parent = MainCard

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
-- HIGH-PERFORMANCE HITBOX ENGINE WITH LOOPBRING SYNERGY
-- ============================================================================
type OriginalData = {
	Size: Vector3,
	Transparency: number,
	Material: Enum.Material,
	CanCollide: boolean,
	CanQuery: boolean,
	CanTouch: boolean,
	Massless: boolean,
	CustomPhysicalProperties: PhysicalProperties?,
}

local originalParts: { [BasePart]: OriginalData } = {}
local activeVisuals: { [BasePart]: SelectionBox } = {}
local charConnections: { [Player]: { RBXScriptConnection } } = {}

local function restorePart(hrp: BasePart)
	local orig = originalParts[hrp]
	if orig and hrp.Parent then
		hrp.Size = orig.Size
		hrp.Transparency = orig.Transparency
		hrp.Material = orig.Material
		hrp.CanCollide = orig.CanCollide
		hrp.CanQuery = orig.CanQuery
		hrp.CanTouch = orig.CanTouch
		hrp.Massless = orig.Massless
		if orig.CustomPhysicalProperties then
			hrp.CustomPhysicalProperties = orig.CustomPhysicalProperties
		end
	end
	originalParts[hrp] = nil

	local visual = activeVisuals[hrp] or hrp:FindFirstChild("HitboxVisual")
	if visual then
		visual:Destroy()
	end
	activeVisuals[hrp] = nil
end

local function applyHitboxToHRP(hrp: BasePart)
	if not _G.Enabled then return end
	if not hrp or not hrp.Parent then return end

	-- Store original properties once
	if not originalParts[hrp] then
		originalParts[hrp] = {
			Size = hrp.Size,
			Transparency = hrp.Transparency,
			Material = hrp.Material,
			CanCollide = hrp.CanCollide,
			CanQuery = hrp.CanQuery,
			CanTouch = hrp.CanTouch,
			Massless = hrp.Massless,
			CustomPhysicalProperties = hrp.CustomPhysicalProperties,
		}
	end

	local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)

	-- Apply expanded hitbox
	if hrp.Size ~= targetSize then
		hrp.Size = targetSize
	end

	hrp.Transparency = 0.75
	hrp.Material = Enum.Material.ForceField

	-- CRITICAL FOR LOOPBRING & DETECTION:
	-- CanCollide = false prevents collision pushing/flinging when brought next to you
	hrp.CanCollide = false
	-- CanTouch & CanQuery = true ensures maximum weapon touch and hit registration
	hrp.CanTouch = true
	hrp.CanQuery = true
	hrp.Massless = true
	hrp.CustomPhysicalProperties = ZERO_PHYSICS

	-- Ensure SelectionBox exists
	local box = activeVisuals[hrp] or hrp:FindFirstChild("HitboxVisual")
	if not box then
		local newBox = Instance.new("SelectionBox")
		newBox.Name = "HitboxVisual"
		newBox.Adornee = hrp
		newBox.LineThickness = 0.05
		newBox.Color3 = Color3.fromRGB(0, 255, 120)
		newBox.SurfaceColor3 = Color3.fromRGB(0, 255, 120)
		newBox.SurfaceTransparency = 0.8
		newBox.Parent = hrp
		activeVisuals[hrp] = newBox
	end
end

local function applyHitboxToPlayer(player: Player)
	if player == LocalPlayer then return end
	if not _G.Enabled then return end

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		applyHitboxToHRP(hrp)
	end
end

local function refreshAllHitboxes()
	if _G.Enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			applyHitboxToPlayer(player)
		end
	else
		for part in pairs(originalParts) do
			restorePart(part)
		end
	end
end

-- ============================================================================
-- GUARANTEED RESPAWN BINDING
-- ============================================================================
local function cleanupPlayerConns(player: Player)
	if charConnections[player] then
		for _, c in ipairs(charConnections[player]) do
			c:Disconnect()
		end
		charConnections[player] = nil
	end
end

local function bindPlayer(player: Player)
	if player == LocalPlayer then return end
	cleanupPlayerConns(player)

	local conns: { RBXScriptConnection } = {}
	charConnections[player] = conns

	local function onCharacter(char: Model)
		-- 1. Immediate check if HRP already exists
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			applyHitboxToHRP(hrp)
		end

		-- 2. ChildAdded listener for when HRP streams/spawns in
		table.insert(conns, char.ChildAdded:Connect(function(child: Instance)
			if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
				task.defer(function()
					applyHitboxToHRP(child)
				end)
			end
		end))

		-- 3. Non-blocking retry loop to guarantee attachment on slow respawns
		task.spawn(function()
			local foundHRP = char:WaitForChild("HumanoidRootPart", 4)
			if foundHRP and foundHRP:IsA("BasePart") and _G.Enabled then
				applyHitboxToHRP(foundHRP)
			end
		end)
	end

	table.insert(conns, player.CharacterAdded:Connect(onCharacter))

	if player.Character then
		onCharacter(player.Character)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	bindPlayer(p)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
	cleanupPlayerConns(player)
end)

-- Gentle low-frequency persistence heartbeat (Every 0.5s)
-- Ensures hitboxes stay applied even if game scripts or health resets overwrite them
local lastCheck = 0
RunService.Heartbeat:Connect(function()
	if not _G.Enabled then return end

	local now = os.clock()
	if now - lastCheck < 0.5 then return end
	lastCheck = now

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
				if hrp.Size ~= targetSize or hrp.CanCollide == true then
					applyHitboxToHRP(hrp)
				end
			end
		end
	end
end)

-- UI Sync
local function updateUI()
	if _G.Enabled then
		ToggleButton.Text = "HITBOX: ON"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "HITBOX: OFF"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
	end
	SizeLabel.Text = tostring(_G.HitboxSize) .. " studs"
end

local function toggleHitbox()
	_G.Enabled = not _G.Enabled
	refreshAllHitboxes()
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(toggleHitbox)

SizeMinus.MouseButton1Click:Connect(function()
	_G.HitboxSize = math.clamp(_G.HitboxSize - CONFIG.Step, CONFIG.MinSize, CONFIG.MaxSize)
	refreshAllHitboxes()
	updateUI()
end)

SizePlus.MouseButton1Click:Connect(function()
	_G.HitboxSize = math.clamp(_G.HitboxSize + CONFIG.Step, CONFIG.MinSize, CONFIG.MaxSize)
	refreshAllHitboxes()
	updateUI()
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == CONFIG.ToggleKey then
		toggleHitbox()
	end
end)

updateUI()
print("⚔️ CIPHER // HITBOX EXPANDER V4.1 Loaded (Guaranteed Respawn Edition).")
