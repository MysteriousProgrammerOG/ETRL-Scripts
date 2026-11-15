-- ============================================================================
-- CIPHER // LOOP TOOLS V6.0 (COSMIC ETERNAL RESCRIPT)
-- High-Speed Tool Attachment & Target Follower with Clean Dropdown UI
-- Mobile Scaled // Cosmic Liquid Border Flow // Black & Purple Theme
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Executor API Resolver
local fireTouch: ((BasePart, BasePart, number) -> ())? = (firetouchinterest :: any)
	or (getgenv and (getgenv().firetouchinterest or getgenv().fire_touch_interest))
	or (syn and syn.firetouchinterest)

-- ============================================================================
-- THEME & CONFIGURATION (COSMIC ETERNAL)
-- ============================================================================
local THEME = {
	VoidBg          = Color3.fromRGB(10, 8, 16),
	PanelBg         = Color3.fromRGB(18, 13, 28),
	CardBg          = Color3.fromRGB(26, 18, 42),
	CardHover       = Color3.fromRGB(38, 26, 62),
	AccentPurple    = Color3.fromRGB(168, 85, 247),
	AccentLight     = Color3.fromRGB(192, 132, 252),
	AccentDeep      = Color3.fromRGB(88, 28, 135),
	BorderDark      = Color3.fromRGB(35, 20, 55),
	TextWhite       = Color3.fromRGB(255, 255, 255),
	TextMuted       = Color3.fromRGB(170, 160, 195),
	ActiveGreen     = Color3.fromRGB(52, 211, 153),
	ActiveButtonBg  = Color3.fromRGB(48, 20, 78),
}

local TOGGLE_KEY = Enum.KeyCode.L
local FollowOffset = Vector3.new(0, 0.6, 0)
local AvoidCollisionOffset = Vector3.new(0, 0, 0.4)
local TICK_INTERVAL = 1 / 45

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
-- COSMIC LIQUID UI & MOBILE SCALING
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
MainCard.BackgroundColor3 = THEME.PanelBg
MainCard.BackgroundTransparency = 0.05
MainCard.BorderSizePixel = 0
MainCard.Active = true
MainCard.ClipsDescendants = false
MainCard.Parent = ScreenGui

-- Mobile Scaler
local CardScale = Instance.new("UIScale")
CardScale.Parent = MainCard

local function updateMobileScaling()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	if vp.X < 650 or vp.Y < 480 then
		local s = math.clamp(math.min(vp.X / 580, vp.Y / 420), 0.70, 0.95)
		CardScale.Scale = s
	else
		CardScale.Scale = 1.0
	end
end
updateMobileScaling()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileScaling)
end

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 9)
CardCorner.Parent = MainCard

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1.5
CardStroke.Color = THEME.AccentPurple
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Parent = MainCard

-- Cosmic Liquid Border Gradient
local BorderGradient = Instance.new("UIGradient")
BorderGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, THEME.AccentPurple),
	ColorSequenceKeypoint.new(0.25, THEME.VoidBg),
	ColorSequenceKeypoint.new(0.50, THEME.AccentLight),
	ColorSequenceKeypoint.new(0.75, THEME.AccentDeep),
	ColorSequenceKeypoint.new(1.00, THEME.AccentPurple),
})
BorderGradient.Parent = CardStroke

RunService.RenderStepped:Connect(function(dt: number)
	BorderGradient.Rotation = (BorderGradient.Rotation + dt * 50) % 360
end)

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
	btn.BackgroundColor3 = THEME.CardBg
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = THEME.TextWhite
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = Header

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = THEME.BorderDark
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEME.CardHover}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = THEME.CardBg}):Play()
	end)

	return btn
end

local ToggleButton = createHeaderButton("⚡ TOOLS: ON", 102, 1)
ToggleButton.TextColor3 = THEME.ActiveGreen

local DropdownToggle = createHeaderButton("TARGETS ▼", 82, 2)
local AllButton = createHeaderButton("ALL", 28, 3)
local ClearButton = createHeaderButton("CLR", 28, 4)

-- Dropdown Roster
local DropdownList = Instance.new("ScrollingFrame")
DropdownList.Name = "DropdownList"
DropdownList.Size = UDim2.fromOffset(250, 160)
DropdownList.Position = UDim2.new(0, 0, 1, 6)
DropdownList.BackgroundColor3 = THEME.PanelBg
DropdownList.BorderSizePixel = 0
DropdownList.ScrollBarThickness = 3
DropdownList.ScrollBarImageColor3 = THEME.AccentPurple
DropdownList.Visible = false
DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownList.Parent = MainCard

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 8)
DropdownCorner.Parent = DropdownList

