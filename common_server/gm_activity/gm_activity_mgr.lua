
--2012-03-01
--cqs
--后台活动管理类

-----------------------------------活动-----------------------------

--local collection_activity_loader = require("config.loader.collection_activity_loader")
local _builder={}
function reg_activity_item_builder(type,cls)
	_builder[type] = cls
end
function get_activity_item_builder(type)
	return _builder[type] or Gm_activity_item
end

Gm_activity_mgr = oo.class(nil, "Gm_activity_mgr")

require("gm_activity.gm_activity_item")

function Gm_activity_mgr:__init()
	self.items = {}
	for i = 1, ACTIVITY_TYPE.MAX do
		self.items[i] = get_activity_item_builder(i)(i)--Gm_activity_item(i)
	end
end

function Gm_activity_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Gm_activity_mgr:on_timer()
	for k, v in ipairs(self.items) do
		v:on_timer()
	end
end

function Gm_activity_mgr:syn_all_activity(server_id)
	for k, v in ipairs(self.items) do
		v:syn_activity_to_map(server_id)
	end
end

--收到后台活动通知
function Gm_activity_mgr:accept_notice(type)
	if self.items[type] then
		self.items[type]:accept_notice()
	end
	return
end

