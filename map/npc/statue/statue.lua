
local statue_config = require("config.statue_config")

--[[local statue_id_l = {}
statue_id_l[OCC_WUZHE] = {[0]=10061,[1]=10062}
statue_id_l[OCC_SHUSHI] = {[0]=10063,[1]=10064}
statue_id_l[OCC_JISI] = {[0]=10065,[1]=10066}]]

Statue_mgr = oo.class(nil, "Statue_mgr")

function Statue_mgr:__init()
	self.statue_list = {}      --statue信息
	self.npc_list = {}         --npc_id->statue_id
	self.worship_list = {}     --膜拜次数
	self.autograph_l = {}      --修改签名计时
	self.world_statue_info = nil
end

function Statue_mgr:create_all_statue(data)
	self.statue_list = data.comm_l or {}
	self.worship_list = {}
	self.autograph_l = {}
	self.world_statue_info = data.world_l or {}	--跨服雕像
	for k,v in pairs(data.comm_l or {}) do
		self.worship_list[k] = v[3]
	end
end

function Statue_mgr:show_all_statue()
	--清除之前npc对象
	for k,_ in pairs(self.npc_list) do
		f_npc_leave(k)
	end
	
	--添加新npc对象
	self.npc_list = {}
	for k,v in pairs(self.statue_list) do
		local param = {}
		param.statue_id = k
		param.faction_l = v[4][5]
		param.name = v[4][2]
		param.class = v[4][3]
		param.gender = v[4][4]
		local obj = f_npc_create_enter(NPC_OCC_STATUE, nil, statue_config.pos[k], {MAP_INFO_3,nil}, param)
		self.npc_list[obj:get_id()] = k
		
		local args = {}
		args.type = k		args.char_id = v[4][1]		g_event_mgr:notify_event(EVENT_SET.EVENT_RANKUPDATE, v[4][1], args)
	end

	local count = 8
	--添加跨服npc对象
	for k, v in pairs(self.world_statue_info.members or {}) do
		count = count + 1
		if not statue_config.pos[count] then
			print("Error: not pos, create npc failed!")
			break
		end
		local param = {}
		param.statue_id = 9
		param.faction_l = {}
		param.name = v[1]
		param.class = v[2]
		param.gender = v[3]
		local obj = f_npc_create_enter(NPC_OCC_WORLD_WAR_STATUE, nil, statue_config.pos[count], {MAP_INFO_3, nil}, param)
		self.npc_list[obj:get_id()] = count
	end
end

function Statue_mgr:net_get_statue(obj_id)
	local id = self.npc_list[obj_id]
	if id ~= nil then
		local statue = self.statue_list[id]
		if statue ~= nil then
			local tb = {}
			tb[1] = statue[1]
			tb[2] = statue[2]
			tb[3] = self.worship_list[id]
			tb[4] = obj_id
			tb[5] = statue[5]
			return tb
		end
	end
end

function Statue_mgr:update_worship(statue_id, worship_l)
	self.worship_list[statue_id] = worship_l
end

function Statue_mgr:update_autograph(statue_id, aug)
	if self.statue_list[statue_id] ~= nil then 
		self.statue_list[statue_id][5] = aug
	end
end

function Statue_mgr:get_statue_id(npc_id)
	return self.npc_list[npc_id]
end

--是否可以修改签名
function Statue_mgr:is_autograph(char_id, npc_id)
	local id = self.npc_list[npc_id]
	if id ~= nil then
		local statue = self.statue_list[id]
		if statue ~= nil and char_id == statue[1] then
			if self.autograph_l[char_id] ~= nil and self.autograph_l[char_id] > ev.time-10 then
				return 20874
			end
			
			self.autograph_l[char_id] = ev.time
			return 0
		end
		return 20873
	end 
	return -1
end

--称号接口(返回该玩家雕像列表)
function Statue_mgr:get_obj_statue_list(obj_id)
	local tb = {}
	for k,v in pairs(self.statue_list) do		
		if v[4] and v[4][1] == obj_id then
			tb[k] = 1
		end
	end
	return tb
end

--跨服雕像
function Statue_mgr:get_world_statue()
	return self.world_statue_info and self.world_statue_info.info
end