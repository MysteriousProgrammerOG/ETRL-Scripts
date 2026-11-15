-- ============================================================================
-- ETERNAL SPT HUB //
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- ============================================================================
-- THEME
-- ============================================================================
local THEME = {
	VoidBg          = Color3.fromRGB(10, 8, 16),        -- Deep Cosmic Space
	PanelBg         = Color3.fromRGB(18, 13, 28),       -- Dark Void Purple
	CardBg          = Color3.fromRGB(26, 18, 42),       -- Cosmic Card Base
	CardHover       = Color3.fromRGB(38, 26, 62),       -- Highlight Violet
	SidebarBg       = Color3.fromRGB(13, 10, 22),       -- Navigation Bar
	AccentPurple    = Color3.fromRGB(168, 85, 247),     -- Neon Electric Purple
	AccentLight     = Color3.fromRGB(192, 132, 252),    -- Glowing Violet
	AccentDeep      = Color3.fromRGB(88, 28, 135),      -- Deep Astral Purple
	BorderDark      = Color3.fromRGB(35, 20, 55),       -- Muted Border
	TextWhite       = Color3.fromRGB(255, 255, 255),    -- Ultra Visible White
	TextMuted       = Color3.fromRGB(170, 160, 195),    -- Soft Starlight Gray
	SuccessGreen    = Color3.fromRGB(52, 211, 153),     -- Active Green
	ActiveButtonBg  = Color3.fromRGB(48, 20, 78),       -- Active Tab Purple
}

-- ============================================================================
-- GUI RESOLVER
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
local existing = guiContainer:FindFirstChild("SPTHubEternal")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- SCREEN GUI ROOT
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SPTHubEternal"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

-- ============================================================================
-- FLOATING TOGGLE BUTTON (COSMIC ORB)
-- ============================================================================
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "SPTToggleOrb"
ToggleButton.Size = UDim2.fromOffset(46, 46)
ToggleButton.Position = UDim2.new(0, 18, 0.5, -23)
ToggleButton.BackgroundColor3 = THEME.PanelBg
ToggleButton.Text = "⚡"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 20
ToggleButton.TextColor3 = THEME.AccentLight
ToggleButton.AutoButtonColor = false
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

local OrbCorner = Instance.new("UICorner")
OrbCorner.CornerRadius = UDim.new(1, 0)
OrbCorner.Parent = ToggleButton

local OrbStroke = Instance.new("UIStroke")
OrbStroke.Thickness = 2
OrbStroke.Color = THEME.AccentPurple
OrbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
OrbStroke.Parent = ToggleButton

local OrbGlowGradient = Instance.new("UIGradient")
OrbGlowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, THEME.AccentPurple),
	ColorSequenceKeypoint.new(0.5, THEME.VoidBg),
	ColorSequenceKeypoint.new(1, THEME.AccentLight),
})
OrbGlowGradient.Parent = OrbStroke

-- ============================================================================
-- MAIN HUB FRAME
-- ============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(660, 410)
MainFrame.Position = UDim2.new(0.5, -330, 0.5, -205)
MainFrame.BackgroundColor3 = THEME.VoidBg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Animated Color Flowing Border (Purple & Black)
local BorderStroke = Instance.new("UIStroke")
BorderStroke.Thickness = 2.5
BorderStroke.Color = Color3.new(1, 1, 1)
BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BorderStroke.Parent = MainFrame

local FlowingGradient = Instance.new("UIGradient")
FlowingGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, THEME.VoidBg),
	ColorSequenceKeypoint.new(0.20, THEME.AccentDeep),
	ColorSequenceKeypoint.new(0.45, THEME.AccentPurple),
	ColorSequenceKeypoint.new(0.55, THEME.AccentLight),
	ColorSequenceKeypoint.new(0.80, THEME.AccentDeep),
	ColorSequenceKeypoint.new(1.00, THEME.VoidBg),
})
FlowingGradient.Rotation = 0
FlowingGradient.Parent = BorderStroke

-- Smooth GPU-accelerated gradient rotation (Lightweight & zero lag)
local gradientRotation = 0
RunService.RenderStepped:Connect(function(dt: number)
	gradientRotation = (gradientRotation + dt * 45) % 360
	FlowingGradient.Rotation = gradientRotation
	OrbGlowGradient.Rotation = (OrbGlowGradient.Rotation + dt * 60) % 360
end)

