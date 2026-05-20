export type function apply(keyUnion, valueType)
	-- selene: allow(undefined_variable)
	local tbl = types.newtable()

	tbl:setindexer(keyUnion, valueType)

	if keyUnion:is("union") then
		for _, component in keyUnion:components() do
			tbl:setreadproperty(component, valueType)
		end
	end

	return tbl
end

return nil
