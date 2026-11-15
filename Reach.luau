-- ============================================================================
-- CIPHER // UNIVERSAL TOOL REACH ENGINE V5.0 (HEADLESS BACKGROUND SERVICE)
-- Extended Tool Range for All Equipped Weapons (Zero UI Overhead)
-- Headless Edition: Always Active for All Tools, Mobile Optimized
-- ============================================================================

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Destroy any previous UI if left over
pcall(function()
	local core = game:GetService("CoreGui"):FindFirstChild("CipherReachUI")
	if core then core:Destroy() end
	local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pgui then
		local u = pgui:FindFirstChild("CipherReachUI")
		if u then u:Destroy() end
	end
end)

-- Global Configuration & State
_G.ReachEnabled = true
_G.ReachSize = _G.ReachSize or 15

local modifiedTools: { [Tool]: boolean } = {}

-- ============================================================================
-- UNIVERSAL REACH APPLICATION
-- ============================================================================
local function applyReach(tool: Tool)
	if not _G.ReachEnabled then return end
	if not tool:IsA("Tool") then return end

	local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
	if not (handle and handle:IsA("BasePart")) then return end

	-- Anti-fling physics settings
	handle.CanCollide = false
	handle.Massless = true
	handle.CanTouch = true
	handle.Size = Vector3.new(0.5, 0.5, _G.ReachSize)
	tool.GripPos = Vector3.zero

	-- Cosmic visual indicator on the blade/handle
	local selectionBox = handle:FindFirstChild("ReachSelection")
	if not selectionBox then
		local newBox = Instance.new("SelectionBox")
		newBox.Name = "ReachSelection"
		newBox.Adornee = handle
		newBox.Color3 = Color3.fromRGB(168, 85, 247) -- Cosmic Purple
		newBox.LineThickness = 0.04
		newBox.SurfaceColor3 = Color3.fromRGB(168, 85, 247)
		newBox.SurfaceTransparency = 0.85
		newBox.Parent = handle
	end

	modifiedTools[tool] = true
end

local function scanContainer(container: Instance?)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			applyReach(child)
		end
	end
end

-- ============================================================================
-- LIFECYCLE LISTENERS
-- ============================================================================
local function hookBackpack(backpack: Backpack)
	scanContainer(backpack)
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			applyReach(child)
		end
	end)
end

local function hookCharacter(char: Model)
	scanContainer(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			applyReach(child)
			task.defer(function()
				applyReach(child)
			end)
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

print("⚡ [Reach] CIPHER // V5.0 Headless Loaded (Always Active for All Tools).")
