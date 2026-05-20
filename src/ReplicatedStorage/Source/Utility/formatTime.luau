 local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))

	local days = math.floor(seconds / 86400)
	seconds %= 86400

	local hours = math.floor(seconds / 3600)
	seconds %= 3600

	local minutes = math.floor(seconds / 60)
	seconds %= 60

	local parts: {string} = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end
	if hours > 0 then
		table.insert(parts, hours .. "h")
	end
	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end
	if seconds > 0 or #parts == 0 then
		table.insert(parts, seconds .. "s")
	end

	return table.concat(parts, " ")
end

return formatTime
