local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local ScreenGui = script.Parent
local HoverFrame = ScreenGui:WaitForChild("HoverFrame")
local EnemyNameLabel = HoverFrame:WaitForChild("EnemyName")
local HealthTextLabel = HoverFrame:WaitForChild("HealthText")
local ProgressBarBackground = HoverFrame:WaitForChild("ProgressBarBackground")
local ProgressBar = ProgressBarBackground:WaitForChild("ProgressBar")

local currentEnemyModel = nil
local attributeConnection = nil

ProgressBar.Size = UDim2.new(1, 0, 1, 0)

local function hideGui()
	HoverFrame.Visible = false
	currentEnemyModel = nil
	if attributeConnection then
		attributeConnection:Disconnect()
		attributeConnection = nil
	end
end

local function updateHealthDisplay(model)
	if not model or not model.Parent then
		hideGui()
		return
	end

	local currentHP = model:GetAttribute("CurrentHP")
	local maxHP = model:GetAttribute("MaxHP")

	if not currentHP or not maxHP then
		currentHP = 50
		maxHP = 50
	end

	HealthTextLabel.Text = string.format("%02d/%02d", currentHP, maxHP)

	local healthRatio = math.clamp(currentHP / maxHP, 0, 1)

	ProgressBar:TweenSize(
		UDim2.new(healthRatio, 0, 1, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.15,
		true
	)

	if currentHP <= 0 then
		hideGui()
	end
end

RunService.RenderStepped:Connect(function()
	local mousePosition = UserInputService:GetMouseLocation()

	if HoverFrame.Visible then
		HoverFrame.Position = UDim2.new(0, mousePosition.X + 15, 0, mousePosition.Y + 15)
	end

	local target = Mouse.Target
	if target then
		local model = target:FindFirstAncestorOfClass("Model")
		if model and model.Parent and model.Parent.Name == "ActiveEnemies" then

			if currentEnemyModel ~= model then
				if attributeConnection then attributeConnection:Disconnect() end

				currentEnemyModel = model
				EnemyNameLabel.Text = model.Name

				attributeConnection = model:GetAttributeChangedSignal("CurrentHP"):Connect(function()
					updateHealthDisplay(model)
				end)

				updateHealthDisplay(model)
				HoverFrame.Visible = true
			end
			return
		end
	end

	if currentEnemyModel then
		hideGui()
	end
end)

UserInputService.MouseLeaveViewport:Connect(hideGui)
