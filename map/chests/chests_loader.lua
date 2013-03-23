

local _open = require("config.chests_config")
------------------open_Chests_class------------
module("chests.chests_analytical", package.seeall)

chests_sum_value = {}			--每个降妖的总权值
chests_radio_sum_value = {}		--每个降妖广播道具总权值
chests_type_time = 0			--降妖的类型次数
chests_ompensation = {}			--每个降妖的补偿金额
chests_list = {}				--每种降妖的列表

local chests_numerical_init = function()
	for k, v in pairs(_open.open_chests) do
		chests_list[k] = {}
		local i = 1
		chests_sum_value[k] = 0
		chests_radio_sum_value[k] = 0
		for k1, v1 in pairs(v.item_list_not_radio) do
			chests_list[k][i] = v1
			i = i + 1
			chests_sum_value[k] = chests_sum_value[k] + v1[3]
			chests_radio_sum_value[k] = chests_radio_sum_value[k] + v1[3]
		end
		for k1, v1 in pairs(v.item_list_radio) do
			chests_list[k][i] = v1
			i = i + 1
			chests_sum_value[k] = chests_sum_value[k] + v1[3]
		end
		chests_ompensation[k] = 0
		for k1, v1 in pairs(_open.open_chests[1].cost) do
			chests_ompensation[k] = chests_ompensation[k] + v1[2]
		end
		chests_type_time = chests_type_time + 1
	end
end
chests_numerical_init()

--返回指定模块类名字
get_open_chests_param_name = function(k_type)
	local name
	if k_type == 1 then
		name = f_get_string(702)
	elseif k_type == 1 then
		name = f_get_string(703)
	elseif k_type == 3 then
		name = f_get_string(704)
	end
	return name
	--return _open.open_chests[k_type].name
end

--返回指定模块类总的权值
get_open_chests_k_type_sum = function(k_type)
	return chests_sum_value[k_type]
end

--返回物品列表
get_open_chests = function(k_type)
	return chests_list[k_type]
end

--返回指定模块类中非广播道具总权值
get_open_chests_radio_value = function(k_type)
	return chests_radio_sum_value[k_type]
end

--返回指定模块所需要的money
get_open_chests_money = function(k_type, lv)
	return _open.open_chests[k_type].cost[lv][2]
end

--返回指定模块所需要的times
get_open_chests_time = function(k_type, lv)
	return _open.open_chests[k_type].cost[lv][1]
end

--返回有多少种类型的降妖
get_number_chests_type = function()
	return chests_type_time
end

--补偿金额
get_open_chests_ompensation = function(k_type)
	return chests_ompensation[k_type]
end
