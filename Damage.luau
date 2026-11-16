-- ============================================================================
-- CIPHER // HITBOX EXPANDER V9.0 (ULTIMATE RESPONSIVE HITBOX ENGINE)
-- Based on V3 Architecture: Per-Frame Instant Attachment // Zero Latency
-- Enhancements: Dual HRP+Torso Expansion // Fixed Property Errors // No Memory Leaks
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Global API compatibility
_G.HitboxSize = _G.HitboxSize or 14
_G.Enabled = if _G.Enabled ~= nil then _G.Enabled else true

-- Weak-keyed memory-safe cache (Automatically frees destroyed parts)
local modified: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" })
local playerCache: { Player } = {}
local cacheDirty: boolean = true

-- Vital combat parts to expand (Covers weapons that check HRP or Torso)
local TARGET_PARTS = {
	"HumanoidRootPart",
	"Torso",
	"UpperTorso",
}

-- ============================================================================
-- INSTANT HITBOX ATTACHMENT
-- ============================================================================
local function expandPart(part: BasePart)
	local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)

	pcall(function()
		if part.Size ~= targetSize then
			part.Size = targetSize
		end

		part.Transparency = 0.75
		part.Color = Color3.fromRGB(168, 85, 247) -- Cosmic Purple
		part.Material = Enum.Material.ForceField
		part.CanCollide = false
		part.CanTouch = true
		part.CanQuery = true

		-- Ensure SelectionBox exists and is properly styled
		local box = part:FindFirstChild("HitboxVisual") :: SelectionBox?
		if not box then
			local newBox = Instance.new("SelectionBox")
			newBox.Name = "HitboxVisual"
			newBox.Adornee = part
			newBox.LineThickness = 0.05
			newBox.Color3 = Color3.fromRGB(168, 85, 247)
			newBox.SurfaceColor3 = Color3.fromRGB(168, 85, 247)
			newBox.SurfaceTransparency = 0.75
			newBox.Parent = part
		end
	end)

	modified[part] = true
end

local function applyHitbox(player: Player)
	if player == LocalPlayer then return end
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		-- Fast check: only skip if already modified and size matches
		local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
		if not modified[hrp] or hrp.Size ~= targetSize then
			expandPart(hrp)
		end
	end

	-- Also expand Torso for weapons that check hit.Name == "Torso"
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if torso and torso:IsA("BasePart") then
		local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
		if not modified[torso] or torso.Size ~= targetSize then
			expandPart(torso)
		end
	end
end

-- ============================================================================
-- FAST PLAYER CACHE
-- ============================================================================
local function updatePlayerCache()
	table.clear(playerCache)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(playerCache, player)
		end
	end
	cacheDirty = false
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			applyHitbox(player)
		end)
	end)
	cacheDirty = true
end)

Players.PlayerRemoving:Connect(function()
	cacheDirty = true
end)

updatePlayerCache()

-- ============================================================================
-- PER-FRAME WATCHDOG (ZERO-DELAY RESPONSIVENESS)
-- Runs every frame via Heartbeat, catching spawns the microsecond they appear
-- ============================================================================
RunService.Heartbeat:Connect(function()
	if not _G.Enabled then return end

	if cacheDirty then
		updatePlayerCache()
	end

	for i = 1, #playerCache do
		applyHitbox(playerCache[i])
	end
end)

print("⚔️ CIPHER // HITBOX EXPANDER V9.0 (Ultimate Dual-Part Engine) Loaded.")
