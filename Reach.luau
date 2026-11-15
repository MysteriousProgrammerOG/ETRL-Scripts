-- ============================================================================
-- CIPHER // TOOL REACH SELECTOR V4.0 (MODERN RESCRIPT)
-- High-Performance Reach Extender with Dynamic Tool Selector & Safe UI
-- ============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Configuration & State
local reachSize: number = 9
local activeReachTools: { [string]: boolean } = {}
local originalProperties: { [Tool]: { Size: Vector3, GripPos: Vector3, CanCollide: boolean, Massless: boolean } } = {}

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
local existing = guiContainer:FindFirstChild("CipherReachUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherReachUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(240, 68)
MainCard.Position = UDim2.new(0.03, 0, 0.26, 0)
MainCard.BackgroundColor3 = THEME.BgPrimary
MainCard.BackgroundTransparency = 0.08
MainCard.BorderSizePixel = 0
MainCard.Active = true
MainCard.ClipsDescendants = false
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
HeaderTitle.Text = "⚡ REACH // TOOL EXTENDER"
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

-- Action Row (Main Dropdown Button + Reach Size Stepper)
local DropdownToggle = Instance.new("TextButton")
DropdownToggle.Name = "DropdownToggle"
DropdownToggle.Size = UDim2.new(0.64, -10, 0, 26)
DropdownToggle.Position = UDim2.new(0, 7, 0, 26)
DropdownToggle.BackgroundColor3 = THEME.BgCard
DropdownToggle.Font = Enum.Font.GothamBold
DropdownToggle.TextSize = 11
DropdownToggle.TextColor3 = THEME.TextMain
DropdownToggle.Text = "SELECT TOOLS ▼"
DropdownToggle.AutoButtonColor = false
DropdownToggle.Parent = MainCard

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 6)
DropCorner.Parent = DropdownToggle

local DropStroke = Instance.new("UIStroke")
DropStroke.Thickness = 1
DropStroke.Color = THEME.BorderDim
DropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DropStroke.Parent = DropdownToggle

-- Size Stepper
local SizeControl = Instance.new("Frame")
SizeControl.Name = "SizeControl"
SizeControl.Size = UDim2.new(0.36, -4, 0, 26)
SizeControl.Position = UDim2.new(0.64, 0, 0, 26)
SizeControl.BackgroundColor3 = THEME.BgCard
SizeControl.Parent = MainCard

local SizeCorner = Instance.new("UICorner")
SizeCorner.CornerRadius = UDim.new(0, 6)
SizeCorner.Parent = SizeControl

local SizeMinus = Instance.new("TextButton")
SizeMinus.Size = UDim2.new(0, 20, 1, 0)
SizeMinus.Position = UDim2.new(0, 0, 0, 0)
SizeMinus.BackgroundTransparency = 1
SizeMinus.Font = Enum.Font.GothamBold
SizeMinus.TextSize = 13
SizeMinus.TextColor3 = THEME.Accent
SizeMinus.Text = "-"
SizeMinus.Parent = SizeControl

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -40, 1, 0)
SizeLabel.Position = UDim2.new(0, 20, 0, 0)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Font = Enum.Font.GothamBold
SizeLabel.TextSize = 10
SizeLabel.TextColor3 = THEME.TextMain
SizeLabel.Text = tostring(reachSize) .. "s"
SizeLabel.Parent = SizeControl

local SizePlus = Instance.new("TextButton")
SizePlus.Size = UDim2.new(0, 20, 1, 0)
SizePlus.Position = UDim2.new(1, -20, 0, 0)
SizePlus.BackgroundTransparency = 1
SizePlus.Font = Enum.Font.GothamBold
SizePlus.TextSize = 13
SizePlus.TextColor3 = THEME.Accent
SizePlus.Text = "+"
SizePlus.Parent = SizeControl

-- Dropdown Scrolling Panel (Anchored directly under MainCard)
local DropdownList = Instance.new("ScrollingFrame")
DropdownList.Name = "DropdownList"
DropdownList.Size = UDim2.new(1, 0, 0, 140)
DropdownList.Position = UDim2.new(0, 0, 1, 6)
DropdownList.BackgroundColor3 = THEME.BgPrimary
DropdownList.BackgroundTransparency = 0.05
DropdownList.BorderSizePixel = 0
DropdownList.ScrollBarThickness = 3
DropdownList.ScrollBarImageColor3 = THEME.Accent
DropdownList.Visible = false
DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
DropdownList.Parent = MainCard

local DropListCorner = Instance.new("UICorner")
DropListCorner.CornerRadius = UDim.new(0, 8)
DropListCorner.Parent = DropdownList

