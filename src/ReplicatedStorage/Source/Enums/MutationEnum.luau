local EnumTypeFunction = require(script.Parent.EnumTypeFunction)

export type EnumType =
    "Normal" 
    | "Gold" 
    | "Diamond" 
    | "Ruby" 
    | "Blaze"

local MutationEnum: EnumTypeFunction.EnumTableFromUnion<EnumType> = {
	Normal = "Normal" :: "Normal",
	Gold = "Gold" :: "Gold",
	Diamond = "Diamond" :: "Diamond",
	Ruby = "Ruby" :: "Ruby",
	Blaze = "Blaze" :: "Blaze",
}

return table.freeze(MutationEnum)
