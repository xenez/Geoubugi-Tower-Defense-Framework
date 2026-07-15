local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerData = require(ReplicatedStorage.Modules.TowerData)
local ClassesFolder = script.Classes

local ActiveTowers = {}

local TowersFolder = workspace:WaitForChild("Towers", math.huge)
local EnemiesFolder = workspace:WaitForChild("ActiveEnemies")

local function InitializeTower(towerModel)
	local towerName = towerModel.Name 
	local data = TowerData[towerName]

	if not data then 
		warn("Характеристики для " .. towerName .. " не знайдено в TowerData!")
		return 
	end

	local classModule = ClassesFolder:FindFirstChild(data.TowerType)
	if classModule then
		local TowerClass = require(classModule)

		local newTower = TowerClass.new(towerModel, towerName, data)
		table.insert(ActiveTowers, newTower)
		print("Tower " .. towerName .. " (" .. data.TowerType .. ") successfully connceted!")
	else
		warn("Logic Module type " .. data.TowerType .. " not found!")
	end
end

for _, tower in pairs(TowersFolder:GetChildren()) do
	InitializeTower(tower)
end

TowersFolder.ChildAdded:Connect(function(newChild)
	task.wait(0.1) 
	InitializeTower(newChild)
end)

RunService.Heartbeat:Connect(function()
	local currentTime = os.clock()

	for i, tower in ipairs(ActiveTowers) do
		if not tower.Model or not tower.Model.Parent then
			table.remove(ActiveTowers, i)
			continue
		end

		if tower.Update then
			tower:Update(currentTime, EnemiesFolder)
		end
	end
end)
