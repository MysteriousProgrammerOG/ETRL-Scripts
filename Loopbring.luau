--!strict
-- ============================================================================
-- CIPHER // AGGRESSIVE LOOPBRING V5.0 (MODERN RESCRIPT)
-- High-Performance Target Teleporter with Anti-Rubberband Physics & Sleek UI
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

local TOGGLE_KEY = Enum.KeyCode.B
local LoopBrings: { [number]: boolean } = {}
local targetDistance: number = 3
local targetOffset: number   = 0
local Active: boolean        = true

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
local existing = guiContainer:FindFirstChild("CipherLoopBringGUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherLoopBringGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(250, 36)
MainFrame.Position = UDim2.new(0, 20, 0.22, 0)
MainFrame.BackgroundColor3 = THEME.BgPrimary
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = THEME.Border
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Top Control Bar
local ControlBar = Instance.new("Frame")
ControlBar.Name = "ControlBar"
ControlBar.Size = UDim2.new(1, -8, 0, 28)
ControlBar.Position = UDim2.new(0, 4, 0, 4)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = MainFrame

local BarLayout = Instance.new("UIListLayout")
BarLayout.FillDirection = Enum.FillDirection.Horizontal
BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BarLayout.Padding = UDim.new(0, 4)
BarLayout.Parent = ControlBar

local function createBarButton(text: string, width: number, order: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width, 0, 26)
	btn.BackgroundColor3 = THEME.BgCard
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = ControlBar

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

local ToggleButton = createBarButton("⚡ LOOPBRING [B]", 136, 1)
local AllButton    = createBarButton("ALL", 48, 2)
local ClearButton  = createBarButton("CLR", 48, 3)

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
DropPanel.Parent = MainFrame

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

setupDraggable(MainFrame, MainFrame)

-- Dropdown Toggle Animation
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
		ToggleButton.Text = "⚡ LOOPBRING: ON"
		MainStroke.Color = THEME.Border
	else
		ToggleButton.TextColor3 = THEME.TextMuted
		ToggleButton.Text = "⚡ LOOPBRING: OFF [B]"
		MainStroke.Color = THEME.BorderDim
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
-- ROSTER UPDATE ENGINE
-- ============================================================================
local function updatePlayerList()
	for _, child in ipairs(ScrollList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local isLocked = LoopBrings[player.UserId] == true

			local btn = Instance.new("TextButton")
			btn.Name = player.Name
			btn.Size = UDim2.new(1, -4, 0, 24)
			btn.BackgroundColor3 = isLocked and THEME.AccentDim or THEME.BgCard
			btn.TextColor3 = isLocked and THEME.Accent or THEME.TextMain
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 10
			btn.AutoButtonColor = false
			btn.Text = (isLocked and "★ " or "") .. player.DisplayName .. (isLocked and " [LOCKED]" or "")
			btn.Parent = ScrollList

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent = btn

			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = isLocked and THEME.Border or THEME.BorderDim
			s.Parent = btn

			btn.MouseButton1Click:Connect(function()
				if LoopBrings[player.UserId] then
					LoopBrings[player.UserId] = nil
					if player.Character then
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							hum.WalkSpeed = 16
							hum.JumpPower = 50
						end
					end
				else
					LoopBrings[player.UserId] = true
				end
				updatePlayerList()
			end)
		end
	end
end

AllButton.MouseButton1Click:Connect(function()
	local anyUnlocked = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and not LoopBrings[p.UserId] then
			anyUnlocked = true
			break
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			if anyUnlocked then
				LoopBrings[p.UserId] = true
			else
				LoopBrings[p.UserId] = nil
				if p.Character then
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = 16
						hum.JumpPower = 50
					end
				end
			end
		end
	end
	updatePlayerList()
end)

ClearButton.MouseButton1Click:Connect(function()
	for userId in pairs(LoopBrings) do
		local p = Players:GetPlayerByUserId(userId)
		if p and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 16
				hum.JumpPower = 50
			end
		end
	end
	table.clear(LoopBrings)
	updatePlayerList()
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(player: Player)
	LoopBrings[player.UserId] = nil
	updatePlayerList()
end)

updatePlayerList()

-- ============================================================================
-- HIGH-PERFORMANCE LOOPBRING ENGINE
-- ============================================================================
local function executeBringCycle()
	if not Active or not next(LoopBrings) then return end

	local myChar = LocalPlayer.Character
	if not myChar then return end

	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	if not (myHRP and myHRP:IsA("BasePart")) then return end

	local targetCFrame = myHRP.CFrame * CFrame.new(targetOffset, 0, -targetDistance)

	for userId, isLocked in pairs(LoopBrings) do
		if isLocked then
			local targetPlayer = Players:GetPlayerByUserId(userId)
			if targetPlayer and targetPlayer.Character then
				local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

				if targetHRP and targetHRP:IsA("BasePart") then
					targetHRP.CFrame = targetCFrame
					targetHRP.AssemblyLinearVelocity = Vector3.zero
					targetHRP.AssemblyAngularVelocity = Vector3.zero

					if targetHum then
						targetHum.WalkSpeed = 0
						targetHum.JumpPower = 0
					end
				end
			end
		end
	end
end

-- Run on PreSimulation (replaces the triple Stepped+PreRender+Heartbeat spam with a clean single physics step)
RunService.PreSimulation:Connect(executeBringCycle)

updateUI()
print("[Loopbring] CIPHER // AGGRESSIVE LOOPBRING V5.0 Loaded.")
