

require("identify.identify_process")
require("identify.identify_container")

local function get_identify_info(char_id)
	return g_identify_con
end


--监听进入
g_event_mgr:register_event(EVENT_SET.EVENT_ENTER_SCENE, get_identify_info, Identify_container.enter_scene)

--监听离开
g_event_mgr:register_event(EVENT_SET.EVENT_LEAVE_SCENE, get_identify_info, Identify_container.leave_scene)
