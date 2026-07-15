local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local EnemyClass = require(ReplicatedStorage.Modules.EnemyClass)
local EnemyData = require(ReplicatedStorage.Modules.EnemyData)

local ActiveEnemiesFolder = workspace:WaitForChild("ActiveEnemies")
local SpawnPart = workspace:WaitForChild("SpawnPart")
local EndPart = workspace:WaitForChild("EndPart")

local isSpawning = false
local currentSpawnSession = 0

local START_SPAWN_DELAY = 2.0 
local MIN_SPAWN_DELAY = 0.1   
local SPEED_UP_STEP = 0.05    

local ENEMY_COLLISION_GROUP = "EnemiesGroup"
pcall(function()
	if not PhysicsService:IsCollisionGroupRegistered(ENEMY_COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(ENEMY_COLLISION_GROUP)
	end
	PhysicsService:CollisionGroupSetCollidable(ENEMY_COLLISION_GROUP, ENEMY_COLLISION_GROUP, false)
end)

local function spawnAndMoveEnemy()
	local originalEnemy = ActiveEnemiesFolder:FindFirstChild("ind1")
	if not originalEnemy then
		print("Error 1")
		return
	end

	local enemyModel = originalEnemy:Clone()

	enemyModel:PivotTo(SpawnPart.CFrame)

	for _, part in pairs(enemyModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			pcall(function()
				part.CollisionGroup = ENEMY_COLLISION_GROUP
			end)
		end
	end

	if enemyModel.PrimaryPart then
		enemyModel.PrimaryPart.Anchored = false
	end

	enemyModel.Parent = ActiveEnemiesFolder

	local stats = EnemyData["ind1"] or EnemyData["BasicZombie"] or {Class = "Normal", MaxHP = 50, Speed = 12}
	enemyModel:SetAttribute("MaxHP", stats.MaxHP)
	enemyModel:SetAttribute("CurrentHP", stats.MaxHP)

	local enemyObject = EnemyClass.new(enemyModel, "ind1", stats)

	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = stats.Speed or 16
		humanoid.EvaluateStateMachine = true

		if enemyModel.PrimaryPart then
			humanoid.HipHeight = humanoid.HipHeight
		end
	end

	local animatorController = enemyModel:FindFirstChildOfClass("Humanoid") or enemyModel:FindFirstChildOfClass("AnimationController")
	if animatorController then
		local animator = animatorController:FindFirstChildOfClass("Animator") or animatorController
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = (stats.Animations and stats.Animations.Walk) or "rbxassetid://118857499732013"

		local walkTrack = animator:LoadAnimation(animInstance)
		walkTrack.Looped = true
		walkTrack:Play()
	end

	if humanoid and enemyModel.PrimaryPart then
		local function walkToEnd()
			if humanoid.Parent and enemyModel.PrimaryPart then
				humanoid:MoveTo(EndPart.Position)
			end
		end

		walkToEnd()

		humanoid.MoveToFinished:Connect(function(reached)
			if not enemyModel or not enemyModel.PrimaryPart then return end

			local myPos = enemyModel.PrimaryPart.Position
			local targetPos = EndPart.Position
			local distance = Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)

			if distance.Magnitude <= 6 then
				if enemyObject then
					enemyObject:ReachBase()
				end
			else
				walkToEnd()
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local words = string.split(message, " ")
		local command = words[1]:lower()

		if command == "/wave" then
			if isSpawning then return end
			isSpawning = true
			currentSpawnSession = currentSpawnSession + 1
			local mySession = currentSpawnSession

			task.spawn(function()
				local currentDelay = START_SPAWN_DELAY

				while isSpawning and currentSpawnSession == mySession do
					spawnAndMoveEnemy()
					task.wait(currentDelay)
					currentDelay = math.max(MIN_SPAWN_DELAY, currentDelay - SPEED_UP_STEP)
				end
			end)

		elseif command == "/stop" then
			isSpawning = false
			currentSpawnSession = currentSpawnSession + 1

		elseif command == "/spawnenemy" then
			local amountText = words[2]
			local count = tonumber(amountText)

			if count and count > 0 then
				currentSpawnSession = currentSpawnSession + 1
				local mySession = currentSpawnSession

				task.spawn(function()
					for i = 1, count do
						if currentSpawnSession ~= mySession then break end
						if not ActiveEnemiesFolder:FindFirstChild("ind1") then 
							print("Error 1")
							break 
						end

						spawnAndMoveEnemy()
						task.wait(0.3)
					end
				end)
			else
				print("Error 1")
			end
		end
	end)
end)
