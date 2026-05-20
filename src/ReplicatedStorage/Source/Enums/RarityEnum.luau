local EnumTypeFunction = require(script.Parent.EnumTypeFunction)

export type EnumType =
    "Common"
    | "Uncommon"
    | "Epic"
    | "Legendary"
    | "Mythical"
    | "Divine"
    | "Secret"
    | "Celestial"

export type WallEnumType =
	"CommonWall"
    | "UncommonWall"
    | "EpicWall"
    | "LegendaryWall"
    | "MythicalWall"
    | "DivineWall"
    | "SecretWall"
    | "CelestialWall"

local RarityEnum: EnumTypeFunction.EnumTableFromUnion<EnumType> = {
    Common = "Common" :: "Common",
    Uncommon = "Uncommon" :: "Uncommon",
    Epic = "Epic" :: "Epic",
    Legendary = "Legendary" :: "Legendary",
    Mythical = "Mythical" :: "Mythical",
    Divine = "Divine" :: "Divine",
    Secret = "Secret" :: "Secret",
    Celestial = "Celestial" :: "Celestial",
}

return table.freeze(RarityEnum)
