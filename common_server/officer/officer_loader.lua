
local lom = require("lom")
module("officer.officer_loader", package.seeall)

officer_config = {}						--官职列表(ID为索引)
string_list_1 = {}
string_list_1[1] = 2719
string_list_1[2] = 2730
string_list_1[3] = 2713
string_list_1[4] = 2714
string_list_1[5] = 2723

string_list_2 = {}
string_list_2[1] = 2724
string_list_2[2] = 2725
string_list_2[3] = 2726
string_list_2[4] = 2727
string_list_2[5] = 2728


END_TIME = {}
START_TIME = {}

local function build_reach_list(root, result)
	if not result.reach_list then
		result.reach_list = {}
	end

	for _, node in pairs(root) do
		if "honour" == node.tag then
			result.reach_list.honour = tonumber(node[1]) or 0
		elseif "win" == node.tag then
			result.reach_list.win    = tonumber(node[1]) or 0
		elseif "kill" == node.tag then
			result.reach_list.kill   = tonumber(node[1]) or 0
		end
	end
end

local function build_additional_list(node, result)
	if not result.additional_list then
		result.additional_list = {}
	end

	for _, child in pairs(node) do
		if child.tag then
			result.additional_list[child.tag] = tonumber(child[1]) or 0
		end
	end
end

local function load_officer(node)
	local officer = {}
	officer.id = tonumber(node.attr["id"])
	officer.type = tonumber(node.attr["type"])
	officer.time = tonumber(node.attr["time"])
	officer.s_week = tonumber(node.attr["s_week"])
	officer.s_time = tonumber(node.attr["s_time"])
	officer.s_min = tonumber(node.attr["s_min"])
	officer.e_week = tonumber(node.attr["e_week"])
	officer.e_time = tonumber(node.attr["e_time"])
	officer.e_min = tonumber(node.attr["e_min"])
	officer.len = tonumber(node.attr["len"])
	officer.cnt1 = tonumber(node.attr["cnt1"])
	officer.cnt2 = tonumber(node.attr["cnt2"])
	officer.cnt3 = tonumber(node.attr["cnt3"])
	officer.cnt4 = tonumber(node.attr["cnt4"])
	officer.cnt5 = tonumber(node.attr["cnt5"])
	officer.max  = tonumber(node.attr["max"])
	officer.show  = tonumber(node.attr["show"])
	officer.officer_list = {}

	local max_level = 0
	for _, root in pairs(node) do
		if "Officer" == root.tag then
			local level = tonumber(root.attr["level"])
			local list = {}
			list.level = level
			list.name = root.attr["name"]
			list.officer_li = tonumber(root.attr["officer_li"])
			list.exp_1 = tonumber(root.attr["exp_1"])
			list.exp_2 = tonumber(root.attr["exp_2"])
			list.exp_3 = tonumber(root.attr["exp_3"])
			list.exp_4 = tonumber(root.attr["exp_4"])
			list.exp_5 = tonumber(root.attr["exp_5"])
			list.exp_6 = tonumber(root.attr["exp_6"])
			list.exp_7 = tonumber(root.attr["exp_7"])
			for _, child in pairs(root) do
				if "reach_list" == child.tag then
					 build_reach_list(child, list)
				elseif "additional_list" == child.tag then
					build_additional_list(child, list)
				end
			end
			officer.officer_list[level] = list
		end
	end
	return officer
end

local function load_config(path)
	local file_handle,err_msg = io.open(path)
	if not file_handle then
		print(err_msg)
		return nil
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		print(err)
		return nil
	end
	
	for _, node in pairs(xml_tree) do
		if "Officer_list" == node.tag then
			local officer = load_officer(node)
			local id = officer.id
			officer_config[id] = officer
		end
	end
end

function laod_officer_info()
	return officer_config
end

function is_can_officer(id, time)
	local st_tm, en_tm = get_start_time(id)
	if time < st_tm or time > en_tm then
		return 0
	elseif time >= en_tm - 15*60 then
		return 2
	elseif time >= st_tm then
		return 1
	end
	return 0
end

function is_close_officer(id,time)
	local st_tm, en_tm = get_start_time(id)
	if time < st_tm or time > en_tm then
		return true
	end
	return false, en_tm
end

function is_open_officer(id,time)
	local st_tm, en_tm = get_start_time(id)
	if time >= st_tm and time < en_tm then
		return true
	end
	return false
end

--这个时间要入库，防止周日关服//设置开始标识位即可
function set_start_time()
	local config = officer_config
	for i = 1, MAX_OFFICER_COUNT do
		local wday = (config[i].s_week) % 7
		local hour = config[i].s_time
		local min = config[i].s_min
		local end_wday = (config[i].e_week) % 7
		local end_hour = config[i].e_time
		local end_min = config[i].e_min
		--print("time==id===", i, wday, hour, min, end_wday, end_hour, end_min)
		START_TIME[i], END_TIME[i] = f_get_monday_before(wday, hour, min, end_wday, end_hour, end_min)
		--print("START_TIME[i]", os.date("%Y.%m.%d %H:%M:%S", START_TIME[i]))
		--print("END_TIME[i]", os.date("%Y.%m.%d %H:%M:%S", END_TIME[i]))
	end
	return START_TIME, END_TIME
end

function get_start_time(id)
	return START_TIME[id], END_TIME[id]
end

function get_officer_des(type)
	return f_get_string(string_list_1[type]) or f_get_string(2715) 
end

function get_officer_info(type)
	return f_get_string(string_list_2[type]) or f_get_string(2729) 
end

function get_eweek(id)
	return officer_config[id].e_week
end

function get_etime(id)
	return officer_config[id].e_time*3600
end

function get_officer_time(id)
	return officer_config[id].time
end

function get_officer_name(id)
	return officer_config[id].officer_list[1].name
end

function get_officer_count(id)
	return officer_config[id].max
end

function get_officer_show(id)
	return officer_config[id].show
end

function is_equal_eweek(time,id)
	local day = os.date("%w",time)
	day = tonumber(day)
	if day == 0 then
		day = 7
	end
	if day == get_eweek(id) then 
		return true
	end
	return false
end

function is_than_etime(time,id)
	local time = os.date("*t", time)
	local hour = time.hour
	local min  = time.min
	local sec  = time.sec	
	if (hour*3600 + min*60+sec) >= get_etime(id) then
		return true
	end
	return false
end

load_config(CONFIG_DIR .. "xml/officer/officer.xml")