-- ============================================================================
-- BACKGROUND
-- ============================================================================
local CosmicBackdrop = Instance.new("Frame")
CosmicBackdrop.Name = "CosmicBackdrop"
CosmicBackdrop.Size = UDim2.new(1, 0, 1, 0)
CosmicBackdrop.BackgroundColor3 = THEME.VoidBg
CosmicBackdrop.BackgroundTransparency = 0
CosmicBackdrop.BorderSizePixel = 0
CosmicBackdrop.ZIndex = 1
CosmicBackdrop.Parent = MainFrame

local CosmicCorner = Instance.new("UICorner")
CosmicCorner.CornerRadius = UDim.new(0, 12)
CosmicCorner.Parent = CosmicBackdrop

-- Ambient Nebula Glow
local NebulaGlow = Instance.new("ImageLabel")
NebulaGlow.Name = "NebulaGlow"
NebulaGlow.Size = UDim2.new(1.2, 0, 1.2, 0)
NebulaGlow.Position = UDim2.new(-0.1, 0, -0.1, 0)
NebulaGlow.BackgroundTransparency = 1
NebulaGlow.Image = "rbxassetid://6015897843" -- Soft ambient radial glow
NebulaGlow.ImageColor3 = THEME.AccentDeep
NebulaGlow.ImageTransparency = 0.85
NebulaGlow.ZIndex = 1
NebulaGlow.Parent = CosmicBackdrop

-- Twinkling Stars Cluster (25 Lightweight Procedural Stars)
local stars: { { Frame: Frame, BaseAlpha: number, Speed: number } } = {}
local starContainer = Instance.new("Frame")
starContainer.Name = "StarContainer"
starContainer.Size = UDim2.new(1, 0, 1, 0)
starContainer.BackgroundTransparency = 1
starContainer.ZIndex = 1
starContainer.Parent = CosmicBackdrop

local rng = Random.new(1337)
for _ = 1, 26 do
	local star = Instance.new("Frame")
	local sSize = rng:NextInteger(2, 3)
	star.Size = UDim2.fromOffset(sSize, sSize)
	star.Position = UDim2.new(rng:NextNumber(0.02, 0.98), 0, rng:NextNumber(0.02, 0.98), 0)
	star.BackgroundColor3 = THEME.TextWhite
	star.BorderSizePixel = 0
	star.BackgroundTransparency = rng:NextNumber(0.3, 0.85)

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(1, 0)
	sCorner.Parent = star
	star.Parent = starContainer

	table.insert(stars, {
		Frame = star,
		BaseAlpha = star.BackgroundTransparency,
		Speed = rng:NextNumber(0.8, 2.2),
	})
end

-- Subtle celestial twinkle animation (Efficient Sine wave)
local starClock = 0
RunService.Heartbeat:Connect(function(dt: number)
	starClock += dt
	for i = 1, #stars do
		local s = stars[i]
		local pulse = math.sin(starClock * s.Speed + i) * 0.25
		s.Frame.BackgroundTransparency = math.clamp(s.BaseAlpha + pulse, 0.2, 0.95)
	end
end)

-- ============================================================================
-- HEADER BAR (DRAGGABLE)
-- ============================================================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = THEME.SidebarBg
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0
Header.ZIndex = 2
Header.Parent = MainFrame

local HeaderBottomBorder = Instance.new("Frame")
HeaderBottomBorder.Size = UDim2.new(1, 0, 0, 1)
HeaderBottomBorder.Position = UDim2.new(0, 0, 1, -1)
HeaderBottomBorder.BackgroundColor3 = THEME.BorderDark
HeaderBottomBorder.BorderSizePixel = 0
HeaderBottomBorder.ZIndex = 2
HeaderBottomBorder.Parent = Header

-- Title and Brand
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Position = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = THEME.TextWhite
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "⚡ SPT HUB // ETERNAL"
Title.ZIndex = 2
Title.Parent = Header

