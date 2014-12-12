local debug_print = function() end
--local debug_print = print

local npc_loader = require("npc.config.npc_loader")
local scene_loader = require("npc.config.scene_loader")


ACTION_TYPE_TRADE_ITEM		= 1 --买卖物品
ACTION_TYPE_LEARN_SKILL 	= 2
ACTION_TYPE_CHANGE_MAP 		= 3
ACTION_TYPE_AUCTION			= 4
ACTION_TYPE_WAREHOUSE		= 5
ACTION_TYPE_ENHANCE			= 6 --强化
ACTION_TYPE_DRILL			= 7 --打孔
ACTION_TYPE_ENCHASE			= 8 --
ACTION_TYPE_STRIP			= 9 --
ACTION_TYPE_FACTION			= 10

ACTION_TYPE_CYCLE_QUEST		= 12
ACTION_TYPE_GATHER			= 14
ACTION_TYPE_EXCHANGE		= 15
ACTION_TYPE_NPC_DESC		= 16
ACTION_TYPE_NPC_MOTION		= 17

ACTION_TYPE_MERGE_GEM	    = 19 --宝石合成
ACTION_TYPE_PVP_LINE	    = 22 --斗法修仙大会报名

ACTION_TYPE_REWARD          = 26 --每日奖励

ACTION_FACTION_TERRITORY    = 41 --帮派领地
ACTION_TYPE_CHANGE_MAP_TOLL = 42 --帮派领地温泉/练功房
ACTION_TYPE_TERRITORY_COPY_OCCUPY = 43 --帮派领地争夺战
ACTION_TYPE_TERRITORY_BATTLE = 45 --帮派领地攻防战
ACTION_TYPE_STUDY_SKILL_NO_OCC = 53  --帮派领地NPC学习技能

--一键传送(天盾令)传送类型
MapCarryType =
{
	CARRY_NONE = 0,
	CARRY_POINT = 1,
	CARRY_NPC = 2,
	CARRY_STRIP = 3,
}


--NpcContainerMgr = {}
Npc_container_mgr = oo.class(nil, "Npc_container_mgr")

function Npc_container_mgr:__init()
	--self.npc_table = {}
	self.contact_player = {}
	self.player_action = {}
	self.scene_quest_list = {}

	for map_id, info in pairs(scene_loader.SceneTable) do
		if info.npc_list then
			local has_quest_list = {}
			for _, npc in pairs(info.npc_list) do
				local has_quest = false
				local quest_list = {}
				quest_list.end_list = {}
				quest_list.start_list = {}
				local npc_obj = self:GetNpc(npc.id)
				
				for _, quest in pairs(npc_obj.end_quest_list) do
					quest_list.end_list[quest.id] = true
					has_quest = true
				end
				
				for _, quest in pairs(npc_obj.start_quest_list) do
					quest_list.start_list[quest.id] = true
					has_quest = true
				end
				
				if has_quest then
					has_quest_list[npc.id] = {}
					--has_quest_list[npc.id].npc = npc
					has_quest_list[npc.id].quest_list = quest_list
				end
			end
			self.scene_quest_list[map_id] = has_quest_list
		end
	end

	----仙机童子和老头
	if not self.scene_quest_list[2901000] then
		self.scene_quest_list[2901000] = {}
	end
	self.scene_quest_list[2901000][3000050611] = {}
	self.scene_quest_list[2901000][3000050613] = {}
	--产生npc实例
end

--产生NPC实例
function Npc_container_mgr:GetNpc(npc_id)
	--[[if not self.npc_table[npc_id] then
		if npc_loader.NpcTable[npc_id] then
			self.npc_table[npc_id] = npc_loader.NpcTable[npc_id]()
		end
	end
	
	return self.npc_table[npc_id] ]]

	return npc_loader.NpcTable[npc_id]
end

function Npc_container_mgr:SetPlayerAction(char_id, action_id)
	self.player_action[char_id] = self.player_action[char_id] or {}
	self.player_action[char_id] = action_id
end

function Npc_container_mgr:GetPlayerAction(char_id)
	local action_id = self.player_action[char_id]
	local npc = self:GetContactNpcWithPlayer(char_id)
	if not npc then return end

	return npc:GetActionById(action_id)
end

