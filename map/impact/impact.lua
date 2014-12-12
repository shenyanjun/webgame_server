
--local debug_print = print
local debug_print = function() end

--************效果顶层类(可序列化的类，可以转化为json对象，不能用int做key)*************
Impact_base = oo.class(nil, "Impact_base")

--obj_id 为所有对象id，包括角色，怪物
function Impact_base:__init(obj_id)
	self.obj_id = obj_id    --对象id

	self.type = nil       --效果类型
	self.cmd_id = nil     --效果id
	self.time_count = 0   --定时器计数
	self.sec_count = IMPACT_MIN_TIMER    --多少秒轮询一次
	self.count = nil      --轮询次数
	self.cur_count = 0    --当前轮询次数，用于计数
	self.tm_start = ev.time

	self.param = nil      --附加参数
	self.level = 1

	self.flag = 0              --0 下线计时，1 下线不计时
	self.flag_splice = 0       --0 不叠加 1叠加

	self.class_nm = "Impact"
end

function Impact_base:get_cmd_id()
	return self.cmd_id
end
function Impact_base:get_type()
	return self.type
end
function Impact_base:get_level()
	return self.level
end

function Impact_base:set_flag(flag)
	self.flag = flag or 0
end

--获取效果影响
function Impact_base:get_effect()
end
--效果影响
function Impact_base:effect(param)
	if Obj_mgr.obj_type(self.obj_id) ~= OBJ_TYPE_PET then
		return self:on_effect(param)
	end
end
function Impact_base:on_effect(param)
end

function Impact_base:set_count(count)
	self.count = count
	self.cur_count = 0
end

function Impact_base:add_count(count)
	self.count = self.count + count
end

function Impact_base:set_sec_count(sec_count)
	self.sec_count = sec_count
end

--获取剩余时间
function Impact_base:get_last_time()
	return math.max(self.tm_start + self.count * self.sec_count - ev.time, 0)
end

--获取每次事件响应时间(间断性效果子类需要重载此方法，如中毒，定时回血)
function Impact_base:get_event_time()
	return self:get_last_time() + ev.time
end

--暂停函数(flag:0运行 1暂停)
function Impact_base:is_pause()
	return false
end
function Impact_base:pause(flag)
end

--附加参数,给客户端
function Impact_base:get_param()
	return nil
end

function Impact_base:stop()
	local obj = g_obj_mgr:get_obj(self.obj_id)
	self:on_stop()
	if obj ~= nil then
		local new_pkt = {}
		new_pkt.id = self.cmd_id
		new_pkt.obj_id = self.obj_id

		if obj:get_type() == OBJ_TYPE_HUMAN then
			g_cltsock_mgr:send_client(self.obj_id, CMD_MAP_IMPACT_STOP_S, new_pkt)
			obj:on_update_impact(2)
		end

		if self:is_net_serialize() then
			local scene_o = obj:get_scene_obj()
			if not scene_o then
				local debug = Debug(g_debug_log)
				local msg = string.format(
								"Impact_base:stop(%s, %s, %s)"
								, tostring(self.cmd_id)
								, tostring(self.obj_id)
								, tostring(obj:get_map_id()))
				debug:trace(msg)
			end
			scene_o:send_screen(self.obj_id, CMD_MAP_IMPACT_STOP_S, new_pkt, nil)
		end
	end
end

--效果同步给屏内其他玩家
function Impact_base:syn(param)
	local obj_d = g_obj_mgr:get_obj(self.obj_id)
	if obj_d ~= nil then
		local new_pkt = self:net_get_info()
		if obj_d:get_type() == OBJ_TYPE_HUMAN then
			g_cltsock_mgr:send_client(self.obj_id, CMD_MAP_IMPACT_SYN_S, new_pkt)
			obj_d:on_update_impact(1)
		end

		if self:is_net_serialize() then
			local scene_o = obj_d:get_scene_obj()
			
			if not scene_o then
				f_scene_error_log("function Impact_base:syn(obj_id = %d, map_id = %s, cmd_id = %s) Not Scene."
					, self.obj_id
					, tostring(obj_d:get_map_id())
					, tostring(self.cmd_id))
			end
			
			scene_o:send_screen(self.obj_id, CMD_MAP_IMPACT_SYN_S, new_pkt, nil)   --屏内广播
		end
	end