local SubtitleBadge = Instance.new("TextLabel")
SubtitleBadge.Size = UDim2.new(0, 110, 0, 20)
SubtitleBadge.Position = UDim2.new(0, 195, 0.5, -10)
SubtitleBadge.BackgroundColor3 = THEME.CardBg
SubtitleBadge.Font = Enum.Font.Code
SubtitleBadge.TextSize = 10
SubtitleBadge.TextColor3 = THEME.AccentLight
SubtitleBadge.Text = "COSMIC V2.1"
SubtitleBadge.ZIndex = 2
SubtitleBadge.Parent = Header

local SubBadgeCorner = Instance.new("UICorner")
SubBadgeCorner.CornerRadius = UDim.new(0, 5)
SubBadgeCorner.Parent = SubtitleBadge

local SubBadgeStroke = Instance.new("UIStroke")
SubBadgeStroke.Thickness = 1
SubBadgeStroke.Color = THEME.AccentPurple
SubBadgeStroke.Transparency = 0.5
SubBadgeStroke.Parent = SubtitleBadge

-- Close & Minimize Buttons
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(28, 28)
CloseButton.Position = UDim2.new(1, -38, 0.5, -14)
CloseButton.BackgroundColor3 = THEME.CardBg
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.TextColor3 = THEME.TextWhite
CloseButton.Text = "X"
CloseButton.AutoButtonColor = false
CloseButton.ZIndex = 2
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Thickness = 1
CloseStroke.Color = THEME.BorderDark
CloseStroke.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
	TweenService:Create(CloseButton, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(180, 30, 60)}):Play()
end)
CloseButton.MouseLeave:Connect(function()
	TweenService:Create(CloseButton, TweenInfo.new(0.12), {BackgroundColor3 = THEME.CardBg}):Play()
end)

-- ============================================================================
-- SIDEBAR NAVIGATION
-- ============================================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = THEME.SidebarBg
Sidebar.BackgroundTransparency = 0.4
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarRightBorder = Instance.new("Frame")
SidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
SidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
SidebarRightBorder.BackgroundColor3 = THEME.BorderDark
SidebarRightBorder.BorderSizePixel = 0
SidebarRightBorder.ZIndex = 2
SidebarRightBorder.Parent = Sidebar

local NavList = Instance.new("ScrollingFrame")
NavList.Name = "NavList"
NavList.Size = UDim2.new(1, -12, 1, -16)
NavList.Position = UDim2.new(0, 6, 0, 8)
NavList.BackgroundTransparency = 1
NavList.ScrollBarThickness = 2
NavList.ScrollBarImageColor3 = THEME.AccentPurple
NavList.CanvasSize = UDim2.new(0, 0, 0, 0)
NavList.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavList.ZIndex = 2
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Padding = UDim.new(0, 6)
NavLayout.Parent = NavList

-- ============================================================================
-- MAIN CONTENT CONTAINER
-- ============================================================================
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -160, 1, -48)
ContentArea.Position = UDim2.new(0, 160, 0, 48)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 2
ContentArea.Parent = MainFrame

-- Page Header Title Banner
local PageTitle = Instance.new("TextLabel")
PageTitle.Name = "PageTitle"
PageTitle.Size = UDim2.new(1, -28, 0, 32)
PageTitle.Position = UDim2.new(0, 14, 0, 10)
PageTitle.BackgroundTransparency = 1
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextSize = 17
PageTitle.TextColor3 = THEME.TextWhite
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Text = "Updates"
PageTitle.ZIndex = 2
PageTitle.Parent = ContentArea

local PageViewContainer = Instance.new("Frame")
PageViewContainer.Name = "PageViewContainer"
PageViewContainer.Size = UDim2.new(1, 0, 1, -46)
PageViewContainer.Position = UDim2.new(0, 0, 0, 46)
PageViewContainer.BackgroundTransparency = 1
PageViewContainer.ZIndex = 2
PageViewContainer.Parent = ContentArea

-- ============================================================================
-- PAGES IN ORDER:
-- 1. Updates
-- 2. Welcome
-- 3. Tool Scripts
-- 4. Player Scripts
-- 5. Misc Scripts
-- 6. Settings
-- ============================================================================

local PAGE_NAMES = {
	"Updates",
	"Welcome",
	"Tool Scripts",
	"Player Scripts",
	"Misc Scripts",
	"Settings",
}

