require("impact.impact")

--local debug_print = print
local debug_print = function() end

--************ 帮派效果顶层类 *************
Faction_impact_base = oo.class(Impact_base, "Faction_impact_base")

--obj_id 为所有对象id，包括角色，怪物
function Faction_impact_base:__init(faction_id)
	Impact_base._init(self, faction_id)

	self.class_nm = "Faction_impact_base"
end



--附加参数,给客户端
function Faction_impact_base:get_param()
	return nil
end

function Faction_impact_base:stop()

	self:on_stop()
	local faction_o = g_faction_mgr:get_faction_by_fid(self.obj_id)
	local player_l = faction_o:get_faction_player_list()
	for player_id, v in pairs(player_l) do
		local obj = g_obj_mgr:get_obj(player_id)
		if obj ~= nil then
			local _ = obj.on_update_attribute and obj:on_update_attribute(1)
			local scene_o = obj:get_scene_obj()
			local new_pkt = {}
			new_pkt.id = self.cmd_id
			new_pkt.obj_id = player_id
			scene_o:send_screen(player_id, CMD_MAP_IMPACT_STOP_S, new_pkt, 1)

			if obj:get_type() == OBJ_TYPE_HUMAN then
				obj:on_update_impact(2)
			end
		end
	end
end

function Faction_impact_base:on_stop()

end

--效果同步 player_id==nil 时同时帮派所有成员
function Faction_impact_base:syn(player_id)
	local player_l = {}	local is_update_attr = false	if player_id then		player_l[player_id] = player_id	else		local faction_o = g_faction_mgr:get_faction_by_fid(self.obj_id)
		player_l = faction_o and faction_o:get_faction_player_list()		is_update_attr = true	end
	for player_id, v in pairs(player_l or {}) do
		local obj_d = g_obj_mgr:get_obj(player_id)
		if obj_d ~= nil then
			local new_pkt = self:net_get_info(player_id)
			if obj_d:get_type() == OBJ_TYPE_HUMAN then
				g_cltsock_mgr:send_client(player_id, CMD_MAP_IMPACT_SYN_S, new_pkt)
				obj_d:on_update_impact(1)
				if is_update_attr then
					local _ = obj_d.on_update_attribute and obj_d:on_update_attribute(1)
				end
			end

			if self:is_net_serialize() then
				local scene_o = obj_d:get_scene_obj()
				scene_o:send_screen(player_id, CMD_MAP_IMPACT_SYN_S, new_pkt, nil)   --屏内广播
			end
			--print("===>Faction_impact_base:syn:id:", player_id, "new_pkt:", Json.Encode(new_pkt))
		end
	end
end

--效果免疫
function Faction_impact_base:immune()

end


-----------网络通信--------
--是否网络序列化同步给其他人
function Faction_impact_base:is_net_serialize()
	return false
end

function Faction_impact_base:net_get_info(player_id)
	local list = {}
	list.impact_id = self.cmd_id
	list.time = self:get_last_time()
	list.des_id = player_id
	list.param = self:get_param()
	return list
end






