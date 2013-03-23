
--2012-01-11
--cqs
--活动奖励获取

---------------------------------------------------------------

local collection_activity_loader = require("config.loader.collection_activity_loader")


Activity_reward_mgr = oo.class(nil, "Activity_reward_mgr")

--定时存盘时间
local update_items = 150
local update_records = 400

function Activity_reward_mgr:__init()
	self.swicth = true

	self.dragon_occ = nil

	self:init_reward_info()
	--local info = g_gm_function_con:get_long_info()
	--if info then
		--self:set_init(info.end_t,info.id,true)
	--end
end

--外部开启接口
function Activity_reward_mgr:set_init(ti, id, init)
	self.change_t = ti
	self.id = id	
	self.end_t = ti

	if self.id then						--活动开始
		if not self.lvl then
			self.lvl = 1
		end

		if f_is_map_list() then
			local statue_id = collection_activity_loader.get_statue_id(self.id)
			local name, x, y, scene_id = collection_activity_loader.get_dragon_statue_info(self.id)
			local post = {}
			post[1] = x
			post[2] = y
			--print("36 =", statue_id, name, j_e(post), j_e({scene_id}))
			local obj = f_npc_create_enter(statue_id, name, post, {scene_id}, {})
			self.dragon_occ = obj:get_id()
		end

		--打开所有在线玩家活动
		local online = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
		for k, v in pairs(online or {}) do
			local ar_con = v:get_ar_con()
			ar_con:open_activity(self.id, self.lvl)
		end
	end

	if init == true then
		self.statue_occ = nil	--雕像OCC
	end
end

--外部关闭
function Activity_reward_mgr:close()
	self.change_t = nil
	self.id  = nil
	self.lvl = nil
	if self.dragon_occ then
		f_npc_leave(self.dragon_occ)
		self.dragon_occ = nil
	end
	if self.statue_occ then
		f_npc_leave(self.statue_occ)
		self.statue_occ = nil
	end
end

function Activity_reward_mgr:init_reward_info()
	--self.change_t, self.id = collection_activity_loader.get_recently_id()
	----print("23 ", self.id)
	--self.lvl = nil
--
	--if self.id then						--活动开始
		--self.lvl = 1
--
		--if f_is_map_list() then
			--local statue_id = collection_activity_loader.get_statue_id(self.id)
			--local name, x, y, scene_id = collection_activity_loader.get_dragon_statue_info(self.id)
			--local post = {}
			--post[1] = x
			--post[2] = y
			----print("36 =", statue_id, name, j_e(post), j_e({scene_id}))
			--local obj = f_npc_create_enter(statue_id, name, post, {scene_id}, {})
			--self.dragon_occ = obj:get_id()
		--end
--
		----打开所有在线玩家活动
		--local online = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
		--for k, v in pairs(online or {}) do
			--local ar_con = v:get_ar_con()
			--ar_con:open_activity(self.id, selfl.lvl)
		--end
--
	--else								--活动结束
		--if f_is_map_list() then 
			--if self.dragon_occ then
				--f_npc_leave(self.dragon_occ)
				--self.dragon_occ = nil
			--end
			--if self.statue_occ then
				--f_npc_leave(self.statue_occ)
				--self.statue_occ = nil
			--end
		--end
	--end
--
	--self.statue_occ = nil	--雕像OCC
end

----------------计时器--------------
function Activity_reward_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Activity_reward_mgr:on_timer()
	if self.change_t and ev.time > self.change_t then	--改变时间到
		self:init_reward_info()
	end 
end

-------------------------------------***内部接口***------------
--function Activity_reward_mgr:notice_lvlup()
	--local player_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	--for k, v in pairs(player_l) do
		--local ar_con = v:get_ar_con()
		--ar_con:reward_lvlup()
	--end 
--end


------------------------------------***外部接口***------------
function Activity_reward_mgr:reward_level_up(lvl)
	local info = g_gm_function_con:get_long_info()
	if not info then return end
	self.id = info.id
	if not self.lvl then
		self.lvl = 1
	end
	if self.id then
		if self.lvl < lvl then
			self.lvl = lvl
			--给在线玩家发升级奖励
			--self:notice_lvlup()

			--更新雕像
		end
	end
end

function Activity_reward_mgr:change_statue()
	local info = g_gm_function_con:get_long_info()
	print(j_e(info))
	if not info then return end
	self.id = info.id
	self.change_t = info.end_t
	if not self.lvl then
		self.lvl = 1
	end

	if f_is_map_list() then
		local occ = collection_activity_loader.get_statue_occ(self.id, self.lvl)
		local name, x, y, scene_id = collection_activity_loader.get_statue_info(self.id)
		local post = {}
		post[1] = x
		post[2] = y
		if self.statue_occ then
			f_npc_leave(self.statue_occ)
		end
		--print("77 =", occ, name, j_e(post), scene_id)
		local obj = f_npc_create_enter(occ, name, post, {scene_id}, {})
		self.statue_occ = obj:get_id()
	end
end

function Activity_reward_mgr:delete_statue()
	if f_is_map_list() then
		if self.statue_occ then
			f_npc_leave(self.statue_occ)
		end
	end
	--print("84")
end

function Activity_reward_mgr:get_lvl()
	return self.lvl 
end

function Activity_reward_mgr:get_end_time()
	return self.end_t 
end

function Activity_reward_mgr:get_id()
	local info = g_gm_function_con:get_long_info()
	if not info then return end
	self.id = info.id
	return self.id
end

function Activity_reward_mgr:get_buf_limit(buf_id)
	return collection_activity_loader.get_buf_limit(self.id, self.lvl, buf_id)
end

function Activity_reward_mgr:get_buf_effect(buf_id)
	return collection_activity_loader.get_buf_effect(self.id, self.lvl, buf_id), self.lvl
end

--活动开关
function Activity_reward_mgr:activity_swicth(swicth)
	if swicth == 1 and self.swicth == false then		--活动打开
		self.swicth = true
	elseif swicth == 0 and self.swicth == true then		--活动关闭
		self.swicth = false
	end
end

--活动开关
function Activity_reward_mgr:get_swicth()
	return self.swicth
end
--------------------------------------与common交互-------