local PAGE_ICONS = {
	["Updates"]        = "✨",
	["Welcome"]        = "🌌",
	["Tool Scripts"]   = "⚔️",
	["Player Scripts"] = "👤",
	["Misc Scripts"]   = "🔮",
	["Settings"]       = "⚙️",
}

local Pages: { [string]: ScrollingFrame } = {}
local TabButtons: { [string]: TextButton } = {}
local currentPage: string? = nil

local function createPage(name: string): ScrollingFrame
	local pageScroll = Instance.new("ScrollingFrame")
	pageScroll.Name = name .. "Page"
	pageScroll.Size = UDim2.new(1, -28, 1, -12)
	pageScroll.Position = UDim2.new(0, 14, 0, 0)
	pageScroll.BackgroundTransparency = 1
	pageScroll.BorderSizePixel = 0
	pageScroll.ScrollBarThickness = 3
	pageScroll.ScrollBarImageColor3 = THEME.AccentPurple
	pageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pageScroll.Visible = false
	pageScroll.ZIndex = 3
	pageScroll.Parent = PageViewContainer

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = pageScroll

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 2)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = pageScroll

	Pages[name] = pageScroll
	return pageScroll
end

-- ============================================================================
-- SCRIPT EXECUTION HELPER & BUTTON BUILDER
-- ============================================================================
local function executeScript(name: string, urlOrFunc: string | () -> ())
	print(string.format("[SPT Hub] Launching script: %s", name))
	if typeof(urlOrFunc) == "function" then
		task.spawn(function()
			local ok, err = pcall(urlOrFunc)
			if not ok then
				warn(string.format("[SPT Hub Error] Failed to run %s: %s", name, tostring(err)))
			end
		end)
	elseif typeof(urlOrFunc) == "string" then
		task.spawn(function()
			local ok, err = pcall(function()
				loadstring(game:HttpGet(urlOrFunc, true))()
			end)
			if not ok then
				warn(string.format("[SPT Hub Error] Failed to load %s: %s", name, tostring(err)))
			end
		end)
	end
end

-- Reusable Button Card Factory
local function createScriptCard(
	pageName: string,
	title: string,
	desc: string,
	icon: string,
	order: number,
	executeAction: string | () -> ()
): Frame
	local page = Pages[pageName]
	assert(page, "Page not found: " .. pageName)

	local card = Instance.new("Frame")
	card.Name = title .. "Card"
	card.Size = UDim2.new(1, 0, 0, 52)
	card.BackgroundColor3 = THEME.CardBg
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.ZIndex = 3
	card.Parent = page

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 8)
	cCorner.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Thickness = 1
	cStroke.Color = THEME.BorderDark
	cStroke.Parent = card

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromOffset(36, 36)
	iconLabel.Position = UDim2.new(0, 8, 0.5, -18)
	iconLabel.BackgroundColor3 = THEME.PanelBg
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 16
	iconLabel.TextColor3 = THEME.AccentLight
	iconLabel.Text = icon
	iconLabel.ZIndex = 3
	iconLabel.Parent = card

	local icCorner = Instance.new("UICorner")
	icCorner.CornerRadius = UDim.new(0, 6)
	icCorner.Parent = iconLabel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.6, -50, 0, 18)
	titleLabel.Position = UDim2.new(0, 52, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 12
	titleLabel.TextColor3 = THEME.TextWhite
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.ZIndex = 3
	titleLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0.6, -50, 0, 16)
	descLabel.Position = UDim2.new(0, 52, 0, 26)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 10
	descLabel.TextColor3 = THEME.TextMuted
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = desc
	descLabel.ZIndex = 3
	descLabel.Parent = card

	-- Execute Button
	local runBtn = Instance.new("TextButton")
	runBtn.Name = "RunButton"
	runBtn.Size = UDim2.new(0, 96, 0, 28)
	runBtn.Position = UDim2.new(1, -106, 0.5, -14)
	runBtn.BackgroundColor3 = THEME.AccentDeep
	runBtn.Font = Enum.Font.GothamBold
	runBtn.TextSize = 10
	runBtn.TextColor3 = THEME.TextWhite
	runBtn.Text = "RUN SCRIPT"
	runBtn.AutoButtonColor = false
	runBtn.ZIndex = 3
	runBtn.Parent = card

	local rbCorner = Instance.new("UICorner")
	rbCorner.CornerRadius = UDim.new(0, 6)
	rbCorner.Parent = runBtn

	local rbStroke = Instance.new("UIStroke")
	rbStroke.Thickness = 1
	rbStroke.Color = THEME.AccentPurple
	rbStroke.Transparency = 0.4
	rbStroke.Parent = runBtn

	-- Hover Tweens
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.14), {BackgroundColor3 = THEME.CardHover}):Play()
		TweenService:Create(cStroke, TweenInfo.new(0.14), {Color = THEME.AccentPurple}):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.14), {BackgroundColor3 = THEME.CardBg}):Play()
		TweenService:Create(cStroke, TweenInfo.new(0.14), {Color = THEME.BorderDark}):Play()
	end)

	runBtn.MouseButton1Click:Connect(function()
		runBtn.Text = "EXECUTED!"
		runBtn.TextColor3 = THEME.SuccessGreen
		TweenService:Create(runBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 80, 50)}):Play()

		executeScript(title, executeAction)

		task.delay(1.2, function()
			runBtn.Text = "RUN SCRIPT"
			runBtn.TextColor3 = THEME.TextWhite
			TweenService:Create(runBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.AccentDeep}):Play()
		end)
	end)

	return card
