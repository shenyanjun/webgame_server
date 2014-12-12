

--require("function/function_config")
require("function.function_container")
require("function.function_process")


local function get_function_con(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	return player and player:get_function_con()
end



--监听杀死怪物事件
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_SCENE, get_function_con, Function_container.war_in)
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_COPY, get_function_con, Function_container.enter_copy)
g_event_mgr:register_event(EVENT_SET.EVENT_COMPLETE_QUEST, get_function_con, Function_container.task)
g_event_mgr:register_event(EVENT_SET.EVENT_NEW_DAY,get_function_con,Function_container.login)
g_event_mgr:register_event(EVENT_SET.EVENT_DOUSHOU,get_function_con,Function_container.pet_doushou)
g_event_mgr:register_event(EVENT_SET.EVENT_LEVEL_UP,get_function_con,Function_container.level_up)
