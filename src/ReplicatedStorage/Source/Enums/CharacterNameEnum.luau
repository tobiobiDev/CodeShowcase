local EnumTypeFunction = require(script.Parent.EnumTypeFunction)

export type EnumType =
	"Ballerina Capuccina"
	| "Bluberini Octopussini"
	| "Bombardino Crocodilo"
	| "Boneca Ambalabu"
	| "Brr Brr Patapim"
	| "Bulliccinni Bananini"
	| "Burbaloni Luliloli"
	| "Cabrospaghetti Mistico"
	| "Cappuccino Assassino"
	| "Centralucci Nuclearucci"
	| "Chimpanzini Bananini"
	| "Chimpanzini Cocosini"
	| "Coccodrillo Formagioso"
	| "Cocosino Rhino"
	| "Elefantucci Bananucci"
	| "Frigo Camelo"
	| "garamaran"
	| "Giraffa Celestre"
	| "Glorbo Fruttodrillo"
	| "Karkerkar Kurkur"
	| "La Grande Combination"
	| "Lirili Larila"
	| "Los Tralaleritos"
	| "Noobini Appleini"
	| "Pakrahmatmamat"
	| "Perochello Lemonchello"
	| "Pot Hotspot"
	| "Spiuniro Golubiro"
	| "Ta Ta Ta Sahur"
	| "Tralalero Tralala"
	| "Tric Trac Baraboom"
	| "Trippi Troppi Troppa Trippa"
	| "Truliluru Tralaluno"
	| "Trulimero Trulichina"
	| "Tung Tung Sahur"
	| "Udin Din Din Dun"
	| "Unta Tobi Tob Tob"
	| "Melanini Pandanini"
	| "Bobritto Bandito"
	| "Madu dung dung"
	| "Ketupat Kuprat"
	| "Torrtuginni Dragonfrutinni"
	| "La Esok Sekola"

local CharacterNameEnum: EnumTypeFunction.EnumTableFromUnion<EnumType> = {
	["Ballerina Capuccina"] = "Ballerina Capuccina" :: "Ballerina Capuccina",
	["Bluberini Octopussini"] = "Bluberini Octopussini" :: "Bluberini Octopussini",
	["Bombardino Crocodilo"] = "Bombardino Crocodilo" :: "Bombardino Crocodilo",
	["Boneca Ambalabu"] = "Boneca Ambalabu" :: "Boneca Ambalabu",
	["Brr Brr Patapim"] = "Brr Brr Patapim" :: "Brr Brr Patapim",
	["Bulliccinni Bananini"] = "Bulliccinni Bananini" :: "Bulliccinni Bananini",
	["Burbaloni Luliloli"] = "Burbaloni Luliloli" :: "Burbaloni Luliloli",
	["Cabrospaghetti Mistico"] = "Cabrospaghetti Mistico" :: "Cabrospaghetti Mistico",
	["Cappuccino Assassino"] = "Cappuccino Assassino" :: "Cappuccino Assassino",
	["Centralucci Nuclearucci"] = "Centralucci Nuclearucci" :: "Centralucci Nuclearucci",
	["Chimpanzini Bananini"] = "Chimpanzini Bananini" :: "Chimpanzini Bananini",
	["Chimpanzini Cocosini"] = "Chimpanzini Cocosini" :: "Chimpanzini Cocosini",
	["Coccodrillo Formagioso"] = "Coccodrillo Formagioso" :: "Coccodrillo Formagioso",
	["Cocosino Rhino"] = "Cocosino Rhino" :: "Cocosino Rhino",
	["Elefantucci Bananucci"] = "Elefantucci Bananucci" :: "Elefantucci Bananucci",
	["Frigo Camelo"] = "Frigo Camelo" :: "Frigo Camelo",
	garamaran = "garamaran" :: "garamaran",
	["Giraffa Celestre"] = "Giraffa Celestre" :: "Giraffa Celestre",
	["Glorbo Fruttodrillo"] = "Glorbo Fruttodrillo" :: "Glorbo Fruttodrillo",
	["Karkerkar Kurkur"] = "Karkerkar Kurkur" :: "Karkerkar Kurkur",
	["La Grande Combination"] = "La Grande Combination" :: "La Grande Combination",
	["Lirili Larila"] = "Lirili Larila" :: "Lirili Larila",
	["Los Tralaleritos"] = "Los Tralaleritos" :: "Los Tralaleritos",
	["Noobini Appleini"] = "Noobini Appleini" :: "Noobini Appleini",
	Pakrahmatmamat = "Pakrahmatmamat" :: "Pakrahmatmamat",
	["Perochello Lemonchello"] = "Perochello Lemonchello" :: "Perochello Lemonchello",
	["Pot Hotspot"] = "Pot Hotspot" :: "Pot Hotspot",
	["Spiuniro Golubiro"] = "Spiuniro Golubiro" :: "Spiuniro Golubiro",
	["Ta Ta Ta Sahur"] = "Ta Ta Ta Sahur" :: "Ta Ta Ta Sahur",
	["Tralalero Tralala"] = "Tralalero Tralala" :: "Tralalero Tralala",
	["Tric Trac Baraboom"] = "Tric Trac Baraboom" :: "Tric Trac Baraboom",
	["Trippi Troppi Troppa Trippa"] = "Trippi Troppi Troppa Trippa" :: "Trippi Troppi Troppa Trippa",
	["Truliluru Tralaluno"] = "Truliluru Tralaluno" :: "Truliluru Tralaluno",
	["Trulimero Trulichina"] = "Trulimero Trulichina" :: "Trulimero Trulichina",
	["Tung Tung Sahur"] = "Tung Tung Sahur" :: "Tung Tung Sahur",
	["Udin Din Din Dun"] = "Udin Din Din Dun" :: "Udin Din Din Dun",
	["Unta Tobi Tob Tob"] = "Unta Tobi Tob Tob" :: "Unta Tobi Tob Tob",
	["Melanini Pandanini"] = "Melanini Pandanini" :: "Melanini Pandanini",
	["Bobritto Bandito"] = "Bobritto Bandito" :: "Bobritto Bandito",
	["Madu dung dung"] = "Madu dung dung" :: "Madu dung dung",
	["Ketupat Kuprat"] = "Ketupat Kuprat" :: "Ketupat Kuprat",
	["Torrtuginni Dragonfrutinni"] = "Torrtuginni Dragonfrutinni" :: "Torrtuginni Dragonfrutinni",
	["La Esok Sekola"] = "La Esok Sekola" :: "La Esok Sekola",
}

return table.freeze(CharacterNameEnum)
