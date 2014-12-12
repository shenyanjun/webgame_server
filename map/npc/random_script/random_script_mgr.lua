


Random_script_mgr = oo.class(nil, "Random_script_mgr")

function Random_script_mgr:__init()
	self.random_script_list = {}
end

function Random_script_mgr:get_random_script(char_id)
    if self.random_script_list[char_id] == nil then
        self.random_script_list[char_id] = Random_script()
    end
	return self.random_script_list[char_id]
end

--清空玩家与神秘商人的物品列表
--[[function Random_script_mgr:set_zero_npc_char(char_id)
    local temp = self:get_random_script(char_id)
	if temp ~= nil then
        temp:set_zero_char()
    end
end]]

--清空玩家与神秘商人的物品列表
function Random_script_mgr:event_del_team(args, char_id)
	local char_id = args.char_id
	local temp = self:get_random_script(char_id)
	if temp ~= nil then
        temp:set_zero_char()
    end
end