--设置与玩家相联系的NPC
function Npc_container_mgr:SetContactPlayer(char_id, npc_id)
	self.contact_player[char_id] = self.contact_player[char_id] or {}
	self.contact_player[char_id] = npc_id
end

--获取与玩家关联的NPC
function Npc_container_mgr:GetContactNpcWithPlayer(char_id)
	local npc_id = self.contact_player[char_id]
	local npc = self:GetNpc(npc_id)
	return npc
end


--获取场景中的NPC状态
function Npc_container_mgr:GetMapNpcStatus(char_id, avail_l)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	local mission_con = player:get_mission_mgr()
	if not mission_con then return end
	local map_id = player:get_map_id()

	if not self.scene_quest_list[map_id] then
		return
	end

	local ret = {}
	for npc_id, info in pairs(self.scene_quest_list[map_id]) do
		local npc_o = scene_loader.get_scene_info(map_id, npc_id)
		local color = 1
		if npc_o ~= nil then
			color = npc_o.color or 1
		end

		local e_code, item
		if Special_npc[npc_id] then
			local fun = Special_npc[npc_id]
			e_code, item = pcall(fun, player, npc_id, color)
		else
			item = {}
			item[1] = npc_id
			item[2] = MISSION_STATUS_NONE
			item[3] = color      --info.npc.color or 1
			for quest_id, _ in pairs(info.quest_list.end_list) do
				local mission_obj = mission_con:get_accept_mission(quest_id)
				if mission_obj then
					local status = mission_obj:get_status()
					item[2] = status
					if MISSION_STATUS_COMMIT == status then
						break
					end
				end
			end
			
			if MISSION_STATUS_COMMIT ~= item[2] then
				for quest_id, _ in pairs(info.quest_list.start_list) do
					if avail_l[quest_id] then
						item[2] = MISSION_STATUS_AVAILABLE
						break
					end
				end
			end
		end
		if item then
			table.insert(ret, item)
		end
	end
	
	g_cltsock_mgr:send_client(char_id, CMD_NPC_GIVER_STATUS_NOTIFY_S, ret)
end

function Npc_container_mgr:SendError(char_id, err_code, cmd)
	local pkt = {}
	pkt.result = err_code
	if not cmd then 
		cmd = CMD_NPC_ERROR 
	end
	g_cltsock_mgr:send_client(char_id, cmd, pkt)
end

--特殊NPC_ID的处理方法
Special_npc = {}

--仙机童子
Special_npc[3000050611] = 
function(player, npc_id, color)
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local scene_obj = player:get_scene_obj()
	local manor_owner_id = scene_obj.get_manor_owner and scene_obj:get_manor_owner()
	
	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	if not faction_obj then
		return 
	end
	local f_id = faction_obj:get_faction_id()

	local t_pkt = {}
	t_pkt[1] = npc_id
	t_pkt[2] = MISSION_STATUS_NONE
	t_pkt[3] = color

	if manor_owner_id == f_id then
		local finca_mission = mission_con:get_param(PARAM_TYPE_FINCA)
		local mission_obj = finca_mission and mission_con:get_accept_mission(finca_mission.quest_id)
		if mission_obj then
			local status = mission_obj:get_status()
			t_pkt[2] = status
		end

		if MISSION_STATUS_COMMIT ~= t_pkt[2] then
			if player:get_level() >= 41 then
				if not finca_mission or finca_mission.count < 5 then
					t_pkt[2] = MISSION_STATUS_AVAILABLE	
				end
			end
		end
	end
	return t_pkt
end

--仙机老头
Special_npc[3000050613] = 
function(player, npc_id, color)
	local mission_con = player:get_mission_mgr()
	if not mission_con then return end

	local finca_mission = mission_con:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then return end

	local scene_obj = player:get_scene_obj()
	local manor_owner_id = scene_obj.get_manor_owner and scene_obj:get_manor_owner()
	
	local faction_obj = g_faction_mgr:get_faction_by_cid(player:get_id())
	if not faction_obj then
		return 
	end
	local t_pkt = {}
	t_pkt[1] = npc_id
	t_pkt[2] = MISSION_STATUS_NONE
	t_pkt[3] = color

	local f_id = faction_obj:get_faction_id()
	if manor_owner_id ~= f_id then
		t_pkt[2] = mission_con:get_sns_mission_status(player, manor_owner_id)
	end
	return t_pkt
end