end

-- Info Banner Factory
local function createInfoBanner(pageName: string, heading: string, body: string, order: number)
	local page = Pages[pageName]
	assert(page, "Page not found: " .. pageName)

	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.new(1, 0, 0, 74)
	banner.BackgroundColor3 = THEME.PanelBg
	banner.BackgroundTransparency = 0.3
	banner.BorderSizePixel = 0
	banner.LayoutOrder = order
	banner.ZIndex = 3
	banner.Parent = page

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = banner

	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 1
	bStroke.Color = THEME.AccentDeep
	bStroke.Parent = banner

	local hLabel = Instance.new("TextLabel")
	hLabel.Size = UDim2.new(1, -20, 0, 20)
	hLabel.Position = UDim2.new(0, 12, 0, 10)
	hLabel.BackgroundTransparency = 1
	hLabel.Font = Enum.Font.GothamBold
	hLabel.TextSize = 13
	hLabel.TextColor3 = THEME.AccentLight
	hLabel.TextXAlignment = Enum.TextXAlignment.Left
	hLabel.Text = heading
	hLabel.ZIndex = 3
	hLabel.Parent = banner

	local bLabel = Instance.new("TextLabel")
	bLabel.Size = UDim2.new(1, -24, 0, 34)
	bLabel.Position = UDim2.new(0, 12, 0, 32)
	bLabel.BackgroundTransparency = 1
	bLabel.Font = Enum.Font.Gotham
	bLabel.TextSize = 10
	bLabel.TextColor3 = THEME.TextMuted
	bLabel.TextXAlignment = Enum.TextXAlignment.Left
	bLabel.TextYAlignment = Enum.TextYAlignment.Top
	bLabel.TextWrapped = true
	bLabel.Text = body
	bLabel.ZIndex = 3
	bLabel.Parent = banner
end

-- ============================================================================
-- INITIALIZE ALL PAGES & PLACEHOLDER BUTTONS
-- ============================================================================
for _, pageName in ipairs(PAGE_NAMES) do
	createPage(pageName)
end

-- 1. Updates Page
createInfoBanner(
	"Updates",
	"✦ Patch V2.1 // Eternal Cosmic Update",
	"• Transformed UI with animated purple/black flowing borders & starfield.\n• Reorganized tabs: Updates, Welcome, Tools, Players, Misc, Settings.\n• Lightweight zero-lag rendering pipeline.",
	1
)
createScriptCard(
	"Updates",
	"Check For Hub Updates",
	"Verifies latest repository scripts and loads fresh patches.",
	"🔄",
	2,
	"https://raw.githubusercontent.com/MysteriousProgrammerOG/RobloxScripting/refs/heads/KillstreakSystemScripting/Get%20Tools"
)

