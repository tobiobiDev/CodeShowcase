--!strict

local SUFFIXES = {
	{1e30, "N"},   -- nonillion
	{1e27, "O"},   -- octillion
	{1e24, "SP"},  -- septillion
	{1e21, "S"},   -- sextillion
	{1e18, "Q"},   -- quintillion
	{1e15, "QA"},  -- quadrillion
	{1e12, "T"},   -- trillion
	{1e9, "B"},    -- billion
	{1e6, "M"},    -- million
	{1e3, "K"},    -- thousand
}

--[[
    Formats a number with suffixes (k, m, b, t, etc.).
]]
local function formatNumber(number: number, precision: number?): string
	if typeof(number) ~= "number" then
		return ""
	end
	local absNumber = math.abs(number)
	local digits = precision or 2

	for _, entry in ipairs(SUFFIXES) do
		local value, suffix = entry[1] :: number, entry[2] :: string
		if absNumber >= value then
			local formatted = string.format(`%.{digits}f` :: any, number / value)
			-- Remove trailing zeros and dot if not needed
			formatted = formatted:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
			return `{formatted}{suffix}`
		end
	end

	-- For numbers less than 1000, just return as is (with precision if needed)
	local formatted = string.format(`%.{digits}f` :: any, number)
	formatted = formatted:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
	return formatted
end

return formatNumber
