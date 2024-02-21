--!strict
local Types = {}

export type HumanoidRootPart = Part & {
	Attachment: Attachment,
}
export type Torso = Part & {
	WeldConstraint: WeldConstraint,
}
export type Character = Model & {
	Humanoid: Humanoid,
	HumanoidRootPart: HumanoidRootPart,
	Movement: LinearVelocity,
	Torso: Torso,
}
export type Leaderstats = Model & {
	BricksEaten: IntValue,
}
export type CustomPlayer = Player & {
	Character: Character,
	leaderstats: Leaderstats,
}

return Types
