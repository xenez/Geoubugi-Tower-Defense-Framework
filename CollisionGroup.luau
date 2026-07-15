local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:RegisterCollisionGroup("TowerRoot")
PhysicsService:RegisterCollisionGroup("TowerVisuals")
PhysicsService:CollisionGroupSetCollidable("TowerRoot", "Default", true)
PhysicsService:CollisionGroupSetCollidable("TowerVisuals", "Default", false)
PhysicsService:CollisionGroupSetCollidable("Players", "TowerRoot", false)
PhysicsService:CollisionGroupSetCollidable("Players", "TowerVisuals", false)
PhysicsService:CollisionGroupSetCollidable("TowerRoot", "TowerVisuals", false)

local function setTowerCollisionGroup(towerModel)
	for _, part in pairs(towerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.CollisionGroup = "TowerRoot"
			else
				part.CollisionGroup = "TowerVisuals"
			end
		end
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end
	end)
end)

task.spawn(function()
	local towersFolder = workspace:WaitForChild("Towers", math.huge)

	towersFolder.ChildAdded:Connect(function(newTower)
		task.wait(0.1) 
		setTowerCollisionGroup(newTower)
	end)

	for _, tower in pairs(towersFolder:GetChildren()) do
		setTowerCollisionGroup(tower)
	end
end)
