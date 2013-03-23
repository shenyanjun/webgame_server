

local _boss = require("config.attr_config")
local _collect = require("config.collect_config")
local _scene = require("config.scene_config")
local database = "gm_reward_function"

module("function.gm_function.refresh_loader",package.seeall)

GmRefreshTable = {}

function load_db()
	--不是正常线，不加载
	if f_is_pvp() or f_is_line_faction() then return end
	GmRefreshTable = {}		--清空
	local dbh = f_get_db()
	local fields = "{function_id:1,refresh_list:1}"
	local query = "{function_id:{$exists:true},refresh_list:{$exists:true}}"
	local row,error = dbh:select(database,fields,query)
	local now = ev.time
	if row and error == 0 then
		for id,list in pairs(row or {}) do
			if id and list and list.refresh_list.end_time and list.refresh_list.start_time and list.refresh_list.end_time > now and _scene._config[list.refresh_list.map_id] then
				GmRefreshTable[list.function_id] = {}
				GmRefreshTable[list.function_id].function_id = list.function_id
				GmRefreshTable[list.function_id].start_time = tonumber(list.refresh_list.start_time)
				GmRefreshTable[list.function_id].end_time = tonumber(list.refresh_list.end_time)
				GmRefreshTable[list.function_id].space_time = math.max(tonumber(list.refresh_list.space_time),300)
				GmRefreshTable[list.function_id].map_id = list.refresh_list.map_id
				GmRefreshTable[list.function_id].map_name = list.refresh_list.map_name or ""
				
				--怪物列表
				GmRefreshTable[list.function_id].monster_list = {}
				local m_count = 1
				for i,v in pairs(list.refresh_list.monster_list or {}) do
					if v[1] and tonumber(v[1]) and _boss.attr[tonumber(v[1])] then
						GmRefreshTable[list.function_id].monster_list[m_count] = {}
						GmRefreshTable[list.function_id].monster_list[m_count].occ  = tonumber(v[1])
						GmRefreshTable[list.function_id].monster_list[m_count].name = tostring(v[2] or "")
						GmRefreshTable[list.function_id].monster_list[m_count].number = math.min(tonumber(v[3]),100)
						GmRefreshTable[list.function_id].monster_list[m_count].effect_id = v[4]
						m_count = m_count+1
					end
				end
			
				--采集列表
				GmRefreshTable[list.function_id].npc_list = {}
				local n_count = 1
				for i,v in pairs(list.refresh_list.npc_list or {}) do
					if v[1] and tonumber(v[1]) and _collect.collect[tonumber(v[1])] then
						GmRefreshTable[list.function_id].npc_list[n_count] = {}
						GmRefreshTable[list.function_id].npc_list[n_count].occ  = tonumber(v[1])
						GmRefreshTable[list.function_id].npc_list[n_count].name = tostring(v[2] or "")
						GmRefreshTable[list.function_id].npc_list[n_count].number = math.min(tonumber(v[3]),100)
						GmRefreshTable[list.function_id].npc_list[n_count].effect_id = v[4]
						n_count = n_count+1
					end					
				end
				--掉落包
				GmRefreshTable[list.function_id].box_list = {}
				local b_count = 1
				for i,v in pairs(list.refresh_list.box_list or {}) do
					if v[1] and tonumber(v[1]) and _boss.attr[tonumber(v[1])] then
						GmRefreshTable[list.function_id].box_list[b_count] = {}
						GmRefreshTable[list.function_id].box_list[b_count].occ  = tonumber(v[1])
						GmRefreshTable[list.function_id].box_list[b_count].name = tostring(v[2] or "")
						GmRefreshTable[list.function_id].box_list[b_count].number = math.min(tonumber(v[3]),100)
						b_count = b_count+1
					end					
				end
				
				--怪区
				GmRefreshTable[list.function_id].position_list = {}
				local count = 1
				for _,v in pairs(list.refresh_list.position_list or {}) do
					local min_pos = {}
					local max_pos = {}
					min_pos.x = math.min(v[1][1],v[2][1])
					min_pos.y = math.min(v[1][2],v[2][2])
					max_pos.x = math.max(v[2][1],v[2][1])
					max_pos.y = math.max(v[1][2],v[2][2])
					if math.abs(max_pos.x-min_pos.x) >= 20 and math.abs(max_pos.y-min_pos.y) >= 20 then
						GmRefreshTable[list.function_id].position_list[count] = {}	
						GmRefreshTable[list.function_id].position_list[count].min_pos = min_pos 
						GmRefreshTable[list.function_id].position_list[count].max_pos = max_pos
						count = count+1
					end		
				end
				
				--刷怪时间
				GmRefreshTable[list.function_id].time_list = list.refresh_list.time_list
			end
		end
	end
end

load_db()
