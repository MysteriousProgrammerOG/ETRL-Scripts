--!strict
-- ============================================================================
-- CIPHER // ULTRA ANTI-LAG & FPS BOOSTER V5.0 (MODERN RESCRIPT)
-- High-Performance Client Optimizer with Full State Restoration & Clean UI
-- ============================================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Terrain = Workspace.Terrain

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

local TOGGLE_KEY = Enum.KeyCode.P
local BoostActive = true

-- ============================================================================
-- SAFE GUI RESOLVER (CoreGui or PlayerGui fallback)
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
local existing = guiContainer:FindFirstChild("CipherAntiLagUI")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- MODERN LIGHTWEIGHT DRAGGABLE UI
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CipherAntiLagUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiContainer

local MainCard = Instance.new("Frame")
MainCard.Name = "MainCard"
MainCard.Size = UDim2.fromOffset(230, 62)
MainCard.Position = UDim2.new(0.03, 0, 0.65, 0)
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
HeaderTitle.Text = "⚡ ANTI-LAG // FPS BOOSTER [P]"
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
ToggleButton.Text = "FPS BOOST: ACTIVE"
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

-- Universal Smooth Draggable Function
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

-- Button Hover Animations
ToggleButton.MouseEnter:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.12), {BackgroundColor3 = THEME.AccentDim}):Play()
end)
ToggleButton.MouseLeave:Connect(function()
	TweenService:Create(ToggleButton, TweenInfo.new(0.12), {BackgroundColor3 = THEME.BgCard}):Play()
end)

local function updateUI()
	if BoostActive then
		ToggleButton.Text = "FPS BOOST: ACTIVE"
		ToggleButton.TextColor3 = THEME.ActiveGreen
		StatusDot.BackgroundColor3 = THEME.ActiveGreen
		CardStroke.Color = THEME.Border
	else
		ToggleButton.Text = "FPS BOOST: OFF [P]"
		ToggleButton.TextColor3 = THEME.TextMuted
		StatusDot.BackgroundColor3 = THEME.BorderDim
		CardStroke.Color = THEME.BorderDim
	end
end

-- ============================================================================
-- STATE BACKUP & RESTORATION ENGINE
-- ============================================================================
type OriginalPartData = {
	Material: Enum.Material,
	Reflectance: number,
	CastShadow: boolean,
}

local originalLighting = {
	GlobalShadows = Lighting.GlobalShadows,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	Brightness = Lighting.Brightness,
	ExposureCompensation = Lighting.ExposureCompensation,
}

local originalTerrain = Terrain and {
	WaterWaveSize = Terrain.WaterWaveSize,
	WaterWaveSpeed = Terrain.WaterWaveSpeed,
	WaterReflectance = Terrain.WaterReflectance,
	WaterTransparency = Terrain.WaterTransparency,
} or nil

local originalPartProps: { [BasePart]: OriginalPartData } = {}
local disabledEffects: { [Instance]: boolean } = {}
local hiddenDecals: { [Decal]: number } = {}

-- ============================================================================
-- HIGH-PERFORMANCE OPTIMIZATION ENGINE
-- ============================================================================
local function optimizeLighting()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.FogStart = 9e9
		Lighting.Brightness = 1
		Lighting.ExposureCompensation = 0

		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") and v.Enabled then
				disabledEffects[v] = true
				v.Enabled = false
			end
		end
	end)

	pcall(function()
		if Terrain then
			Terrain.WaterWaveSize = 0
			Terrain.WaterWaveSpeed = 0
			Terrain.WaterReflectance = 0
			Terrain.WaterTransparency = 1
		end
	end)

	pcall(function()
		if typeof(settings) == "function" then
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end
	end)
end

local function restoreLighting()
	pcall(function()
		Lighting.GlobalShadows = originalLighting.GlobalShadows
		Lighting.FogEnd = originalLighting.FogEnd
		Lighting.FogStart = originalLighting.FogStart
		Lighting.Brightness = originalLighting.Brightness
		Lighting.ExposureCompensation = originalLighting.ExposureCompensation

		for effect, wasEnabled in pairs(disabledEffects) do
			if effect and effect.Parent and wasEnabled then
				(effect :: PostEffect).Enabled = true
			end
		end
		table.clear(disabledEffects)
	end)

	pcall(function()
		if Terrain and originalTerrain then
			Terrain.WaterWaveSize = originalTerrain.WaterWaveSize
			Terrain.WaterWaveSpeed = originalTerrain.WaterWaveSpeed
			Terrain.WaterReflectance = originalTerrain.WaterReflectance
			Terrain.WaterTransparency = originalTerrain.WaterTransparency
		end
	end)
end

local function simplifyObject(obj: Instance)
	if not BoostActive then return end

	-- Skip player characters to preserve character meshes/animations
	local char = LocalPlayer.Character
	if char and obj:IsDescendantOf(char) then return end

	if obj:IsA("BasePart") then
		if not originalPartProps[obj] then
			originalPartProps[obj] = {
				Material = obj.Material,
				Reflectance = obj.Reflectance,
				CastShadow = obj.CastShadow,
			}
		end
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
		obj.CastShadow = false
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		if not hiddenDecals[obj] then
			hiddenDecals[obj] = obj.Transparency
		end
		obj.Transparency = 1
	elseif obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles") then
		if obj.Enabled then
			disabledEffects[obj] = true
			obj.Enabled = false
		end
	elseif obj:IsA("Highlight") or obj:IsA("Beam") then
		obj.Enabled = false
	end
end

local function restoreObjects()
	for part, props in pairs(originalPartProps) do
		if part and part.Parent then
			part.Material = props.Material
			part.Reflectance = props.Reflectance
			part.CastShadow = props.CastShadow
		end
	end
	table.clear(originalPartProps)

	for decal, originalTrans in pairs(hiddenDecals) do
		if decal and decal.Parent then
			decal.Transparency = originalTrans
		end
	end
	table.clear(hiddenDecals)

	for effect in pairs(disabledEffects) do
		if effect and effect.Parent then
			pcall(function()
				(effect :: any).Enabled = true
			end)
		end
	end
	table.clear(disabledEffects)
end

-- Efficient chunked workspace scan
local function runBatchOptimization()
	optimizeLighting()
	local descendants = Workspace:GetDescendants()
	for i = 1, #descendants do
		simplifyObject(descendants[i])
	end
end

-- Dynamic listener for newly spawned map elements
local descendantConnection: RBXScriptConnection? = nil

local function enableBoost()
	BoostActive = true
	runBatchOptimization()
	if not descendantConnection then
		descendantConnection = Workspace.DescendantAdded:Connect(function(inst: Instance)
			if BoostActive then
				simplifyObject(inst)
			end
		end)
	end
	updateUI()
end

local function disableBoost()
	BoostActive = false
	if descendantConnection then
		descendantConnection:Disconnect()
		descendantConnection = nil
	end
	restoreLighting()
	restoreObjects()
	updateUI()
end

local function toggleBoost()
	if BoostActive then
		disableBoost()
	else
		enableBoost()
	end
end

ToggleButton.MouseButton1Click:Connect(toggleBoost)

UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.KeyCode == TOGGLE_KEY then
		toggleBoost()
	end
end)

-- Initial run
enableBoost()

print("[Anti-Lag] CIPHER // ANTI-LAG & FPS BOOSTER V5.0 initialized.")
