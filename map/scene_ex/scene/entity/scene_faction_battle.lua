
local faction_battle_config = require("scene_ex.config.faction_battle_loader")

Scene_faction_battle = oo.class(Scene_instance, "Scene_faction_battle")

function Scene_faction_battle:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.wait_relive = {}
	self.relive_time = self:get_self_config().relive.time or 5
	self.die_record = {}
	self.kill_record = {{}, {}}

	self.final_score = {0, 0}
	self.final_score_each = {{}, {}}
	self.win_side = 1
	self.end_time = 0
	--self.status = SCENE_STATUS.CLOSE
	local b_l = g_faction_battle_mgr:get_battle_letter(instance_id)
	if b_l ~= nil then
		self.applyer = b_l.applyer
		self.replyer = b_l.replyer
		self.wager_type = b_l.wager_type
		self.wager = b_l.wager
		f_scene_info_log("faction battle start s_id:%d, instance_id:%s, applyer:%d replyer:%d wager_type:%d wager:%d",
							self.id, self.instance_id, self.applyer, self.replyer, self.wager_type, self.wager)
	end
end

function Scene_faction_battle:get_self_config()
	return faction_battle_config.config[self.id]
end

function Scene_faction_battle:get_mode()
	if SCENE_STATUS.OPEN == self.status then
		local config = g_scene_config_mgr:get_config(self.id)
		return config and config.mode
	end
	return SCENE_MODE.PEACE
end

--副本出口
function Scene_faction_battle:get_home_carry(obj)
	local config = g_all_scene_config[self.id]
	local home_carry = config and config.home
	if not home_carry or not home_carry.id or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end


function Scene_faction_battle:can_carry(obj)

	return SCENE_ERROR.E_SUCCESS
end

function Scene_faction_battle:on_timer(tm)
	
	if SCENE_STATUS.OPEN == self.status then
		if self.end_time <= ev.time then
			self:to_freeze()
		end
	end
	
	Scene_instance.on_timer(self, tm)

	self:do_relive(ev.time)
end

function Scene_faction_battle:to_freeze()
	self.end_time = ev.time + 30
	self.status = SCENE_STATUS.FREEZE
	self:do_relive(ev.time+self.relive_time)

	local win_side = self:compute_score()
	self:end_notify(win_side)
	g_faction_battle_mgr:faction_battle_over(self.instance_id, win_side)
end

