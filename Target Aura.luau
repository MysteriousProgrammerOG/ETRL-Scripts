-- ============================================================================
-- CIPHER // TYCOON TOOL GRABBER V7.0 (HEADLESS BACKGROUND SERVICE)
-- Strict Filtering: GearGiver1 ONLY from Robotic, Stone, Storm, and Magic
-- Headless Edition: Always Active, UI-less, Lightweight
-- ============================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Executor API Resolver
local fireTouch: ((BasePart, BasePart, number) -> ())? = (firetouchinterest :: any)
	or (getgenv and (getgenv().firetouchinterest or getgenv().fire_touch_interest))
	or (syn and syn.firetouchinterest)

-- Destroy any previous UI if left over
pcall(function()
	local core = game:GetService("CoreGui"):FindFirstChild("CipherToolGrabberUI")
	if core then core:Destroy() end
	local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pgui then
		local u = pgui:FindFirstChild("CipherToolGrabberUI")
		if u then u:Destroy() end
	end
end)

-- STRICT FILTER SETS: ONLY these 4 bases are allowed to give tools
local ALLOWED_BASES: { [string]: boolean } = {
	["Robotic"] = true,
	["Stone"]   = true,
	["Storm"]   = true,
	["Magic"]   = true,
}

-- EXCLUDED BASES: These bases are strictly blocked
local EXCLUDED_BASES: { [string]: boolean } = {
	["Web"]      = true,
	["Strong"]   = true,
	["Dark"]     = true,
	["Spike"]    = true,
	["Insanity"] = true,
	["Giant"]    = true,
}

local SWEEP_INTERVAL: number = 0.5
local tycoons: Instance = Workspace:FindFirstChild("Tycoons") or Workspace
local touchableParts: { BasePart } = {}
local currentRoot: BasePart? = nil
local lastSweepTime: number = 0

-- ============================================================================
-- STRICT FILTERING ENGINE
-- ============================================================================
local function isValidGearGiver(descendant: Instance): (boolean, string?)
	-- 1. Must be a TouchTransmitter inside a BasePart
	if not descendant:IsA("TouchTransmitter") then return false, nil end

	local touchPart = descendant.Parent
	if not (touchPart and touchPart:IsA("BasePart")) then return false, nil end

	-- 2. Must be directly inside GearGiver1 (strict name match: "geargiver1")
	local gearGiver = touchPart.Parent
	if not gearGiver then return false, nil end
	local giverName = string.lower(gearGiver.Name)
	if giverName ~= "geargiver1" then return false, nil end

	-- 3. Check ancestry to identify the base
	local current: Instance? = gearGiver.Parent
	local matchedBase: string? = nil

	while current and current ~= Workspace and current ~= game do
		local cName = string.lower(current.Name)

		-- Reject immediately if an excluded base name appears
		for excluded in pairs(EXCLUDED_BASES) do
			if string.find(cName, string.lower(excluded), 1, true) then
				return false, nil
			end
		end

		-- Check if an allowed base appears
		for allowed in pairs(ALLOWED_BASES) do
			if string.find(cName, string.lower(allowed), 1, true) then
				matchedBase = allowed
			end
		end

		current = current.Parent
	end

	-- ONLY accept if it belongs to one of the 4 allowed bases
	if matchedBase and ALLOWED_BASES[matchedBase] then
		return true, matchedBase
	end

	return false, nil
end

local function evaluateAndAdd(descendant: Instance)
	local isValid, _ = isValidGearGiver(descendant)
	if not isValid then return end

	local parent = descendant.Parent
	if not (parent and parent:IsA("BasePart")) then return end

	if not table.find(touchableParts, parent) then
		table.insert(touchableParts, parent)

		parent.AncestryChanged:Connect(function(_, newParent)
			if not newParent then
				local idx = table.find(touchableParts, parent)
				if idx then
					table.remove(touchableParts, idx)
				end
			end
		end)
	end
end

-- Scan tycoons
for _, inst in ipairs(tycoons:GetDescendants()) do
	evaluateAndAdd(inst)
end

tycoons.DescendantAdded:Connect(evaluateAndAdd)

if tycoons ~= Workspace then
	Workspace.DescendantAdded:Connect(function(inst)
		if string.lower(inst.Name) == "geargiver1" or inst:IsA("TouchTransmitter") then
			evaluateAndAdd(inst)
		end
	end)
end

-- ============================================================================
-- TOOL CLAIM DISPATCHER
-- ============================================================================
local function updateCharacterRoot(character: Model)
	currentRoot = (character:WaitForChild("HumanoidRootPart", 5) 
		or character:FindFirstChildWhichIsA("BasePart")) :: BasePart?
end

if LocalPlayer.Character then
	updateCharacterRoot(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
	updateCharacterRoot(char)
	-- Frame-0 Instant claim upon spawn
	if currentRoot and fireTouch then
		for i = 1, #touchableParts do
			local targetPart = touchableParts[i]
			if targetPart and targetPart.Parent then
				pcall(fireTouch, currentRoot, targetPart, 0)
				pcall(fireTouch, currentRoot, targetPart, 1)
			end
		end
	end
	-- Fast 0.05s retry for streaming assets
	task.delay(0.05, function()
		if currentRoot and fireTouch then
			for i = 1, #touchableParts do
				local targetPart = touchableParts[i]
				if targetPart and targetPart.Parent then
					pcall(fireTouch, currentRoot, targetPart, 0)
					pcall(fireTouch, currentRoot, targetPart, 1)
				end
			end
		end
	end)
end)
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

_G.GrabTools = fireAllTouches

-- Background low-frequency sweep (every 0.5s)
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastSweepTime < SWEEP_INTERVAL then return end
	lastSweepTime = now

	if currentRoot and currentRoot.Parent and #touchableParts > 0 then
		fireAllTouches()
	end
end)

print("⚡ [Tool Grabber] CIPHER // V7.0 Headless Loaded (Allowed Bases Only, Always Active).")
