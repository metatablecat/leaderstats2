return function(className: string, props: {[string|number]: any})
	local inst = Instance.new(className)
	local parent = props.Parent
	if parent then
		props.Parent = nil
	end

	for i, v in ipairs(props) do
		v.Parent = inst
		props[i] = nil
	end

	for propName, prop in pairs(props) do
		inst[propName] = prop
	end

	inst.Parent = parent
	return inst
end