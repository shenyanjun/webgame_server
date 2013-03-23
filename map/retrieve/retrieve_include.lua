--头文件
RETRIEVE_TYPE_DAILY			= 1			--日常任务
RETRIEVE_TYPE_SCENE			= 2			--每日副本
RETRIEVE_TYPE_SCENE_TYPE	= 3			--每日类型场景


require("config.loader.retrieve_loader")
require("retrieve.retrieve_db")
require("retrieve.retrieve_mgr")
require("retrieve.retrieve_container")
require("retrieve.retrieve_process")

require("retrieve.retrieve.retrieve_base_include")
g_retrieve_mgr = Retrieve_mgr()

local function get_retrieve_info(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	return player and player:get_retrieve_con()
end

--监听进入副本
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_SCENE, get_retrieve_info, Retrieve_container.notify_enter_scene_event)

--监听任务完成事件
g_event_mgr:register_event(EVENT_SET.EVENT_COMPLETE_QUEST, get_retrieve_info, Retrieve_container.notify_complete_quest_event)