local DropListStroke = Instance.new("UIStroke")
DropListStroke.Thickness = 1
DropListStroke.Color = THEME.Border
DropListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DropListStroke.Parent = DropdownList

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = DropdownList

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 6)
ListPadding.PaddingBottom = UDim.new(0, 6)
ListPadding.PaddingLeft = UDim.new(0, 6)
ListPadding.PaddingRight = UDim.new(0, 6)
ListPadding.Parent = DropdownList

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
-- REACH EXECUTION LOGIC
-- ============================================================================
local function applyReach(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then return end

	if not originalProperties[tool] then
		originalProperties[tool] = {
			Size = handle.Size,
			GripPos = tool.GripPos,
			CanCollide = handle.CanCollide,
			Massless = handle.Massless,
		}
	end

	-- Apply reach properties with anti-fling physics settings
	handle.Size = Vector3.new(0.5, 0.5, reachSize)
	handle.CanCollide = false
	handle.Massless = true
	handle.CanTouch = true
	tool.GripPos = Vector3.zero

	-- Visual adornment
	local selectionBox = handle:FindFirstChild("ReachSelection")
	if not selectionBox then
		local newBox = Instance.new("SelectionBox")
		newBox.Name = "ReachSelection"
		newBox.Adornee = handle
		newBox.Color3 = THEME.Accent
		newBox.LineThickness = 0.05
		newBox.SurfaceColor3 = THEME.Accent
		newBox.SurfaceTransparency = 0.8
		newBox.Parent = handle
	end
end

local function restoreReach(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	local orig = originalProperties[tool]

	if handle and handle:IsA("BasePart") and orig then
		handle.Size = orig.Size
		handle.CanCollide = orig.CanCollide
		handle.Massless = orig.Massless
		tool.GripPos = orig.GripPos

		local box = handle:FindFirstChild("ReachSelection")
		if box then
			box:Destroy()
		end
	end

	originalProperties[tool] = nil
end

-- Refresh dropdown items
local function updateDropdown()
	for _, child in ipairs(DropdownList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local discoveredTools: { [string]: boolean } = {}
	local containers = { LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character }

	for _, container in ipairs(containers) do
		if container then
			for _, obj in ipairs(container:GetChildren()) do
				if obj:IsA("Tool") and not discoveredTools[obj.Name] then
					discoveredTools[obj.Name] = true
					local toolName = obj.Name
					local isEnabled = activeReachTools[toolName] == true

					local itemBtn = Instance.new("TextButton")
					itemBtn.Name = toolName
					itemBtn.Size = UDim2.new(1, 0, 0, 26)
					itemBtn.BackgroundColor3 = isEnabled and THEME.AccentDim or THEME.BgCard
					itemBtn.Font = Enum.Font.GothamBold
					itemBtn.TextSize = 10
					itemBtn.TextColor3 = isEnabled and THEME.Accent or THEME.TextMuted
					itemBtn.Text = (isEnabled and "★ " or "") .. toolName .. (isEnabled and " [REACH ON]" or " [OFF]")
					itemBtn.AutoButtonColor = false
					itemBtn.Parent = DropdownList

					local c = Instance.new("UICorner")
					c.CornerRadius = UDim.new(0, 5)
					c.Parent = itemBtn

					local s = Instance.new("UIStroke")
					s.Thickness = 1
					s.Color = isEnabled and THEME.Border or THEME.BorderDim
					s.Transparency = isEnabled and 0.2 or 0.6
					s.Parent = itemBtn

					itemBtn.MouseButton1Click:Connect(function()
						if activeReachTools[toolName] then
							activeReachTools[toolName] = nil
							-- Find active instances of this tool
							local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
							local ch = LocalPlayer.Character
							local t1 = bp and bp:FindFirstChild(toolName)
							local t2 = ch and ch:FindFirstChild(toolName)
							if t1 and t1:IsA("Tool") then restoreReach(t1) end
							if t2 and t2:IsA("Tool") then restoreReach(t2) end
						else
							activeReachTools[toolName] = true
							local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
							local ch = LocalPlayer.Character
							local t1 = bp and bp:FindFirstChild(toolName)
							local t2 = ch and ch:FindFirstChild(toolName)
							if t1 and t1:IsA("Tool") then applyReach(t1) end
							if t2 and t2:IsA("Tool") then applyReach(t2) end
						end
						updateDropdown()
					end)
				end
			end
		end
	end
end

DropdownToggle.MouseButton1Click:Connect(function()
	DropdownList.Visible = not DropdownList.Visible
	DropdownToggle.Text = DropdownList.Visible and "SELECT TOOLS ▲" or "SELECT TOOLS ▼"
	if DropdownList.Visible then
		updateDropdown()
	end
end)

SizeMinus.MouseButton1Click:Connect(function()
	reachSize = math.clamp(reachSize - 2, 3, 30)
	SizeLabel.Text = tostring(reachSize) .. "s"
	-- Re-apply to all active reach tools
	local ch = LocalPlayer.Character
	if ch then
		for _, child in ipairs(ch:GetChildren()) do
			if child:IsA("Tool") and activeReachTools[child.Name] then
				applyReach(child)
			end
		end
	end
end)

SizePlus.MouseButton1Click:Connect(function()
	reachSize = math.clamp(reachSize + 2, 3, 30)
	SizeLabel.Text = tostring(reachSize) .. "s"
	local ch = LocalPlayer.Character
	if ch then
		for _, child in ipairs(ch:GetChildren()) do
			if child:IsA("Tool") and activeReachTools[child.Name] then
				applyReach(child)
			end
		end
	end
end)

-- Character & Backpack listeners
local function hookBackpack(backpack: Backpack)
	backpack.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") and activeReachTools[child.Name] then
			applyReach(child)
		end
		if DropdownList.Visible then
			updateDropdown()
		end
	end)

	backpack.ChildRemoved:Connect(function()
		if DropdownList.Visible then
			task.defer(updateDropdown)
		end
	end)
end

local function hookCharacter(char: Model)
	char.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") and activeReachTools[child.Name] then
			applyReach(child)
		end
	end)

	char.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") then
			restoreReach(child)
		end
	end)
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
if bp then
	hookBackpack(bp)
end
LocalPlayer.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		hookBackpack(child)
	end
end)

print("[Reach] CIPHER // TOOL REACH SELECTOR V4.0 Loaded.")
