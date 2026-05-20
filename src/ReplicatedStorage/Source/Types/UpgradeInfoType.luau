export type UpgradeInfo = {
	read CarryCapacity: {
		read BasePrice: number,
		read BaseAmount: number,
		read Multiplier: number,
		read Increase: number,
		read MaxLevel: number,
	},
	read PickaxeUpgrade: {
		read BasePrice: number,
		read Multiplier: number,
	},
	read Walkspeed: {
		read BasePrice: number,
		read BaseAmount: number,
		read Multiplier: number,
		read Increase: number,
		read MaxLevel: number,
	},
}

return nil
