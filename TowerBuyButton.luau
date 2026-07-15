local button = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlacementClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PlacementClient"))

local targetTowerName = "Archer"

local towersModels = ReplicatedStorage:WaitForChild("TowersModels")
local towerModel = towersModels:FindFirstChild(targetTowerName)

if not towerModel then
	warn("Помилка: Модель тавера '" .. targetTowerName .. "' не знайдена в TowersModels!")
end

button.MouseButton1Click:Connect(function()
	if towerModel then
		PlacementClient.StartPlacement(targetTowerName)
	else
		print("Неможливо розмістити, модель відсутня.")
	end
end)
