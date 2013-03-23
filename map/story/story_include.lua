E_SUCCESS							= 	0			--成功
E_STORY_INVALID_DATA						=	27701		--无效的数据
E_STORY_INCOMPLETE						=	27702		--未完成
E_STORY_INVALID_ID						=	27703		--无效的目标
E_STORY_PREQUEST						=	27704		--条件未满足
E_STORY_EXISTS							=	27705		--不能在一个剧情副本里再开启一个剧情副本

require("story.story_loader")
require("story.story_container")
require("story.story_process")

local function get_story_con(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	return player and player:get_story_con()
end


--监听等级提升事件
g_event_mgr:register_event(EVENT_SET.EVENT_LEVEL_UP, get_story_con, Story_container.notify_level_up_event)