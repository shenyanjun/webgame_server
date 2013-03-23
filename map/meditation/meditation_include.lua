
require("meditation.meditation_container")
require("meditation.meditation_mgr")
require("meditation.meditation_process")
g_meditation_mgr = Meditation_mgr()




local function get_meditation_con(char_id)
	return g_meditation_mgr:get_meditation(char_id)
end



--监听杀死怪物事件
g_event_mgr:register_event(EVENT_SET.EVENT_DIE, get_meditation_con, Meditation_container.set_status)
g_event_mgr:register_event(EVENT_SET.EVENT_LEAVE_SCENE, get_meditation_con, Meditation_container.set_status)
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_SCENE, get_meditation_con, Meditation_container.set_status)