-- ============================================================================
-- CIPHER // KILL AURA V7.0 (HEADLESS BACKGROUND SERVICE)
-- 10-Stud Melee Combat Aura Triggered on Attack/Swing (Zero-Ping Overhead)
-- Headless Edition: Always Active, UI-less, Lightweight
-- ============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

-- Executor API Resolver
local fireTouch: ((BasePart, BasePart, number) -> ())? = (firetouchinterest :: any)
	or (getgenv and (getgenv().firetouchinterest or getgenv().fire_touch_interest))
	or (syn and syn.firetouchinterest)

-- Global State & Settings
_G.KillAuraEnabled = true
local RANGE: number       = 10     -- Exactly 10 studs
local RANGE_SQ: number    = RANGE * RANGE
local TOUCH_BURST: number = 3      -- Clean touch pairs per swing

-- Internal Caches
local toolParts: { BasePart } = {}
local toolRemotes: { RemoteEvent } = {}
local equippedTools: { Tool } = {}
local toolConnections: { [Tool]: RBXScriptConnection } = {}

-- Priority parts for reliable hit registration
local PRIORITY_PARTS = {
	"HumanoidRootPart",
	"Head",
	"UpperTorso",
	"Torso",
}

-- Destroy any previous UI if left over
pcall(function()
	local core = game:GetService("CoreGui"):FindFirstChild("CipherKillAuraUI")
	if core then core:Destroy() end
	local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pgui then
		local u = pgui:FindFirstChild("CipherKillAuraUI")
		if u then u:Destroy() end
	end
end)

-- ============================================================================
-- AURA HIT EXECUTION (ON ATTACK / SWING ONLY)
-- ============================================================================
local function executeAuraStrike()
	if not _G.KillAuraEnabled then return end

	local char = LocalPlayer.Character
	if not char then return end

	local myRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if not (myRoot and myRoot:IsA("BasePart")) then return end

	local myPos = myRoot.Position

	-- Find all enemies within 10 studs
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local pChar = p.Character
			if pChar then
				local hum = pChar:FindFirstChildOfClass("Humanoid")
				local enemyRoot = pChar:FindFirstChild("HumanoidRootPart") or pChar:FindFirstChild("Torso")
				if hum and enemyRoot and enemyRoot:IsA("BasePart") and hum.Health > 0 then
					local dx = enemyRoot.Position.X - myPos.X
					local dy = enemyRoot.Position.Y - myPos.Y
					local dz = enemyRoot.Position.Z - myPos.Z
					if (dx * dx + dy * dy + dz * dz) <= RANGE_SQ then
						-- 1. Fire tool combat remotes
						for r = 1, #toolRemotes do
							local rem = toolRemotes[r]
							if rem and rem.Parent and enemyRoot and enemyRoot.Parent then
								pcall(rem.FireServer, rem, enemyRoot)
							end
						end

						-- 2. Fire touch interests to priority parts
						if fireTouch then
							for _, partName in ipairs(PRIORITY_PARTS) do
								local enemyPart = pChar:FindFirstChild(partName)
								if enemyPart and enemyPart:IsA("BasePart") and enemyPart.Parent then
									for t = 1, #toolParts do
										local toolPart = toolParts[t]
										if toolPart and toolPart.Parent then
											for _ = 1, TOUCH_BURST do
												pcall(fireTouch, toolPart, enemyPart, 0)
												pcall(fireTouch, toolPart, enemyPart, 1)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- ============================================================================
-- TOOL CACHING & SWING HOOKING
-- ============================================================================
local function findFightRemote(tool: Tool): RemoteEvent?
	local r = tool:FindFirstChild("FightEvent")
	if r and r:IsA("RemoteEvent") then return r end
	for _, o in ipairs(tool:GetChildren()) do
		if o:IsA("RemoteEvent") then
			local n = string.lower(o.Name)
			if string.find(n, "fight", 1, true)
				or string.find(n, "slap", 1, true)
				or string.find(n, "hit", 1, true)
				or string.find(n, "attack", 1, true)
				or string.find(n, "combat", 1, true)
				or string.find(n, "event", 1, true) then
				return o
			end
		end
	end
	return nil
end

local function hookToolAttack(tool: Tool)
	if toolConnections[tool] then
		toolConnections[tool]:Disconnect()
		toolConnections[tool] = nil
	end

	-- Strike when weapon is activated
	toolConnections[tool] = tool.Activated:Connect(function()
		executeAuraStrike()
	end)
end

local function rebuildToolParts()
	table.clear(toolParts)
	table.clear(toolRemotes)
	table.clear(equippedTools)

	local char = LocalPlayer.Character
	if not char then return end

	for _, t in ipairs(char:GetChildren()) do
		if t:IsA("Tool") then
			table.insert(equippedTools, t)
			hookToolAttack(t)

			local handle = t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart")
			if handle and handle:IsA("BasePart") then
				handle.CanCollide = false
				handle.Massless = true
				handle.CanTouch = true
				if not table.find(toolParts, handle) then
					table.insert(toolParts, handle)
				end
			end

			local rem = findFightRemote(t)
			if rem and not table.find(toolRemotes, rem) then
				table.insert(toolRemotes, rem)
			end
		end
	end
end

-- Screen tap / mouse click fallback attack trigger
UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		if #equippedTools > 0 and _G.KillAuraEnabled then
			executeAuraStrike()
		end
	end
end)

local function hookCharacter(char: Model)
	for _, conn in pairs(toolConnections) do
		conn:Disconnect()
	end
	table.clear(toolConnections)

	rebuildToolParts()
	char.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") then
			rebuildToolParts()
			-- Frame-0 Instant Damage Burst upon Equip / Respawn
			task.defer(function()
				if _G.KillAuraEnabled then
					executeAuraStrike()
				end
			end)
		end
	end)
	char.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("Tool") then
			task.defer(rebuildToolParts)
		end
	end)
	-- Initial check for already equipped tools on spawn
	if #equippedTools > 0 and _G.KillAuraEnabled then
		task.defer(executeAuraStrike)
	end
end

if LocalPlayer.Character then
	hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

print("⚡ [Kill Aura] CIPHER // V7.0 Headless Loaded (Always Active, 10-Stud On-Attack).")
