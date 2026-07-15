local EnemyClass = {}
EnemyClass.__index = EnemyClass

local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local GiveMoneyEvent = ServerStorage:FindFirstChild("GiveMoneyEvent")

EnemyClass.ActiveEnemies = {} 

function EnemyClass.new(model, enemyName, data)
	local self = setmetatable({}, EnemyClass)

	self.Model = model
	self.Name = enemyName

	self.Class = data.Class
	self.MaxHP = data.MaxHP
	self.CurrentHP = data.MaxHP
	self.Speed = data.Speed

	self.DeathReward = data.DeathReward or 0
	self.MoneyPerDamage = data.MoneyPerDamage or 0
	self.Sounds = data.Sounds or {}

	EnemyClass.ActiveEnemies[model] = self

	if self.Sounds.Spawn and self.Model.PrimaryPart then
		local spawnSound = Instance.new("Sound")
		spawnSound.SoundId = self.Sounds.Spawn
		spawnSound.Parent = self.Model.PrimaryPart
		spawnSound.RollOffMaxDistance = 100
		spawnSound:Play()
		Debris:AddItem(spawnSound, 3)
	end

	return self
end

function EnemyClass:TakeDamage(amount)
	if self.CurrentHP <= 0 then return end 

	local actualDamage = math.min(amount, self.CurrentHP)
	self.CurrentHP = self.CurrentHP - actualDamage

	if self.Model then
		self.Model:SetAttribute("CurrentHP", self.CurrentHP)
	end

	if GiveMoneyEvent and self.MoneyPerDamage > 0 then
		local moneyEarned = actualDamage * self.MoneyPerDamage
		GiveMoneyEvent:Fire(moneyEarned)
	end

	if self.CurrentHP <= 0 then
		self:Die()
	end
end

function EnemyClass:Die()
	EnemyClass.ActiveEnemies[self.Model] = nil

	if GiveMoneyEvent and self.DeathReward > 0 then
		GiveMoneyEvent:Fire(self.DeathReward)
	end

	if self.Sounds.Death and self.Model.PrimaryPart then
		local deathSoundPart = Instance.new("Part")
		deathSoundPart.Transparency = 1
		deathSoundPart.Anchored = true
		deathSoundPart.CanCollide = false
		deathSoundPart.Position = self.Model.PrimaryPart.Position
		deathSoundPart.Parent = workspace

		local deathSound = Instance.new("Sound")
		deathSound.SoundId = self.Sounds.Death
		deathSound.Parent = deathSoundPart
		deathSound.RollOffMaxDistance = 100
		deathSound:Play()

		Debris:AddItem(deathSoundPart, 3)
	end

	if self.Model then
		self.Model:Destroy()
	end

	self = nil
end

function EnemyClass:ReachBase()
	EnemyClass.ActiveEnemies[self.Model] = nil
	if self.Model then
		self.Model:Destroy()
	end
	self = nil
end

return EnemyClass
