
local _dis = 20     --有效距离

require("compete.obj_compete")
require("compete.compete_mgr")

local err_fun = function(obj_id, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_COMPETE_ERROR_S, new_pkt)
end


--邀请
Clt_commands[1][CMD_MAP_COMPETE_REQUEST_C] =
function(conn, pkt)
	--print("----_command[CMD_MAP_COMPETE_REQUEST_C]", conn.char_id, pkt.obj_id)
	if conn.char_id ~= nil and pkt.obj_id ~= nil then
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
		local scene_o = obj_s:get_scene_obj()
		if obj_s ~= nil then
			--被邀请人判断
			local err = 0
			if obj_d == nil then
				err = 20201
			elseif obj_s:get_compete() ~= nil then
				err = 20202
			elseif obj_d:get_compete() ~= nil then 
				err = 20203
			elseif scene_o:get_mode() ~= MAP_MODE_PEACE then
				err = 20204
			elseif f_is_pvp() or f_is_line_faction() or f_is_line_ww() then
				err = 20207
			elseif obj_s:get_scene()[1] ~= obj_d:get_scene()[1] or 
				g_compete_mgr:distance(obj_s:get_pos(), obj_d:get_pos()) > _dis then
				err = 20205
			elseif obj_s:get_team() ~= nil and obj_s:get_team() == obj_d:get_team() then
				err = 20208
			end

			if err ~= 0 then
				err_fun(conn.char_id, err)
				return
			end

			if g_compete_mgr:add_request(conn.char_id, pkt.obj_id) then
				local new_pkt = {}
				new_pkt.obj_id = conn.char_id
				new_pkt.name = obj_s:get_name()
				g_cltsock_mgr:send_client(pkt.obj_id, CMD_MAP_COMPETE_REQUEST_ANSWER_S, new_pkt)
			end
		end
	end
end

--邀请确认
Clt_commands[1][CMD_MAP_COMPETE_REQUEST_ANSWER_C] =
function(conn, pkt)
	if conn.char_id ~= nil and pkt.obj_id ~= nil then
		local obj_s = g_obj_mgr:get_obj(pkt.obj_id)
		local obj_d = g_obj_mgr:get_obj(conn.char_id)
		if obj_s ~= nil and obj_d ~= nil then
			--超时
			local scene_o = obj_s:get_scene_obj()
			if not g_compete_mgr:is_request(pkt.obj_id) then
				err_fun(conn.char_id, 20206)
				return
			elseif scene_o:get_mode() ~= MAP_MODE_PEACE then --地图
				err_fun(conn.char_id, 20204)
				return
			elseif f_is_pvp() or f_is_line_faction() or f_is_line_ww() then
				err_fun(conn.char_id, 20207)
				return
			elseif obj_s:get_scene()[1] ~= obj_d:get_scene()[1] or 
				g_compete_mgr:distance(obj_s:get_pos(), obj_d:get_pos()) > _dis then  --距离
				err_fun(conn.char_id, 20205)
				return
			elseif obj_s:get_compete() ~= nil then  --正在切磋
				err_fun(conn.char_id, 20202)
				return
			elseif obj_d:get_compete() ~= nil then
				err_fun(conn.char_id, 20203)
				return
			elseif obj_s:get_team() ~= nil and obj_s:get_team() == obj_d:get_team() then
				err_fun(conn.char_id, 20208)
				return
			end
			
			local cp_o = g_compete_mgr:create(obj_s, obj_d)
			local new_pkt = cp_o:net_get_info()
			local scene_o = obj_s:get_scene_obj()
			scene_o:send_screen(pkt.obj_id, CMD_MAP_COMPETE_START_S, new_pkt, 1)

			g_compete_mgr:del_request(pkt.obj_id)
		end
	end
end