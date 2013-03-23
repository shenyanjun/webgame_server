-- cailizhong
-- 手机绑定礼包

--local bind_reward = {}
--bind_reward[1] = {{104001230140,1}} -- 手机绑定礼包

--local BIND_GIFT_TYPE ={}
--BIND_GIFT_TYPE[1] = "sj"

local lom = require("lom") -- 解析xml需要
module("bind_gift.bind_gift_loader", package.seeall)

local bind_gift_list = {}

-- 判断绑定类型是否存在
function bind_type_isExist(bind_type)
	return bind_gift_list[bind_type]
end

-- 从绑定类型获取绑定类型的名字，用于生成key
function get_bind_name(bind_type)
	return bind_gift_list[bind_type].bind_name
end

-- 从绑定类型获取绑定类型的game，用于生成key
function get_bind_game(bind_type)
	return bind_gift_list[bind_type].bind_game
end

-- 从绑定类型获取绑定类型的奖励列表
function get_reward_list(bind_type)
	return bind_gift_list[bind_type].reward_list or {}
end

-- 从指定路径加载并解析配置文件
local function load_config(path)
	local file_handle, err_msg = io.open(path)
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
		if "bind_gift" == node.tag then
			local bind_type = tonumber(node.attr["bind_type"])
			local bind_name = node.attr["bind_name"]
			local bind_game      = node.attr["bind_game"]
			if bind_type and bind_name and bind_game then
				local item     = {}
				item.bind_type = bind_type
				item.bind_name = bind_name
				item.bind_game = bind_game
				item.reward_list   = {}
				for k, v in pairs(node) do
					if "reward" == v.tag then
						local item_id    = tonumber(v.attr["item_id"])
						local item_count = tonumber(v.attr["item_count"])
						if item_id and item_count then
							local reward      = {}
							reward.item_id    = item_id
							reward.item_count = item_count
							table.insert(item.reward_list, reward) -- 将奖励物品放到对应的绑定礼包上面
						end
					end
				end
				bind_gift_list[bind_type] = item -- 将绑定礼包根据绑定类型放入绑定礼包列表的对应位置
			end
		end
	end
end


-- 启动绑定礼包配置加载
load_config(CONFIG_DIR.."xml/bind_gift/bind_gift.xml")