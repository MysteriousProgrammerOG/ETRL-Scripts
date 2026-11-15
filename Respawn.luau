-- ============================================================================
-- CIPHER // FAST RESPAWN ENGINE V7.1 (SINGLE-PULSE HEADLESS SERVICE)
-- Guaranteed Guide() Remote Detection & Ultra-Early Death Insta-Spawn
-- Single-Pulse State Lock: Zero Spamming on Respawn // Fires Exactly Once
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Destroy any previous UI if left over
pcall(function()
	local core = game:GetService("CoreGui"):FindFirstChild("CipherRespawnUI")
	if core then core:Destroy() end
	local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pgui then
		local u = pgui:FindFirstChild("CipherRespawnUI")
		if u then u:Destroy() end
	end
end)

-- Settings
local HEALTH_THRESHOLD: number     = 40     -- Early trigger threshold
local BURST_DROP_THRESHOLD: number = 15     -- Sudden single-frame damage drop threshold

-- Strict Lifecycle State Machine
local hasFiredThisLife: boolean    = false  -- Locks out any spam until fully respawned & healthy
local activeCharConns: { RBXScriptConnection } = {}
local guideRemotes: { Instance }   = {}
local lastObservedHealth: number   = 100

local function disconnectCharConns()
	for _, c in ipairs(activeCharConns) do
		if c and c.Connected then
			c:Disconnect()
		end
	end
	table.clear(activeCharConns)
end

-- ============================================================================
-- GUIDE() & RESPAWN REMOTE DISCOVERY (ALL CONTAINERS)
-- ============================================================================
local function evaluateRemote(inst: Instance)
	if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
		local n = string.lower(inst.Name)
		if n == "guide"
			or string.find(n, "guide", 1, true)
			or string.find(n, "respawn", 1, true)
			or string.find(n, "loadchar", 1, true)
			or string.find(n, "spawn", 1, true) then
			if not table.find(guideRemotes, inst) then
				table.insert(guideRemotes, inst)
			end
		end
	end
end

local function discoverAllRemotes()
	table.clear(guideRemotes)

	for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
		evaluateRemote(inst)
	end
	for _, inst in ipairs(Workspace:GetDescendants()) do
		evaluateRemote(inst)
	end
	for _, inst in ipairs(LocalPlayer:GetDescendants()) do
		evaluateRemote(inst)
	end
end

discoverAllRemotes()

ReplicatedStorage.DescendantAdded:Connect(evaluateRemote)
Workspace.DescendantAdded:Connect(evaluateRemote)

-- ============================================================================
-- SINGLE-PULSE INSTA-SPAWN GUIDE DISPATCHER
-- ============================================================================
local function fireRespawnOnce(cause: string)
	if hasFiredThisLife then return end
	hasFiredThisLife = true -- STRICT LOCK: Never fires more than once per death

	disconnectCharConns()

	-- 1. Ensure remotes are found
	if #guideRemotes == 0 then
		discoverAllRemotes()
	end

	-- 2. Dispatch the Guide / Respawn remotes in one clean pulse
	for _, r in ipairs(guideRemotes) do
		if r and r.Parent then
			task.spawn(function()
				if r:IsA("RemoteEvent") then
					pcall(r.FireServer, r)
					pcall(r.FireServer, r, LocalPlayer)
					pcall(r.FireServer, r, "Respawn")
					pcall(r.FireServer, r, true)
				elseif r:IsA("RemoteFunction") then
					pcall(r.InvokeServer, r)
					pcall(r.InvokeServer, r, LocalPlayer)
				end
			end)
		end
	end

	-- 3. Direct lookup fallback for "Guide"
	local directGuide = ReplicatedStorage:FindFirstChild("Guide", true) 
		or Workspace:FindFirstChild("Guide", true)
	if directGuide then
		task.spawn(function()
			if directGuide:IsA("RemoteEvent") then
				pcall(directGuide.FireServer, directGuide)
			elseif directGuide:IsA("RemoteFunction") then
				pcall(directGuide.InvokeServer, directGuide)
			end
		end)
	end

	-- 4. Fast-equip hook / Global Guide trigger
	pcall(function()
		local g = _G.Guide or _G.FastEquip
		if typeof(g) == "function" then
			task.spawn(g)
		end
		local genv = typeof(getgenv) == "function" and getgenv()
		if genv and typeof(genv.Guide) == "function" then
			task.spawn(genv.Guide)
		end
	end)
end

-- Expose global trigger for other scripts
_G.Respawn = function()
	fireRespawnOnce("ManualCall")
end
_G.GuideRespawn = _G.Respawn

-- ============================================================================
-- ULTRA-EARLY HEALTH MONITOR & LIFECYCLE CONTROLLER
-- ============================================================================
local function hookCharacter(char: Model)
	disconnectCharConns()

	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not (hum and hum:IsA("Humanoid")) then return end

	lastObservedHealth = hum.Health

	local function checkAndTrigger(currentHp: number, cause: string)
		if hasFiredThisLife then return end

		local drop = lastObservedHealth - currentHp
		lastObservedHealth = currentHp

		-- Triggers on:
		-- 1. Any health <= 0 (death)
		-- 2. Health drops below early threshold (<= 40)
		-- 3. Sudden lethal burst damage (drop >= 15 in one frame)
		-- 4. Native Died signal
		-- 5. Ragdoll / Dead humanoid state
		if currentHp <= 0 or currentHp <= HEALTH_THRESHOLD or drop >= BURST_DROP_THRESHOLD or cause == "Died" or cause == "State" then
			fireRespawnOnce(cause)
		end
	end

	table.insert(activeCharConns, hum.HealthChanged:Connect(function(hp: number)
		checkAndTrigger(hp, "HealthChanged")
	end))

	table.insert(activeCharConns, hum.Died:Connect(function()
		checkAndTrigger(0, "Died")
	end))

	table.insert(activeCharConns, hum.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.Ragdoll
			or newState == Enum.HumanoidStateType.FallingDown then
			checkAndTrigger(hum.Health, "State")
		end
	end))
end

-- Handles respawn cleanly: only resets the lock once fully spawned and healthy
local function onCharacterAdded(char: Model)
	-- Remain locked until the new humanoid confirms it has spawned alive and healthy
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then return end

	local healthWatcher: RBXScriptConnection? = nil

	local function activateIfHealthy(hp: number)
		if hp > HEALTH_THRESHOLD then
			if healthWatcher then
				healthWatcher:Disconnect()
				healthWatcher = nil
			end
			hasFiredThisLife = false -- Reset lock cleanly for the new life
			hookCharacter(char)
		end
	end

	healthWatcher = hum.HealthChanged:Connect(activateIfHealthy)
	if hum.Health > HEALTH_THRESHOLD then
		activateIfHealthy(hum.Health)
	end
end

if LocalPlayer.Character then
	local currentHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if currentHum and currentHum.Health > HEALTH_THRESHOLD then
		hasFiredThisLife = false
		hookCharacter(LocalPlayer.Character)
	end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

print("⚡ [Respawn] CIPHER // V7.1 Single-Pulse Headless Loaded (Strict Zero-Spam).")
