
Team_mgr = oo.class(nil, "Team_mgr")

function Team_mgr:__init()
	self.team_l = {}

	--时间计数
	self.time_count = 0         --时间计数

	--副本关联
	self.copy_container = Team_copy_container()

	--所有加入过组的对象列表
	self.char_list = {}
end

function Team_mgr:get_copy_container()
	return self.copy_container
end

function Team_mgr:create_team(obj_id, team_id)
	local team_obj = Obj_team(team_id)
	self.team_l[team_obj:get_id()] = team_obj
	team_obj:new(obj_id)
	self:add_char_id(obj_id, team_obj:get_id())

	f_cmd_show(obj_id, 20101)
	return team_obj
end

function Team_mgr:get_team_obj(team_id)
	if team_id ~= nil then
		return self.team_l[team_id]
	end
end
function Team_mgr:del_team(team_id)
	local team_obj = self.team_l[team_id]
	if team_obj then
		for k,v in pairs(team_obj:get_team_l()) do 
			--team_obj:del_obj(k)
			self:del_char_id(k)
		end

		self.team_l[team_id] = nil
		return true
	end
	return false
end

--玩家下线
function Team_mgr:outline(obj_id, team_id)
	--print("-------Team_mgr:outline", obj_id, team_id)
	local team_id = self.char_list[obj_id]
	local team_obj = self:get_team_obj(team_id)
	if team_obj ~= nil then
		if team_obj:get_line_count() <= 1 then
			self:del_team(team_id)
			team_obj:remove()
		else
			team_obj:outline(obj_id)
		end
	end
end
--玩家上线
function Team_mgr:online(obj_id, team_id)
	local team_id = self.char_list[obj_id]
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		obj:set_team(team_id)
	end

	local team_obj = self:get_team_obj(team_id)
	if team_obj ~= nil then
		team_obj:online(obj_id)
	else
		self:del_char_id(obj_id)
	end
end

--集合(flag:nil不要道具，非nil 需要道具  type: 1正常集合 2副本集合)
function Team_mgr:gather(obj_id, team_id, flag, type)
	local team_obj = self:get_team_obj(team_id)
	if team_obj == nil or team_obj:get_teamer_id() ~= obj_id then
		return 20106
	else
		if team_obj:get_line_count() > 1 then
			--扣道具
			local obj = g_obj_mgr:get_obj(obj_id)
			local scene_id = obj:get_map_id()
			if flag ~= nil then
				local pack_con = obj:get_pack_con()
				local item = pack_con:get_item_by_item_id(103040000120)
				if not item then
					item = pack_con:get_item_by_item_id(103040000121)
				end

				if not item then
					return 20038
				end

				local param_l = {}
				param_l.team_obj = team_obj
				return pack_con:use_item(obj, item, param_l)
			else
				team_obj:add_gather_flag(obj_id, scene_id, type)
				return 0
			end
		end
	end

	return 20108
end

--保存所有玩家
function Team_mgr:add_char_id(char_id, team_id)
	if char_id ~= nil then
		self.char_list[char_id] = team_id
	end
end
function Team_mgr:del_char_id(char_id)
	if char_id ~= nil then
		self.char_list[char_id] = nil
	end
end


-----------event----------
--开启副本事件
function Team_mgr:on_event_open_copy(args, char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil and obj:get_team() ~= nil then
		if args.map_id == MAP_COPY_INFO_10 then    --幻境之塔
			local team_obj = self:get_team_obj(obj:get_team())
			if team_obj == nil then return end
			 
			--清除神秘商人列表
			for k,_ in pairs(team_obj:get_team_l()) do
				g_random_script:event_del_team({["char_id"]=k}, k)
			end
		end
	end
end


--[[function Team_mgr:get_click_param()
	return self, self.on_timer, 5, nil
end

function Team_mgr:on_timer(tm)
	--print("Team_mgr:on_timer", tm)
	--秒计数
	self.time_count = self.time_count + 1
	if self.time_count >= math.floor(5/tm) then
		self.time_count = 0

		for k,v in pairs(self.team_l) do
			v:on_timer(5)
		end
	end
end]]