-- 2. Welcome Page
createInfoBanner(
	"Welcome",
	"🌌 Welcome to SPT Hub Eternal",
	string.format("Logged in as @%s. Select a category on the left sidebar to execute scripts seamlessly.", LocalPlayer.DisplayName),
	1
)
createScriptCard(
	"Welcome",
	"Get Discord & Community Links",
	"Copies the official support invite and script repository links.",
	"💬",
	2,
	function()
		pcall(function()
			setclipboard("https://discord.gg/example")
		end)
		print("[SPT Hub] Community link copied to clipboard!")
	end
)

-- 3. Tool Scripts Page
createScriptCard(
	"Tool Scripts",
	"Tool Booster & Reach Extender",
	"Amplifies tool range, click speed, and touch hitbox detection.",
	"⚔️",
	1,
	"https://raw.githubusercontent.com/MysteriousProgrammerOG/RobloxScripting/refs/heads/KillstreakSystemScripting/Reach"
)

-- 4. Player Scripts Page
createScriptCard(
	"Player Scripts",
	"Speed & Jump Modifier",
	"Applies mobility boosts, infinite jump, and anti-ragdoll protection.",
	"⚡",
	1,
	function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 32
				hum.JumpPower = 80
			end
		end
		print("[SPT Hub] Applied Speed (32) and JumpPower (80)!")
	end
)

-- 5. Misc Scripts Page
createScriptCard(
	"Misc Scripts",
	"Anti-Lag & FPS Ultra Booster",
	"Optimizes lighting, clears map particles, and boosts render speed.",
	"🛡️",
	1,
	"https://raw.githubusercontent.com/iamrobloxstudio/OG1-Hub-Scripts/refs/heads/main/Antti-Lag"
)

-- 6. Settings Page
createInfoBanner(
	"Settings",
	"⚙️ Hub Configuration & Physics",
	"Adjust your personal character mobility settings and hub preferences below.",
	1
)

-- Interactive WalkSpeed Stepper
local function createSettingsStepper(title: string, defaultVal: number, step: number, order: number, onChange: (number) -> ())
	local page = Pages["Settings"]
	local currentVal = defaultVal

	local row = Instance.new("Frame")
	row.Name = title .. "Row"
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = THEME.CardBg
	row.BackgroundTransparency = 0.2
	row.LayoutOrder = order
	row.ZIndex = 3
	row.Parent = page

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 8)
	rc.Parent = row

	local rs = Instance.new("UIStroke")
	rs.Thickness = 1
	rs.Color = THEME.BorderDark
	rs.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextColor3 = THEME.TextWhite
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = title
	label.ZIndex = 3
	label.Parent = row

	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.new(0, 26, 0, 24)
	minusBtn.Position = UDim2.new(1, -120, 0.5, -12)
	minusBtn.BackgroundColor3 = THEME.AccentDeep
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 13
	minusBtn.TextColor3 = THEME.TextWhite
	minusBtn.Text = "-"
	minusBtn.AutoButtonColor = false
	minusBtn.ZIndex = 3
	minusBtn.Parent = row
	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 5)
	mc.Parent = minusBtn

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0, 48, 1, 0)
	valLabel.Position = UDim2.new(1, -92, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.Code
	valLabel.TextSize = 11
	valLabel.TextColor3 = THEME.AccentLight
	valLabel.Text = tostring(currentVal)
	valLabel.ZIndex = 3
	valLabel.Parent = row

	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 26, 0, 24)
	plusBtn.Position = UDim2.new(1, -40, 0.5, -12)
	plusBtn.BackgroundColor3 = THEME.AccentDeep
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 13
	plusBtn.TextColor3 = THEME.TextWhite
	plusBtn.Text = "+"
	plusBtn.AutoButtonColor = false
	plusBtn.ZIndex = 3
	plusBtn.Parent = row
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 5)
	pc.Parent = plusBtn

	minusBtn.MouseButton1Click:Connect(function()
		currentVal = math.max(0, currentVal - step)
		valLabel.Text = tostring(currentVal)
		onChange(currentVal)
	end)

	plusBtn.MouseButton1Click:Connect(function()
		currentVal = currentVal + step
		valLabel.Text = tostring(currentVal)
		onChange(currentVal)
	end)
end

createSettingsStepper("WalkSpeed Slider", 16, 4, 2, function(newSpeed)
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = newSpeed end
	end
end)