function Scene_faction_battle:end_notify(win_side)
	--print("Scene_faction_battle:end_notify", win_side)
	--邮件返还胜方押金
	local email_pkt = {}
	email_pkt.sender = -1
	email_pkt.title = f_get_string(2233)
	email_pkt.box_title = f_get_string(2236)
	email_pkt.money_list = {}
	email_pkt.item_list = {}
	local re_content = f_get_string(2238)
	if self.wager_type == 1 then
		email_pkt.money_list[MoneyType.JADE] = self.wager
	elseif self.wager_type == 2 then
		email_pkt.money_list[MoneyType.GOLD] = self.wager		
	end
	local each_reward = 0
	local win_size = 0
	if win_side == 1 then
		email_pkt.recevier = self.applyer
		email_pkt.content = string.format(f_get_string(2234), g_faction_battle_mgr:get_battle_reply_name(self.instance_id))
		re_content = string.format(re_content, g_faction_battle_mgr:get_battle_reply_name(self.instance_id))
		win_size = table.size(self.kill_record[1])
	else
		email_pkt.recevier = self.replyer
		email_pkt.content = string.format(f_get_string(2234), g_faction_battle_mgr:get_battle_apply_name(self.instance_id))
		re_content = string.format(re_content, g_faction_battle_mgr:get_battle_apply_name(self.instance_id))
		win_size = table.size(self.kill_record[2])			
	end
	if (self.wager_type == 1 or self.wager_type == 2) and self.wager > 0 then
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, email_pkt)
		each_reward = win_size > 0 and math.floor(self.wager / win_size) or 0
	end
	if each_reward > 0 then
		for obj_id, _  in pairs(self.kill_record[win_side]) do
			email_pkt.title = f_get_string(2237)
			email_pkt.box_title = f_get_string(2237)
			email_pkt.content = re_content
			email_pkt.recevier = obj_id
			if self.wager_type == 1 then
				email_pkt.money_list[MoneyType.JADE] = each_reward
			elseif self.wager_type == 2 then
				email_pkt.money_list[MoneyType.GOLD] = each_reward		
			end
			g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, email_pkt)
		end
	end

	if self.obj_mgr then
		local con = self.obj_mgr:get_obj_con(OBJ_TYPE_HUMAN)
		if con then
			local pkt = {}
			pkt.win_side = win_side
			pkt.score_list = {}
			local side_l = {}
			if #self.final_score_each[1] <= 10 then
				side_l[1] = self.final_score_each[1]
			else
				side_l[1] = {}
				for i=1, 10 do
					side_l[1][i] = self.final_score_each[1][i]
				end
			end
			if #self.final_score_each[2] <= 10 then
				side_l[2] = self.final_score_each[2]
			else
				side_l[2] = {}
				for i=1, 10 do
					side_l[2][i] = self.final_score_each[2][i]
				end
			end
			for obj_id, _ in pairs(con:get_obj_list()) do
				local obj = g_obj_mgr:get_obj(obj_id)
				if obj then
					--[[
					if obj:get_side() == win_side and each_reward > 0 then
						local pack_con = obj:get_pack_con()
						local money_list = {}
						if self.wager_type == 1 then
							money_list[MoneyType.JADE] = each_reward		
						elseif self.wager_type == 2 then
							money_list[MoneyType.GOLD] = each_reward	
						end							
						local src_log = {["type"] = MONEY_SOURCE.FACTION_BATTLE_WIN}
						pack_con:add_money_l(money_list, src_log)
					end
					]]
					pkt.my_side = obj:get_side()
					pkt.score_list[1] = side_l[pkt.my_side]
					local oth_side = pkt.my_side == 1 and 2 or 1
					pkt.score_list[2] = side_l[oth_side]
					g_cltsock_mgr:send_client(obj_id, CMD_FACTION_BATTLE_END_NOTIFY_S, pkt)
				end
			end
		end
	end
	
end

function Scene_faction_battle:do_relive(now_time)
	local obj_mgr = g_obj_mgr
	for char_id, time in pairs(self.wait_relive) do
		local config = self:get_self_config()
		if time <= now_time then
			local obj = obj_mgr:get_obj(char_id)
			if obj then
				self.wait_relive[char_id] = nil
				if not obj:is_alive() then
					local pos = self:get_relive_pos(obj:get_side())
					--obj:relive_and_convey(1, self.id, pos)
					obj:do_relive(1, true)	--复活
					obj:send_relive(3)
					self:transport(obj, pos)
				end
			end
		end
	end
end

function Scene_faction_battle:on_obj_enter(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		self.wait_relive[obj_id] = nil
		local side = g_faction_battle_mgr:get_battle_side(obj:get_id()) or 2
		obj:set_side(side)
		if self.kill_record[side][obj_id] == nil then
			self.kill_record[side][obj_id] = 0 
		end
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_OUT_FACTION, obj_id, self, self.out_faction_event)
	end
end

function Scene_faction_battle:on_obj_leave(obj)
	if OBJ_TYPE_HUMAN == obj:get_type() then
		local obj_id = obj:get_id()
		if not obj:is_alive() then
			self.wait_relive[obj_id] = nil
			obj:do_relive(1, true)
		end
		obj:set_side(0)
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_OUT_FACTION, obj_id)
	end
end

function Scene_faction_battle:out_faction_event(obj_id)
	if obj_id then
		self:kickout(obj_id)
	end
end

