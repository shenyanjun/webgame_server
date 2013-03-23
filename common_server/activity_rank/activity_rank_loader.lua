local debug_print = print
local lom = require("lom")

module("activity_rank.activity_rank_loader", package.seeall)

if _activity_rank_cfg == nil then
	_activity_rank_cfg = {}
end

_activity_rank_cfg_tmp = {} --热更时 临时表

function get_activity(id)
	return _activity_rank_cfg[id]
end

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/activity/activity_rank.xml")
end

--从XML文件中读取数据
function HandleXmlFile(str_file)
	debug_print("HandleXmlFile str_file=", str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		debug_print("HandleXmlFile can't open the xml file, file name=", str_file)
		assert(nil,'load '..str_file..' error1')
		return
	end
	local file_data = file_handle:read("*a")
	file_handle:close()

	local xml_tree,err = lom.parse(file_data)
	if err then
		debug_print("HandleXmlFile error:",err)
		assert(nil,'load '..str_file..' error2')
		return
	end
	local ret = HandleXmlTree(xml_tree)
end

function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree tree is nil return")
		return 1
	end

	for _, node in pairs(xml_tree) do
		if "rank" == node.tag then
			local rank = Handle_one_rank(node)
			--_activity_rank_cfg[rank.id] = rank
			assert(_activity_rank_cfg_tmp[rank.type] == nil, "type repeat "..rank.type)
			--_activity_rank_cfg[rank.type] = rank
			_activity_rank_cfg_tmp[rank.type] = rank
		end
	end
	--没发生错误 可替换
	_activity_rank_cfg = _activity_rank_cfg_tmp
	_activity_rank_cfg_tmp = nil
end

function Handle_one_rank(node) --加载一个排行活动
	local rank_handle={
		id = tonumber,
		type = tonumber,
		s_year = tonumber,
		s_month = tonumber,
		s_day = tonumber,
		s_hour = tonumber,
		s_minute = tonumber,
		e_year = tonumber,
		e_month = tonumber,
		e_day = tonumber,
		e_hour = tonumber,
		e_minute = tonumber,
		limit = tonumber,
	}
	local reward_handle={
		reward_type = tonumber
	}
	local gift_handle = {
		order = tonumber,
		item_id = tonumber,
		num = tonumber,
		name = tostring
	}
	local stamp_handle = {
		t_id = tonumber,
		t_year = tonumber,
		t_month = tonumber,
		t_day = tonumber,
		t_hour = tonumber,
		t_minute = tonumber
	}
	local _rank ={}
	
	for key, val in pairs(node.attr) do --活动基本信息
		if rank_handle[key] then
			_rank[key] =  rank_handle[key](val)
		end
	end
	
	_rank.start_t = os.time({["year"] = _rank.s_year or 0 , ["month"] = _rank.s_month or 0, ["day"] = _rank.s_day or 0,["hour"] = _rank.s_hour or 0,["min"] = _rank.s_minute or 0})
	_rank.end_t   = os.time({["year"] = _rank.e_year or 0 , ["month"] = _rank.e_month or 0, ["day"] = _rank.e_day or 0,["hour"] = _rank.e_hour or 0,["min"] = _rank.e_minute or 0})
	
	_rank.timestamp_set = {}
	
	for _,reward in pairs(node)do --加载奖励信息
		if reward.tag == 'reward' then
			local rew = {}
			
			for key,val in pairs(reward.attr)do
				if reward_handle[key] then
					rew[key] = reward_handle[key](val)
				end
			end
			
			assert(rew["reward_type"],"missing reward type")
			
			local index = nil
			local gift_set = {}
			local timestamp_set = {}
			for key, info in pairs(reward) do --名次奖励
				if info.tag == "timestamp" then
					local timestamp = {}
					for t_k, t_v in pairs(info.attr) do
						if stamp_handle[t_k] then
							timestamp[t_k] = stamp_handle[t_k](t_v)
						end
					end
					assert(timestamp_set[timestamp.t_id] == nil, 'repeat timestamp t_id:'..timestamp.t_id)
					--print(j_e(timestamp))
					timestamp.start_t = os.time({["year"] = timestamp.t_year or 0 , ["month"] = timestamp.t_month or 0, ["day"] = timestamp.t_day or 0,["hour"] = timestamp.t_hour or 0,["min"] = timestamp.t_minute or 0})
					
					timestamp_set[timestamp.t_id] = timestamp
				elseif info.tag == "gift" then
					local gift = {}
					for g_k, g_v in pairs(info.attr) do
						if gift_handle[g_k] then
							gift[g_k] = gift_handle[g_k](g_v)
						end
					end
					assert(gift_set[gift.order] == nil, 'repeat gift order '..gift.order)
					gift_set[gift.order] = gift
				end
			end
			
			for timestamp_id, timestamp_o in pairs(timestamp_set) do
				timestamp_o.gift_set = gift_set
				timestamp_o.reward_type = rew.reward_type
				assert(_rank.timestamp_set[timestamp_id]==nil, "repeat timestamp_id:"..timestamp_id)
				_rank.timestamp_set[timestamp_id] = timestamp_o
			end
			
		end
	end
	return _rank
end

init()

--print(j_e(_activity_rank_cfg))