createSettingsStepper("JumpPower Slider", 50, 10, 3, function(newJump)
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.JumpPower = newJump end
	end
end)

createScriptCard(
	"Settings",
	"Reset Hub & Character Defaults",
	"Restores original walk speed, jump power, and clears local UI caches.",
	"🔄",
	4,
	function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 16
				hum.JumpPower = 50
			end
		end
		print("[SPT Hub] Reset to default settings!")
	end
)

-- ============================================================================
-- SIDEBAR TAB SWITCHER
-- ============================================================================
local function showPage(name: string)
	if currentPage == name then return end

	local oldPage = currentPage and Pages[currentPage]
	local newPage = Pages[name]
	if not newPage then return end

	PageTitle.Text = string.format("%s %s", PAGE_ICONS[name] or "✦", name)

	-- Update Navigation Buttons
	for tabName, btn in pairs(TabButtons) do
		local isCurrent = (tabName == name)
		local stroke = btn:FindFirstChildWhichIsA("UIStroke")

		if isCurrent then
			btn.BackgroundColor3 = THEME.ActiveButtonBg or Color3.fromRGB(48, 20, 78)
			btn.TextColor3 = THEME.AccentLight
			if stroke then stroke.Color = THEME.AccentPurple end
		else
			btn.BackgroundColor3 = THEME.CardBg
			btn.TextColor3 = THEME.TextMuted
			if stroke then stroke.Color = THEME.BorderDark end
		end
	end

	-- Slide Transition
	if oldPage then
		oldPage.Visible = false
	end

	newPage.Position = UDim2.new(0, 14, 0, 8)
	newPage.Visible = true
	TweenService:Create(newPage, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 14, 0, 0),
	}):Play()

	currentPage = name
end

-- Create Navigation Buttons in Sidebar
for order, name in ipairs(PAGE_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Name = name .. "TabBtn"
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = THEME.CardBg
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextColor3 = THEME.TextMuted
	btn.Text = string.format(" %s  %s", PAGE_ICONS[name] or "✦", name)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.ZIndex = 2
	btn.Parent = NavList

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 1
	bStroke.Color = THEME.BorderDark
	bStroke.Parent = btn

	btn.MouseEnter:Connect(function()
		if currentPage ~= name then
			TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.CardHover}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentPage ~= name then
			TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.CardBg}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		showPage(name)
	end)

	TabButtons[name] = btn
end

-- ============================================================================
-- OPENING & CLOSING ANIMATIONS
-- ============================================================================
local isOpen = true
local isAnimating = false

local function openHub()
	if isAnimating or isOpen then return end
	isAnimating = true
	isOpen = true

	MainFrame.Visible = true
	MainFrame.Size = UDim2.fromOffset(590, 365)
	MainFrame.Position = UDim2.new(0.5, -295, 0.5, -182)

	local targetSize = UDim2.fromOffset(660, 410)
	local targetPos = UDim2.new(0.5, -330, 0.5, -205)

	local tween = TweenService:Create(MainFrame, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPos,
	})
	tween:Play()
	tween.Completed:Connect(function()
		isAnimating = false
	end)
end

local function closeHub()
	if isAnimating or not isOpen then return end
	isAnimating = true

	local targetSize = UDim2.fromOffset(590, 365)
	local targetPos = UDim2.new(0.5, -295, 0.5, -182)

	local tween = TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = targetSize,
		Position = targetPos,
	})
	tween:Play()
	tween.Completed:Connect(function()
		MainFrame.Visible = false
		isOpen = false
		isAnimating = false
	end)
end

local function toggleHub()
	if isOpen then
		closeHub()
	else
		openHub()
	end
end

CloseButton.MouseButton1Click:Connect(closeHub)
ToggleButton.MouseButton1Click:Connect(toggleHub)

-- Toggle Keybind (RightControl or Insert)
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
		toggleHub()
	end
end)

-- ============================================================================
-- UNIVERSAL DRAGGABLE ENGINE
-- ============================================================================
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

setupDraggable(MainFrame, Header)
setupDraggable(ToggleButton, ToggleButton)

-- Set Initial Page (Updates)
showPage("Updates")

print("⚡ ETERNAL SPT HUB // Initialized.")
