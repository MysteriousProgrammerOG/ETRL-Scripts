--!strict
-- ============================================================================
-- CIPHER // TARGET AURA V6.0 (MODERN RESCRIPT)
-- Selective Player Aura with Recycled Roster UI & Optimized Combat Dispatch
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

local TOGGLE_KEY = Enum.KeyCode.T
local TOUCH_BURST = 3
local REMOTE_BURST = 2
local TICK_INTERVAL = 1 / 30

local TargetList: { [Player]: boolean } = {}
local Active: boolean = true

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
local existingUI = guiContainer:FindFirstChild("CipherTargetAuraUI")
if existingUI then
	existingUI:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherTargetAuraUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(250, 36)
MainFrame.Position = UDim2.new(0.5, -125, 0.02, 0)
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

local ToggleButton = createBarButton("⚡ TARGET AURA [T]", 136, 1)
local SelectAllBtn  = createBarButton("ALL", 48, 2)
local ClearAllBtn   = createBarButton("CLR", 48, 3)

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
		ToggleButton.Text = "⚡ TARGET AURA: ON"
		MainStroke.Color = THEME.Border
	else
		ToggleButton.TextColor3 = THEME.TextMuted
		ToggleButton.Text = "⚡ TARGET AURA: OFF [T]"
		MainStroke.Color = THEME.BorderDim
	end
end

local function toggleActive()
	Active = not Active
	updateUI()
end

ToggleButton.MouseButton1Click:Connect(function()
	togglePanel()
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleActive()
	end
end)

-- ============================================================================
-- PLAYER ROSTER GENERATION
-- ============================================================================
local function updatePlayerList()
	for _, child in ipairs(ScrollList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local isSelected = TargetList[player] == true

			local btn = Instance.new("TextButton")
			btn.Name = player.Name
			btn.Size = UDim2.new(1, -4, 0, 24)
			btn.BackgroundColor3 = isSelected and THEME.AccentDim or THEME.BgCard
			btn.TextColor3 = isSelected and THEME.Accent or THEME.TextMain
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 10
			btn.AutoButtonColor = false
			btn.Text = (isSelected and "★ " or "") .. player.DisplayName .. (isSelected and " [LOCKED]" or "")
			btn.Parent = ScrollList

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent = btn

			local s = Instance.new("UIStroke")
			s.Thickness = 1
			s.Color = isSelected and THEME.Border or THEME.BorderDim
			s.Parent = btn

			btn.MouseButton1Click:Connect(function()
				if TargetList[player] then
					TargetList[player] = nil
				else
					TargetList[player] = true
				end
				updatePlayerList()
			end)
		end
	end
end

SelectAllBtn.MouseButton1Click:Connect(function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			TargetList[p] = true
		end
	end
	updatePlayerList()
end)

ClearAllBtn.MouseButton1Click:Connect(function()
	table.clear(TargetList)
	updatePlayerList()
end)

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(player: Player)
	TargetList[player] = nil
	updatePlayerList()
end)

updatePlayerList()

-- ============================================================================
-- TOOL CACHING & COMBAT DISPATCH
-- ============================================================================
type CachedTool = {
	Tool: Tool,
	TouchPart: BasePart?,
	Remote: RemoteEvent?,
}

local cachedTools: { CachedTool } = {}

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
	table.clear(cachedTools)
	local char = LocalPlayer.Character
	if not char then return end

	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
			if handle and handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Massless = true
				handle.CanTouch = true
			end

			local rem = findFightRemote(tool)
			table.insert(cachedTools, {
				Tool = tool,
				TouchPart = handle,
				Remote = rem,
			})
		end
	end
end

local function hookCharacter(char: Model)
	rebuildToolCache()
	char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.defer(rebuildToolCache) end end)
	char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then task.defer(rebuildToolCache) end end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- Attack Engine (Single smooth 30 Hz tick)
local lastAttackTick: number = 0

local function executeTargetAttack()
	if not Active then return end
	if not next(TargetList) then return end
	if #cachedTools == 0 then return end

	local targetsToHit: { { Character: Model, Root: BasePart, Parts: { BasePart } } } = {}

	for plr, isTargeted in pairs(TargetList) do
		if isTargeted and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
			if hum and hum.Health > 0 and root and root:IsA("BasePart") then
				local parts: { BasePart } = {}
				for _, name in ipairs(PRIORITY_PARTS) do
					local p = plr.Character:FindFirstChild(name)
					if p and p:IsA("BasePart") then
						table.insert(parts, p)
					end
				end
				table.insert(targetsToHit, {
					Character = plr.Character,
					Root = root,
					Parts = parts,
				})
			end
		end
	end

	if #targetsToHit == 0 then return end

	for t = 1, #cachedTools do
		local toolEntry = cachedTools[t]
		local tool = toolEntry.Tool
		local touchPart = toolEntry.TouchPart
		local remote = toolEntry.Remote

		if tool and tool.Parent then
			pcall(tool.Activate, tool)

			for _, target in ipairs(targetsToHit) do
				-- 1. Remote dispatch
				if remote and remote.Parent and target.Root and target.Root.Parent then
					for _ = 1, REMOTE_BURST do
						pcall(remote.FireServer, remote, target.Root)
					end
				end

				-- 2. Touch Interest Burst
				if fireTouch and touchPart and touchPart.Parent then
					for _, enemyPart in ipairs(target.Parts) do
						if enemyPart and enemyPart.Parent then
							for _ = 1, TOUCH_BURST do
								pcall(fireTouch, touchPart, enemyPart, 0)
								pcall(fireTouch, touchPart, enemyPart, 1)
							end
						end
					end
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastAttackTick < TICK_INTERVAL then return end
	lastAttackTick = now

	executeTargetAttack()
end)

updateUI()
print("[Target Aura] CIPHER // TARGET AURA V6.0 Loaded.")
