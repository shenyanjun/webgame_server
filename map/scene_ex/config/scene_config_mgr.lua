local scene_config = require("config.scene_config")
local extend_config = require("scene_ex.config.extend_loader")
local copy_config = require("scene_ex.config.copy_bale_loader")

local mode_builder_list = create_local("scene_ex.scene_config_mgr.mode_builder_list", {})


Scene_config_mgr = oo.class(nil, "Scene_config_mgr")

--注册任务类的构建者，构建者可以是类（是类，不是对象除非是函数对象），函数对象，函数
function Scene_config_mgr.register_mode_class(type, builder)
	mode_builder_list[type] = builder(type)
end

function Scene_config_mgr:__init()
	self.config = {}
	self.map_obj_list = {}
end

function Scene_config_mgr:get_mode(mode)
	return mode_builder_list[mode]
end

function Scene_config_mgr:load_map(map_id, file_path)
	if not file_path then
		local config = self:get_config(map_id)
		file_path = config and config.map_path
	end
	
	if not map_id or not file_path then
		f_scene_error_log(
			"Scene_config_mgr:load_map(map_id = %s, file_path = %s) Invalid Args!"
			, tostring(map_id)
			, tostring(file_path))
		return nil
	end

	local map_obj = self.map_obj_list[map_id]
	if not map_obj then
		map_obj = Scene_map(map_id)
		if not map_obj:load(file_path) then
			f_scene_error_log(
				"Scene_config_mgr:load_map(map_id = %d, file_path = %s) Load Map Failed!"
				, map_id
				, file_path)
			return nil
		else
			f_scene_info_log(
				"Scene_config_mgr:load_map(map_id = %d, file_path = %s) Load Map Success!"
				, map_id
				, file_path)
		end
		self.map_obj_list[map_id] = map_obj
	end
	
	return map_obj:clone(map_id)
end

function Scene_config_mgr:load()
end

function Scene_config_mgr:get_config(scene_id)
	--return self.config[scene_id]
	return scene_config._config[scene_id]
end

function Scene_config_mgr:get_carry_config(carry_id)
	return scene_config._carry[carry_id]
end

function Scene_config_mgr:can_load(map_id)
	local config = scene_config._config[map_id]
	local is_success = false
	if config then
		local index = config.line
		if not index or 0 == index then
			return (not f_is_pvp()) and (not f_is_line_faction()) and (not f_is_line_ww())
		elseif -1 ~= index then
			local info = scene_config._line[index]
			if info then
				return info[SELF_SV_ID] ~= nil
			else
				f_scene_error_log("Scene_config_mgr:can_load(%s) Not Info."
					, tostring(map_id))
			end
		end
	end
	return is_success
end

function Scene_config_mgr:get_relive_config(map_id)
	--local config = self.config[map_id]
	local config = scene_config._config[map_id]
	if config then
		return scene_config._relive[config.relive]
	end
end

function Scene_config_mgr:get_config_list()
	return scene_config._config
end

function Scene_config_mgr:get_extend_config(map_id)
	return extend_config.config[map_id]
end

function Scene_config_mgr:get_extend_config_list()
	return extend_config.config
end

function Scene_config_mgr:get_schedule_list()
	return extend_config.schedule
end

function Scene_config_mgr:get_copy_limit(map_id)
	local config = copy_config.config_list.value[map_id]
	return config and (config.cycle or 0) or 0
end

function Scene_config_mgr:get_scene_name(scene_id)
	--return self.config[scene_id]
	local scene_c = scene_config._config[scene_id]
	return scene_c and scene_c.name or "unknow"
end