local EnumTypeFunction = require(script.Parent.EnumTypeFunction)

export type EnumType =
	"Traitless"
	| "Greedy"
	| "Ancient"
	| "Efficient"
	| "Loaded"
	| "Golden touch"
	| "Hyperactive"
	| "Ancient wealth"
	| "Enhanced"
	| "Ascended"
	| "Godlike"
	| "Radiating"

local TraitsEnum: EnumTypeFunction.EnumTableFromUnion<EnumType> = {
	Traitless = "Traitless" :: "Traitless",
	Greedy = "Greedy" :: "Greedy",
	Ancient = "Ancient" :: "Ancient",
	Efficient = "Efficient" :: "Efficient",
	Loaded = "Loaded" :: "Loaded",
	["Golden touch"] = "Golden touch" :: "Golden touch",
	Hyperactive = "Hyperactive" :: "Hyperactive",
	["Ancient wealth"] = "Ancient wealth" :: "Ancient wealth",
	Enhanced = "Enhanced" :: "Enhanced",
	Ascended = "Ascended" :: "Ascended",
	Godlike = "Godlike" :: "Godlike",
	Radiating = "Radiating" :: "Radiating",
}

return table.freeze(TraitsEnum)
