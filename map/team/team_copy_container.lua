
--******************组队副本关联类******************

--[[--需要关联的副本
local _copy_l = {}
_copy_l[MAP_COPY_INFO_4] = {["team_list"]={}, ["obj_list"]={}, ["level"]=1,["time"]=ev.time}
_copy_l[MAP_COPY_INFO_6] = {["team_list"]={}, ["obj_list"]={}, ["level"]=5,["time"]=ev.time}
_copy_l[MAP_COPY_INFO_7] = {["team_list"]={}, ["obj_list"]={}, ["level"]=30,["time"]=ev.time}
_copy_l[MAP_COPY_INFO_8] = {["team_list"]={}, ["obj_list"]={}, ["level"]=30,["time"]=ev.time}
_copy_l[MAP_COPY_INFO_9] = {["team_list"]={}, ["obj_list"]={}, ["level"]=30,["time"]=ev.time}]]


local team_config = require("config.team_config")

Team_copy_container = oo.class(nil, "Team_copy_container")

function Team_copy_container:__init()
	--self.list = team_config.copy_l
	self.list = {}
end

function Team_copy_container:add_list(copy_id)
	--增加
	if team_config.copy_l[copy_id] == nil then
		return 10000
	elseif self.list[copy_id] == nil then
		self.list[copy_id] = {["team_list"]={}, ["obj_list"]={},["time"]=ev.time}
	end

	return 0
end

--增加组
function Team_copy_container:add_team(obj_id, copy_id)
	--增加
	local ret = self:add_list(copy_id)
	if ret ~= 0 then return ret end

	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		if obj:get_level() < team_config.copy_l[copy_id]["level"] then
			return 20115
		end

		local team_obj = g_team_mgr:get_team_obj(obj:get_team())
		if team_obj == nil or team_obj:get_teamer_id() ~= obj_id then
			return 20114
		end

		if self.list[copy_id]["team_list"][obj:get_team()] ~= nil then
			return 20116
		end

		self.list[copy_id]["team_list"][obj:get_team()] = self:get_team_info(obj, team_obj)

		--清除其他copy中信息
		for c_id,_ in pairs(self.list) do
			if copy_id ~= c_id then
				self.list[c_id]["team_list"][obj:get_team()] = nil
			end
		end

		return 0
	end
	return 10000
end

--增加玩家
function Team_copy_container:add_obj(obj_id, copy_id)
	--增加
	local ret = self:add_list(copy_id)
	if ret ~= 0 then return ret end

	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then
		if obj:get_level() < team_config.copy_l[copy_id]["level"] then
			return 20115
		end

		if obj:get_team() ~= nil then
			return 20117
		end

		self.list[copy_id]["obj_list"][obj:get_id()] = self:get_obj_info(obj)

		--清除其他copy中信息
		for c_id,_ in pairs(self.list) do
			if copy_id ~= c_id then
				self.list[c_id]["obj_list"][obj_id] = nil
			end
		end

		return 0
	end
	return 10000
end

function Team_copy_container:get_team_info(obj, team_obj)
	local t = {}
	t[1] = obj:get_id()
	t[2] = obj:get_name()
	local _,c = team_obj:get_team_l()
	t[3] = c
	return t
end

function Team_copy_container:get_obj_info(obj)
	local t = {}
	t[1] = obj:get_id()
	t[2] = obj:get_name()
	t[3] = obj:get_level()
	t[4] = obj:get_occ()
	return t
end

function Team_copy_container:is_have_copy(team_id)
	return g_scene_mgr_ex:exists_instance(team_id)
end

function Team_copy_container:update(copy_id)
	local ret = self:add_list(copy_id)
	if ret ~= 0 then return ret end

	if self.list[copy_id]["time"] + 10 >= ev.time then
		return
	end
	self.list[copy_id]["time"] = ev.time

	--组信息
	local copy_l = self.list[copy_id] or {}
	for team_id,info in pairs(copy_l.team_list or {}) do
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if team_obj ~= nil and not self:is_have_copy(team_id) then
			local teamer = team_obj:get_teamer_id()
			local obj = g_obj_mgr:get_obj(teamer)
			if obj ~= nil then
				copy_l.team_list[team_id] = self:get_team_info(obj, team_obj)
			else
				copy_l.team_list[team_id] = nil
			end
		else
			copy_l.team_list[team_id] = nil
		end
	end

	--玩家信息
	for obj_id,info in pairs(copy_l.obj_list or {}) do
		local obj = g_obj_mgr:get_obj(obj_id)
		if obj == nil or obj:get_team() ~= nil then
			copy_l.obj_list[obj_id] = nil
		end
	end
end

--********************net***********************
function Team_copy_container:net_get_list(copy_id)
	self:update(copy_id)

	local new_pkt = {}
	new_pkt.copy_id = copy_id
	new_pkt.team_l = {}
	new_pkt.obj_l = {}
	local copy_l = self.list[copy_id] or {}

	local count = 0
	for _,info in pairs(copy_l.team_list or {}) do
		count = count + 1
		new_pkt.team_l[count] = info
	end

	count = 0
	for _,info in pairs(copy_l.obj_list or {}) do
		count = count + 1
		new_pkt.obj_l[count] = info
	end

	return new_pkt
end