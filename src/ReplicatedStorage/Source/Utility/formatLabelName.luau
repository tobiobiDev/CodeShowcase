--!strict

--[[
	This function will split text by word within limitations.
	This allows a text label with TextScaled enabled to more appropriately show
	text on multiple lines without splitting a single word up.
	
	Note: Long single words may still be split by TextScaled/TextWrapped.
]]
local function formatLabelName(text: string): string
	local words = text:split(" ")
	
	if #words <= 1 then
		return text
	end

	return `{words[1]}\n{table.concat(words, " ", 2)}`
end

return formatLabelName