end

--效果免疫
function Impact_base:immune()
	local obj_d = g_obj_mgr:get_obj(self.obj_id)
	if obj_d ~= nil then
		local scene_o = obj_d:get_scene_obj()
		local new_pkt = {}
		new_pkt.obj_id = self.obj_id
		new_pkt.impact_id = self.cmd_id
		scene_o:send_screen(self.obj_id, CMD_MAP_IMPACT_IMMUNE_SYN_S, new_pkt, 1)
	end
end

--效果叠加时间
function Impact_base:splice(item)
	if self.flag_splice == 0 then   			--替换
		if item.level >= self.level then        --高级别替换低级别
			return item
		else
			return self
		end
	else      									--叠加
		return self:on_splice(item)
	end
end
--效果叠加回调
function Impact_base:on_splice(item)
	if item.level == self.level then                       			
		self.count = self.count + item.count
		return self
	else                                   --级别不同，直接替换
		return item
	end
end

--效果序列化
--[[function Impact_base:serialize()
end]]



-----------网络通信--------
--是否网络序列化同步给其他人
function Impact_base:is_net_serialize()
	return false
end

function Impact_base:net_get_info()
	local list = {}
	list.impact_id = self.cmd_id
	list.time = self:get_last_time() --(self.count - self.cur_count) * self.sec_count 
	list.des_id = self.obj_id
	list.param = self:get_param()
	return list
end

-----------event--------------
--click回调，返回-1则移出click池
--[[function Impact_base:on_timer(tm)
	self.time_count = self.time_count + tm
	if self.time_count >= self.sec_count then  
		self.time_count = 0

		--self.cur_count = self.cur_count + 1
		return self:on_process()
	end
end]]
--效果停止时回调
function Impact_base:on_stop()
end
function Impact_base:on_process()
	--[[if self.count <= self.cur_count then   --轮询次数判断
		return -1
	end]]
	if --[[self.flag == 0 and]] ev.time >= self.tm_start + self.count*self.sec_count then   --总时间点判断
		return -1
	end
end

--玩家上线时，恢复效果
function Impact_base:on_resume()
	self:syn(self.param)
end



 --***********效果基类，持久化***********
Impact_s = oo.class(Impact_base, "Impact_s")

function Impact_s:__init(obj_id)
	Impact_base.__init(self, obj_id)
end

--对象死亡是否清理impact
function Impact_s:is_clear()
	return true
end
--[[function Impact_s:clear()
end]]

--剩余时间大于15秒或debuff大于10秒需要保存
function Impact_s:is_save()
	if Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN and 
		(self.count*self.sec_count + self.tm_start - ev.time > 15 or 
		(self.flag == 1 and self.count*self.sec_count + self.tm_start - ev.time > 10)) then    
		return true
	end
	return false
end

--是否可以clone
function Impact_s:is_clone()
	return true
end
function Impact_s:clone(item)
	--复制数据
	for k,v in pairs(item) do
		self[k] = v
	end

	if self.flag == 1 then
		self.cur_count = self.cur_count + 1  --向小取整时间
		self.tm_start = ev.time - self.cur_count * self.sec_count
	end

	local tm = self.tm_start + self.count*self.sec_count - ev.time
	if tm > 0 and self:is_clone() then  
		self.time_count = 0   
		self.cur_count = self.flag == 1 and self.cur_count or self.count - math.floor(tm/self.sec_count)
		self:on_resume()
		return self
	end
end

function Impact_s:serialize_to_db()
	local item_l = {}
	--item_l.time_count = self.time_count
	item_l.count = self.count
	item_l.cur_count = (ev.time - self.tm_start)/self.sec_count    --self.cur_count
	item_l.tm_start = self.tm_start

	item_l.level = self.level
	item_l.param = self.param
	item_l.class_nm = self.class_nm
	self:on_serialize_to_db(item_l)

	return item_l
end
--子类实现
function Impact_s:on_serialize_to_db(item_l)
end





