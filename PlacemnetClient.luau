local PlacementClient = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerData"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local towersModels = ReplicatedStorage:WaitForChild("TowersModels")
local placeEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlaceTowerEvent")

local previewTower = nil
local rangeCircle = nil
local baseCircle = nil
local renderConnection = nil
local isPlacing = false
local canPlace = false
local canConfirmClick = false

local FIXED_MAP_Y = 0.5
local TOWER_Y_OFFSET = -1.35
local placedTowerIndicators = {} 

local function ToggleBarriers(isVisible)
	local targetTransparency = isVisible and 0.5 or 1
	local barriersFolder = workspace:FindFirstChild("Barriers")
	if barriersFolder then
		for _, obj in pairs(barriersFolder:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "MapBarrier" then
				obj.Transparency = targetTransparency
			end
		end
	end
end

local function CreateCircle(radius, color, transparency)
	local circle = Instance.new("Part")
	circle.Shape = Enum.PartType.Cylinder
	circle.Material = Enum.Material.Neon
	circle.Color = color
	circle.Transparency = transparency
	circle.CanCollide = false
	circle.Anchored = true
	circle.CastShadow = false
	circle.Orientation = Vector3.new(0, 0, 90)
	circle.Size = Vector3.new(0.2, radius * 2, radius * 2)
	circle.Parent = workspace
	return circle
end

function PlacementClient.CancelPlacement()
	isPlacing = false
	canConfirmClick = false
	if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
	if previewTower then previewTower:Destroy(); previewTower = nil end
	if rangeCircle then rangeCircle:Destroy(); rangeCircle = nil end
	if baseCircle then baseCircle:Destroy(); baseCircle = nil end

	for _, indicator in pairs(placedTowerIndicators) do
		if indicator then indicator:Destroy() end
	end
	table.clear(placedTowerIndicators)

	ToggleBarriers(false)
end

function PlacementClient.StartPlacement(towerName)
	if isPlacing then PlacementClient.CancelPlacement() end

	local towerTemplate = towersModels:FindFirstChild(towerName)
	local config = TowerData[towerName]

	if not towerTemplate or not config then return end

	isPlacing = true
	canConfirmClick = false

	task.spawn(function()
		task.wait(0.1)
		canConfirmClick = true
	end)

	previewTower = towerTemplate:Clone()
	for _, part in pairs(previewTower:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 0.5
			part.Material = Enum.Material.ForceField
			if part.Name == "TowerBarrier" then part:Destroy() end
		end
	end
	previewTower.Parent = workspace

	rangeCircle = CreateCircle(config.Range, Color3.new(0, 0.5, 1), 0.8)
	baseCircle = CreateCircle(config.CollisionRadius, Color3.new(0, 1, 0), 0.5)

	local towersFolder = workspace:FindFirstChild("Towers")
	if towersFolder then
		for _, otherTower in pairs(towersFolder:GetChildren()) do
			local otherConfig = TowerData[otherTower.Name]
			if otherConfig and otherTower.PrimaryPart then
				local otherRange = CreateCircle(otherConfig.Range, Color3.new(0, 0.5, 1), 0.9)
				local otherBase = CreateCircle(otherConfig.CollisionRadius, Color3.new(1, 0, 0), 0.7)

				otherRange.Position = Vector3.new(otherTower.PrimaryPart.Position.X, FIXED_MAP_Y + 0.1, otherTower.PrimaryPart.Position.Z)
				otherBase.Position = Vector3.new(otherTower.PrimaryPart.Position.X, FIXED_MAP_Y + 0.15, otherTower.PrimaryPart.Position.Z)

				table.insert(placedTowerIndicators, otherRange)
				table.insert(placedTowerIndicators, otherBase)
			end
		end
	end

	ToggleBarriers(true)

	renderConnection = RunService.RenderStepped:Connect(function()
		local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local ignoreList = {
			previewTower, rangeCircle, baseCircle, player.Character,
			workspace:FindFirstChild("Barriers"),
			workspace:FindFirstChild("Towers")
		}
		for _, ind in pairs(placedTowerIndicators) do table.insert(ignoreList, ind) end
		raycastParams.FilterDescendantsInstances = ignoreList

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
		local hitPosition = result and result.Position or (ray.Origin + ray.Direction * 100)

		local yOffset = previewTower.PrimaryPart.Size.Y / 2

		local targetPosition = Vector3.new(hitPosition.X, FIXED_MAP_Y + yOffset + TOWER_Y_OFFSET, hitPosition.Z)
		local targetCFrame = CFrame.new(targetPosition)

		previewTower:PivotTo(targetCFrame)

		rangeCircle.Position = Vector3.new(targetPosition.X, FIXED_MAP_Y + 0.1, targetPosition.Z)
		baseCircle.Position = Vector3.new(targetPosition.X, FIXED_MAP_Y + 0.15, targetPosition.Z)

		canPlace = true

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		local barriersFolder = workspace:FindFirstChild("Barriers")
		if barriersFolder then
			overlapParams.FilterDescendantsInstances = {barriersFolder}
			local checkSize = previewTower.PrimaryPart.Size + Vector3.new(0, 2, 0)
			local touchingParts = workspace:GetPartBoundsInBox(targetCFrame, checkSize, overlapParams)
			for _, part in pairs(touchingParts) do
				if part.Name == "MapBarrier" then
					canPlace = false
					break
				end
			end
		end

		if canPlace and towersFolder then
			for _, otherTower in pairs(towersFolder:GetChildren()) do
				local otherConfig = TowerData[otherTower.Name]
				if otherConfig and otherTower.PrimaryPart then
					local dist = (Vector3.new(targetPosition.X, 0, targetPosition.Z) - Vector3.new(otherTower.PrimaryPart.Position.X, 0, otherTower.PrimaryPart.Position.Z)).Magnitude
					local requiredDist = config.CollisionRadius + otherConfig.CollisionRadius
					if dist < requiredDist then
						canPlace = false
						break
					end
				end
			end
		end

		local color = canPlace and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		baseCircle.Color = color
		for _, part in pairs(previewTower:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = color
			end
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if isPlacing then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if canConfirmClick and canPlace and previewTower then
				placeEvent:FireServer(previewTower.Name, previewTower:GetPivot())
				PlacementClient.CancelPlacement()
			end
		elseif input.KeyCode == Enum.KeyCode.Q then 
			PlacementClient.CancelPlacement()
		end
	end
end)

return PlacementClient
