local debug_print = function() end


require("reward.obj_reward")
require("reward.reward_mgr")

--require("reward/login_reward/reward_handler")
--require("reward/buffer_reward/buffer_reward_handler")

require("reward.reward_exp")


local reward_err_fun = function(obj_id, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_REWARD_ERROR_S, new_pkt)
end

--登陆时请求奖励礼包
Clt_commands[1][CMD_MAP_REWARD_LOGIN_C] =
function(conn, pkt)
	if conn.char_id ~= nil then
		if g_reward_mgr:create_reward_obj(conn.char_id) == false then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_LOGIN_S, {})
			return  --全部领完
		end

		local s_pkt = {}
		s_pkt["remain_tm"] = g_reward_mgr:get_reward_remain_time(conn.char_id)
		--s_pkt["item_id"] = 10001
		s_pkt["reward"]  = {}
		s_pkt["reward"].id = g_reward_mgr:get_reward_item(conn.char_id)[2]
		s_pkt["reward"].num = g_reward_mgr:get_reward_item(conn.char_id)[3]

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_LOGIN_S, s_pkt)
	end
end

--领取奖励
Clt_commands[1][CMD_MAP_REWARD_GET_C] =
function(conn, pkt)
	local s_pkt = {}
	s_pkt["result"] = 0
	local ret_code = g_reward_mgr:featch_reward(conn.char_id)
	if ret_code ~= 0 then
		debug_print("featch_reward return ret_code", ret_code)
		if ret_code == 27002 then --领取最后一次
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_GET_S, s_pkt)
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_LOGIN_S, {})

			g_reward_mgr:destroy_reward_obj(conn.char_id)
			return
		end

		s_pkt["result"] = ret_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_GET_S, s_pkt)
		return
	end

	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_GET_S, s_pkt)

	local ss_pkt = {}
	ss_pkt["remain_tm"] = g_reward_mgr:get_reward_remain_time(conn.char_id)
	--ss_pkt["item_id"] = 10001
	ss_pkt["reward"]  = {}
	ss_pkt["reward"].id = g_reward_mgr:get_reward_item(conn.char_id)[2]
	ss_pkt["reward"].num = g_reward_mgr:get_reward_item(conn.char_id)[3]
	
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_LOGIN_S, ss_pkt)
end