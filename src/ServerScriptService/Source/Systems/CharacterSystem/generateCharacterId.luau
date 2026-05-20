local HttpService = game:GetService("HttpService")

local function generateCharacterId(): string
	return HttpService:GenerateGUID(false)
end

return generateCharacterId
