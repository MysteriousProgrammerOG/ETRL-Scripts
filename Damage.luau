-- ============================================================================
-- CIPHER // HITBOX EXPANDER V5.0 (HEADLESS BACKGROUND SERVICE)
-- Persistent Hitbox Expander with Guaranteed Respawn & Loopbring Synergy
-- Headless Edition: Always Active, UI-less, Lightweight
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Destroy any previous UI if left over
pcall(function()
	local core = game:GetService("CoreGui"):FindFirstChild("CipherDamageUI")
	if core then core:Destroy() end
	local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pgui then
		local u = pgui:FindFirstChild("CipherDamageUI")
		if u then u:Destroy() end
	end
end)

-- Global API compatibility
_G.HitboxSize = _G.HitboxSize or 12
_G.Enabled = true

-- Anti-Jitter Zero-Mass Physical Properties (Eliminates all Loopbring physics conflict)
local ZERO_PHYSICS = PhysicalProperties.new(0.0001, 0, 0, 0, 0)

-- State & Caches
local activeVisuals: { [BasePart]: SelectionBox } = {}
local charConnections: { [Player]: { RBXScriptConnection } } = {}

-- ============================================================================
-- HIGH-PERFORMANCE HITBOX ENGINE
-- ============================================================================
local function applyHitboxToHRP(hrp: BasePart)
	if not _G.Enabled then return end
	if not (hrp and hrp.Parent) then return end

	local targetSize = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)

	if hrp.Size ~= targetSize then
		hrp.Size = targetSize
	end

	hrp.Transparency = 0.75
	hrp.Material = Enum.Material.ForceField

	-- CRITICAL FOR LOOPBRING & WEAPON DETECTION:
	-- CanCollide = false prevents pushing/flinging when brought near you
	hrp.CanCollide = false
	-- CanTouch & CanQuery = true ensures maximum weapon touch and hit registration
	hrp.CanTouch = true
	hrp.CanQuery = true
	hrp.Massless = true
	hrp.CustomPhysicalProperties = ZERO_PHYSICS

	-- Visual Box
	local box = activeVisuals[hrp] or hrp:FindFirstChild("HitboxVisual")
	if not box then
		local newBox = Instance.new("SelectionBox")
		newBox.Name = "HitboxVisual"
		newBox.Adornee = hrp
		newBox.LineThickness = 0.05
		newBox.Color3 = Color3.fromRGB(168, 85, 247) -- Cosmic Purple
		newBox.SurfaceColor3 = Color3.fromRGB(168, 85, 247)
		newBox.SurfaceTransparency = 0.82
		newBox.Parent = hrp
		activeVisuals[hrp] = newBox
	end
end

local function applyHitboxToPlayer(player: Player)
	if player == LocalPlayer then return end
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		applyHitboxToHRP(hrp)
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

		-- 2. ChildAdded listener for when HRP spawns in (Frame 0 + defer)
		table.insert(conns, char.ChildAdded:Connect(function(child: Instance)
			if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
				applyHitboxToHRP(child)
				task.defer(function()
					applyHitboxToHRP(child)
				end)
			end
		end))

		-- 3. Non-blocking retry loop for slow loads
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

print("⚡ [Damage/Hitbox] CIPHER // V5.0 Headless Loaded (Always Active, Loopbring Synergized).")
