local TowerData = {
	["Rifleman"] = {
		TowerType = "Attacker",
		Price = 500,
		Damage = 10,
		Range = 12,
		CollisionRadius = 2,

		FireMode = "Burst",
		BurstCount = 4,
		BurstDelay = 0.15,
		Cooldown = 1.3,

		Upgrades = {},

		Animations = {
			Spawn = "rbxassetid://108169438515895",
			Idle = "rbxassetid://114555464333533",
			Attack = "rbxassetid://90000483019628"
		},
		Sounds = {
			Spawn = "rbxassetid://87123900728301",
			Attack = "rbxassetid://103807799095792"
		}
	}
}