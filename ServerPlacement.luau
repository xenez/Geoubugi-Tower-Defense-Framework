local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local placeEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlaceTowerEvent")
local towersModels = ReplicatedStorage:WaitForChild("TowersModels")
local TowerData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerData"))

local TOWER_LIMIT = 100
local playerTowersCount = {} 

Players.PlayerRemoving:Connect(function(player)
	playerTowersCount[player] = nil
end)

placeEvent.OnServerEvent:Connect(function(player, towerName, targetCFrame)
	local towerTemplate = towersModels:FindFirstChild(towerName)
	local towerConfig = TowerData[towerName]

	if not towerTemplate or not towerConfig then 
		warn("Модель або конфіг для " .. tostring(towerName) .. " не знайдено!")
		return 
	end

	local price = towerConfig.Price

	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money or money.Value < price then
		print(player.Name .. " не має достатньо грошей!")
		return 
	end

	if not playerTowersCount[player] then playerTowersCount[player] = 0 end
	if playerTowersCount[player] >= TOWER_LIMIT then
		print(player.Name .. " досяг ліміту таверів!")
		return
	end

	money.Value -= price
	playerTowersCount[player] += 1

	local newTower = towerTemplate:Clone()

	newTower:SetAttribute("Owner", player.UserId)

	local towersFolder = workspace:FindFirstChild("Towers")
	if not towersFolder then
		towersFolder = Instance.new("Folder")
		towersFolder.Name = "Towers"
		towersFolder.Parent = workspace
	end

	newTower.Parent = towersFolder
	newTower:PivotTo(targetCFrame)

	local rootPart = newTower:FindFirstChild("HumanoidRootPart") or newTower.PrimaryPart

	if rootPart then
		rootPart.Anchored = true
	end

	for _, part in pairs(newTower:GetDescendants()) do
		if part:IsA("BasePart") then
			if part ~= rootPart then
				part.Anchored = false
			end
			part.CanCollide = false
		end
	end
  
	local humanoid = newTower:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.PlatformStand = true
	end
end)
