

Impact_container = oo.class(nil, "Impact_container")

function Impact_container:__init(obj_id)
	self.obj_id = obj_id

	self.impact_list = {}
end

function Impact_container:get_impact_obj(impact_id)
	return self.impact_list[impact_id]
end

function Impact_container:set_impact_obj(impact_obj)
	local impact_id = impact_obj:get_impact_id()
	self.impact_list[impact_id] = impact_obj
end

function Impact_container:is_in_impact_list(impact_id)
	if self.impact_list[impact_id] == nil then 
		return false
	end

	return true
end

function Impact_container:get_net_info()
end

function Impact_container:load()
end