function Scene_faction_battle:die_event(args)
	local killer_id = args.killer_id
	local obj_id = args.char_id
	local obj = self:get_obj(obj_id)
	if obj then
		self.die_record[obj_id] = (self.die_record[obj_id] or 0) + 1
		self.wait_relive[obj_id] = ev.time + self.relive_time			--加入等待复活列表
		
		args.mode = 1
		args.is_notify = false
		args.is_evil = false
		args.relive_time = math.max(self.wait_relive[obj_id] - ev.time, 0)
		
		local killer = killer_id and self:get_obj(killer_id)
		if killer and OBJ_TYPE_HUMAN == killer:get_type() then				--被玩家杀死
			local side = killer:get_side()
			self.kill_record[side][killer_id] = (self.kill_record[side][killer_id] or 0) + 1		
		end
	end
end

function Scene_faction_battle:get_relive_pos(side)
	local config = self:get_self_config()
	return config.relive[side][crypto.random(#config.relive[side], #config.relive[side] + 1)]
end

function Scene_faction_battle:compute_score()
	local cmp = function(e1,e2) 
					return e1[4] > e2[4]
				end

	self.final_score = {0, 0}	
	local apply_name = g_faction_battle_mgr:get_battle_apply_name(self.instance_id)
	local reply_name = g_faction_battle_mgr:get_battle_reply_name(self.instance_id)
	local apply_id = g_faction_battle_mgr:get_battle_apply_id(self.instance_id)
	local reply_id = g_faction_battle_mgr:get_battle_reply_id(self.instance_id)

	local enter1, enter2 = 0, 0
	for k, v in pairs(self.kill_record[1]) do
		self.final_score[1] = self.final_score[1] + v
		--
		local obj = g_obj_mgr:get_obj(k)
		if obj ~= nil then
			table.insert(self.final_score_each[1], {k, obj:get_name(), apply_name, v})
		end
		enter1 = enter1 + 1
	end
	table.sort(self.final_score_each[1], cmp)

	for k, v in pairs(self.kill_record[2]) do
		self.final_score[2] = self.final_score[2] + v
		--
		local obj = g_obj_mgr:get_obj(k)
		if obj ~= nil then
			table.insert(self.final_score_each[2], {k, obj:get_name(), reply_name, v})
		end
		enter2 = enter2 + 1
	end
	table.sort(self.final_score_each[2], cmp)

	--print("self.final_score[1]  self.final_score[2]", self.final_score[1] , self.final_score[2])
	win_side = self.final_score[1] >= self.final_score[2] and 1 or 2
	if self.final_score[1] == 0 and self.final_score[2] == 0 then
		win_side = enter1 >= enter2 and 1 or 2
	end
	--f_scene_info_log("faction battle s_id:%d, instance_id:%s, apply:%s :%d reply:%s :%d win:%d",
	--						self.id, self.instance_id, apply_name, enter1, reply_name, enter2, win_side)
	--后台流水
	local str = string.format("insert into log_faction_battlefield set start_time=%d, end_time=%d, winner='%s', winner_id='%s', winner_people=%d, failed='%s', failed_id='%s', failed_people=%d, battlefield=%d, winner_kill=%d, failded_kill=%d, money_type=%d, money=%d",
							self.start_time, self.end_time, win_side == 1 and apply_name or reply_name, win_side == 1 and apply_id or reply_id, win_side == 1 and enter1 or enter2, 
							win_side == 1 and reply_name or apply_name, win_side == 1 and reply_id or apply_id, win_side == 1 and enter2 or enter1, self.id,
							win_side == 1 and self.final_score[1] or self.final_score[2], win_side == 1 and self.final_score[2] or self.final_score[1],
							self.wager_type or 0, self.wager or 0)
	f_multi_web_sql(str)
	return win_side
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_faction_battle:carry_scene(obj, pos)
	--print("Scene_faction_battle:carry_scene()", obj, pos[1], pos[2])
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end
	
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end

function Scene_faction_battle:instance()
	self.start_time = ev.time
	self.end_time = g_faction_battle_mgr:get_letter_remain_time(self.instance_id) + ev.time
	self.status = SCENE_STATUS.OPEN
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
end