local DropdownStroke = Instance.new("UIStroke")
DropdownStroke.Thickness = 1
DropdownStroke.Color = THEME.BorderDark
DropdownStroke.Parent = DropdownList

local DropdownLayout = Instance.new("UIListLayout")
DropdownLayout.SortOrder = Enum.SortOrder.Name
DropdownLayout.Padding = UDim.new(0, 4)
DropdownLayout.Parent = DropdownList

local DropdownPadding = Instance.new("UIPadding")
DropdownPadding.PaddingTop = UDim.new(0, 6)
DropdownPadding.PaddingBottom = UDim.new(0, 6)
DropdownPadding.PaddingLeft = UDim.new(0, 6)
DropdownPadding.PaddingRight = UDim.new(0, 6)
DropdownPadding.Parent = DropdownList

DropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	DropdownList.CanvasSize = UDim2.new(0, 0, 0, DropdownLayout.AbsoluteContentSize.Y + 12)
end)

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
-- ROSTER SYNC
-- ============================================================================
local function updateDropdown()
	for _, child in ipairs(DropdownList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local isSelected = targetPlayers[player.Name] == true
			local itemBtn = Instance.new("TextButton")
			itemBtn.Name = player.Name
			itemBtn.Size = UDim2.new(1, 0, 0, 26)
			itemBtn.BackgroundColor3 = isSelected and THEME.ActiveButtonBg or THEME.CardBg
			itemBtn.Font = Enum.Font.GothamBold
			itemBtn.TextSize = 10
			itemBtn.TextColor3 = isSelected and THEME.AccentLight or THEME.TextMuted
			itemBtn.Text = (isSelected and "★ " or "") .. player.DisplayName .. " (@" .. player.Name .. ")"
			itemBtn.AutoButtonColor = false
			itemBtn.Parent = DropdownList

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent = itemBtn

			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = isSelected and THEME.AccentPurple or THEME.BorderDark
			s.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				if targetPlayers[player.Name] then
					targetPlayers[player.Name] = nil
				else
					targetPlayers[player.Name] = true
				end
				updateDropdown()
			end)
		end
	end
end

DropdownToggle.MouseButton1Click:Connect(function()
	DropdownList.Visible = not DropdownList.Visible
	DropdownToggle.Text = DropdownList.Visible and "TARGETS ▲" or "TARGETS ▼"
	if DropdownList.Visible then
		updateDropdown()
	end
end)

AllButton.MouseButton1Click:Connect(function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			targetPlayers[p.Name] = true
		end
	end
	updateDropdown()
end)

ClearButton.MouseButton1Click:Connect(function()
	table.clear(targetPlayers)
	updateDropdown()
end)

local function updateUI()
	if Active then
		ToggleButton.Text = "⚡ TOOLS: ON"
		ToggleButton.TextColor3 = THEME.ActiveGreen
	else
		ToggleButton.Text = "⚡ TOOLS: OFF [L]"
		ToggleButton.TextColor3 = THEME.TextMuted
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
-- TOOL CACHING & FOLLOW ENGINE
-- ============================================================================
local function rebuildToolParts()
	table.clear(cachedToolParts)
	local char = LocalPlayer.Character
	if not char then return end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") then
			local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
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

local lastFollowTime = 0
RunService.Heartbeat:Connect(function()
	if not Active then return end

	local now = os.clock()
	if now - lastFollowTime < TICK_INTERVAL then return end
	lastFollowTime = now

	if #cachedToolParts == 0 then return end

	for targetName in pairs(targetPlayers) do
		local player = Players:FindFirstChild(targetName)
		if player and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
			if root and root:IsA("BasePart") then
				local targetCFrame = root.CFrame + FollowOffset + AvoidCollisionOffset
				for _, toolPart in ipairs(cachedToolParts) do
					if toolPart and toolPart.Parent then
						toolPart.CFrame = targetCFrame
						if fireTouch then
							pcall(fireTouch, toolPart, root, 0)
							pcall(fireTouch, toolPart, root, 1)
						end
					end
				end
			end
		end
	end
end)

local function hookCharacter(char: Model)
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

Players.PlayerAdded:Connect(function()
	if DropdownList.Visible then
		updateDropdown()
	end
end)

Players.PlayerRemoving:Connect(function(p)
	targetPlayers[p.Name] = nil
	if DropdownList.Visible then
		updateDropdown()
	end
end)

print("⚡ [Loop Tools] CIPHER // V6.0 Cosmic Eternal Loaded.")
