
local lom = require("lom")
module("mission_ex.mission_loader", package.seeall)

local mission_list = {}

function get_meta(quest_id)
	return mission_list[quest_id]
end
function get_meta_list()
	return mission_list
end


local function build_postcondition(node, result)
	local complete_map = { ["gold"] = true
			, ["gift_gold"] = true
			, ["gift_jade"] = true
			, ["jade"] = true
			, ["item"] = true
		}

	if not result.postcondition then
		result.postcondition = {}
	end
	if "kill_monster" == node.tag then
		local monster_list = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				monster_list[item.id] = item
			end
		end
		result.postcondition.monster_list = monster_list
	elseif "collect_item" == node.tag or "option_collect_item" == node.tag then
		local collect_list = {}
		local monster_list = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				local monster = {}
				monster.id = tonumber(child.attr["monster"])
				monster.probability = tonumber(child.attr["probability"])
				monster.item_id = item.id
				
				collect_list[item.id] = item
				if monster.id then
					monster_list[monster.id] = monster
				end
			end
		end
		
		if "option_collect_item" == node.tag then
			result.postcondition.option_collect_list = {}
			result.postcondition.option_collect_list.item_list = collect_list
			result.postcondition.option_collect_list.monster_list = monster_list
		else
			result.postcondition.collect_list = {}
			result.postcondition.collect_list.item_list = collect_list
			result.postcondition.collect_list.monster_list = monster_list
		end
	elseif "trigger" == node.tag then
		local trigger_list = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				item.map_id = tonumber(child.attr["map_id"])
				item.pos_x = tonumber(child.attr["pos_x"])
				item.pos_y = tonumber(child.attr["pos_y"])
				trigger_list[item.id] = item
			end
		end
		result.postcondition.trigger_list = trigger_list
	elseif "complete_level" == node.tag then
		result.postcondition.complete_level = tonumber(node[1])
	elseif "intensify_item" == node.tag then
		result.postcondition.intensify_item = {}
		result.postcondition.intensify_item.class = tonumber(node.attr["class"]) or 0
		result.postcondition.intensify_item.level = tonumber(node.attr["level"])
	elseif "limit_time" == node.tag then
		result.postcondition.limit_time = tonumber(node[1])
	elseif "option_collect_equi" == node.tag then
		result.postcondition.option_collect_equi = {}
		local collect_equi_list = {}
		for _, child in pairs(node) do
			result.postcondition.option_collect_equi[node.tag] = tonumber(node[1]) 
		end
	elseif "collect_condition" == node.tag then
		result.postcondition.collect_condition = {}
		local collect_condition = {}
		local t_req_class
		for _, child in pairs(node) do
			if child.tag == 'req_class' then
				if not t_req_class then t_req_class = {} end
				table.insert(t_req_class, tonumber(child[1]))
			elseif type(child.tag) == 'string' then
				collect_condition[child.tag] = tonumber(child[1]) 
			end
		end
		collect_condition.req_class = t_req_class
		result.postcondition.collect_condition = collect_condition
	elseif "quick_complete" == node.tag then
		result.postcondition.quick_complete = {}
		for _, child in pairs(node) do
			if complete_map[child.tag] then
				--if child.tag == "jade" then
					--result.postcondition.quick_complete[child.tag] = tonumber(child[1]) 
				--end
				if child.tag == "item" then
					result.postcondition.quick_complete[child.tag] = tonumber(child[1])
				end
			end
		end
	--@total关键词最好换一个不太常用的
	elseif "total" == node.tag then
		result.postcondition[node.tag] = tonumber(node[1])
	elseif "option_kill_monster" == node.tag then
		if result.flag == 17 or result.flag == 18 then   --pvp 九幽任务
			local kill_monster = {}
			kill_monster[result.id] = {}
			for _, child in pairs(node) do
				if child.tag == "item" then
					local t_monster = 0
					for i,v in pairs(child.attr) do
						if i == "id" then
							t_monster = tonumber(v)
							kill_monster[result.id][t_monster] = {}
						end
					end
					for _, v in pairs(child) do
						if v.tag == "option_kill" then
							for c,d in pairs(v.attr) do
								if type(c) == "string" then
									kill_monster[result.id][t_monster][tonumber(d)] = 0
								end
							end
						end
					end
				end
			end		
			result.postcondition.option_kill_monster = kill_monster
		end
	elseif "quest_type" == node.tag then
		result.postcondition.quest_list = {}
		for _, child in pairs(node) do
			if "quest" == child.tag then
				result.postcondition.quest_list[tonumber(child.attr["type"])] = tonumber(child[1])
			end
		end
	elseif "quest_limit_flag" == node.tag then	
		result.postcondition.quest_limit_flag = {}
		for _, child in pairs(node) do
			if "quest" == child.tag then
				result.postcondition.quest_limit_flag[tonumber(child.attr["flag"])] = 1
			end
		end
	elseif "count_scene" == node.tag then
		result.postcondition.count_scene = {}
		for _, child in pairs(node) do
			if "scene" == child.tag then
				result.postcondition.count_scene[tonumber(child.attr["id"])] = tonumber(child[1])
			end
		end
	end
end

local function build_precondition(node, result)
	if not result.precondition then
		result.precondition = {}
	end
	if "pre_quest_chain" == node.tag then
		local quest_list = {}
		for _, child in pairs(node) do
			if "quest" == child.tag then
				table.insert(quest_list, child.attr["id"])
			end
		end
		result.precondition.pre_quest_chain = quest_list
	elseif "src_item" == node.tag then
		local list = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				table.insert(list, item)
			end
		end
		result.precondition.src_item = list
	elseif "target_scene" == node.tag then
		local target_scene = {}
		target_scene.id = tonumber(node.attr["id"])
		target_scene.x = tonumber(node.attr["x"])
		target_scene.y = tonumber(node.attr["y"])
		result.precondition.target_scene = target_scene
	elseif "faction_building" == node.tag then
		local faction_building = {}
		for _, child in pairs(node) do
			if "building" == child.tag then
				local building = {}
				building.id 	= tonumber(child.attr["id"])
				building.lvl 	= tonumber(child[1])
				table.insert(faction_building, building)
			end
		end
		result.precondition.faction_building = faction_building
	elseif "extra" == node.tag then
		local extra = {}
		for _, child in pairs(node) do
			if "limit_time" == child.tag then
				extra.limit_time = tonumber(child[1])
			end
		end
		result.precondition.extra = extra
	elseif "accept_scene" == node.tag then
		result.precondition.accept_scene = tonumber(node.attr["id"]) or 0
	else
		result.precondition[node.tag] = tonumber(node[1])
	end
end

local function build_reward(node, result)
	if not result.reward then
		result.reward = {}
	end
	
	if "next_quest_chain" == node.tag then
		local quest_list = {}
		for _, child in pairs(node) do
			if "quest" == child.tag then
				quest_list[child.attr["id"]] = true
			end
		end
		result.reward.next_quest_chain = quest_list
	elseif "all_reward" == node.tag then
		local all_reward = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				table.insert(all_reward, item)
			end
		end
		result.reward.all_reward = all_reward
	elseif "option_reward" == node.tag then
		local option_reward = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				table.insert(option_reward, item)
			end
		end
		result.reward.option_reward = option_reward
	elseif "occ_reward" == node.tag then
		local occ_reward = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				item.occ = tonumber(child.attr["occ"])
				table.insert(occ_reward, item)
			end
		end
		result.reward.occ_reward = occ_reward
	elseif "faction_reward" == node.tag then
		local faction_reward = {}
		for _,child in pairs(node) do
			if "reward" == child.tag then
				local reward = {}
				reward.type 	= tonumber(child.attr["type"])
				reward.counts 	= tonumber(child[1])
				table.insert(faction_reward, reward)
			end
		end
		result.reward.faction_reward = faction_reward
	elseif "sub_faction_reward" == node.tag then
		local sub_faction_reward = {}
		for _,child in pairs(node) do
			if "reward" == child.tag then
				local reward = {}
				reward.type 	= tonumber(child.attr["type"])
				reward.counts 	= tonumber(child[1])
				table.insert(sub_faction_reward, reward)
			end
		end
		result.reward.sub_faction_reward = sub_faction_reward
	elseif "add_faction_reward" == node.tag then
		local add_faction_reward = {}
		for _,child in pairs(node) do
			if "reward" == child.tag then
				local reward = {}
				reward.type 	= tonumber(child.attr["type"])
				reward.counts 	= tonumber(child[1])
				table.insert(add_faction_reward, reward)
			end
		end
		result.reward.add_faction_reward = add_faction_reward
	elseif "spectral_reward" == node.tag then
		local spectral_reward = {}
		for _,child in pairs(node) do
			if "reward" == child.tag then
				local reward = {}
				reward.type 	= tonumber(child.attr["type"])
				reward.counts 	= tonumber(child[1])
				table.insert(spectral_reward, reward)
			end
		end
		result.reward.spectral_reward = spectral_reward		
	elseif "extra_reward" == node.tag then
		local reward_map = {
			["exp"] = true
			, ["gold"] = true
			, ["gift_gold"] = true
			, ["gift_jade"] = true
			, ["jade"] = true
		}
		local extra_reward = {}
		for _, child in pairs(node) do
			if "item" == child.tag then
				local item_list = extra_reward.item_list
				if not item_list then
					item_list ={}
					extra_reward.item_list = item_list
				end
				local item = {}
				item.id = tonumber(child.attr["id"])
				item.number = tonumber(child[1])
				table.insert(item_list, item)
			elseif reward_map[child.tag] then
				extra_reward[child.tag] = tonumber(child[1])
			end
		end
		result.reward.extra_reward = extra_reward
	else
		result.reward[node.tag] = tonumber(node[1])
	end
end

local function load_quest(node)
	local quest = {}
	quest.id = node.attr["id"]
	quest.name = node.attr["name"]
	quest.give_up = tonumber(node.attr["give_up"])
	
	local reward_map = {
		["exp"] = true
		, ["gold"] = true
		, ["gift_gold"] = true
		, ["gift_jade"] = true
		, ["jade"] = true
		, ["flourish"] = true
		, ["add_flourish"] = true
		, ["sub_flourish"] = true
		, ["all_reward"] = true
		, ["option_reward"] = true
		, ["occ_reward"] = true
		, ["next_quest_chain"] = true
		, ["faction_reward"] = true			--4种帮派奖励
		, ["sub_faction_reward"] = true		--减4种帮派奖励
		, ["extra_reward"] = true
		, ["authorize_reward"] = true
		, ["spectral_reward"] = true				--领地灵力
		, ["add_faction_reward"] = true
		, ["honor"] = true					--加荣誉值
		, ["skill_sp"]	= true
	}
	
	local precondition_map = {
		["req_class"] = true
		, ["min_level"] = true
		, ["max_level"] = true
		, ["src_item"] = true
		, ["pre_quest_chain"] = true
		, ["target_scene"] = true
		, ["faction_building"] = true		--3种建筑
		, ["extra"] = true
		, ["accept_scene"] = true
		, ["ring_lvl"] = true				--婚戒等级
	}
	
	local postcondition_map = {
		["kill_monster"] = true
		, ["collect_item"] = true
		, ["option_collect_item"] = true
		, ["complete_level"] = true
		, ["trigger"] = true
		, ["intensify_item"] = true
		, ["limit_time"] = true
		, ["option_collect_equi"] = true	--装备需求，color、lvl
		, ["quick_complete"] = true			--能否快速完成
		, ["collect_condition"] = true		--分类物品收集
		, ["total"] = true					--战场上缴资源次数 or 战场协助助攻次数 or 战场杀敌个数
		, ["option_kill_monster"] = true    -- 九幽pvp
		, ["quest_type"] = true				-- 引导任务 （完成任务类型的任务）
		, ["quest_limit_flag"] = true		-- 引导任务(限制任务的flag类型)
		, ["count_scene"] = true			-- 场景计数任务（在此场景获得任意东西 计数+1）
	}
	
	for _, child in pairs(node) do
		if "type" == child.tag then
			quest.type = tonumber(child[1])
		elseif "flag" == child.tag then
			quest.flag = tonumber(child[1])
		elseif "give_up" == child.tag then
			quest.give_up = tonumber(child[1])
		elseif "complete_time" == child.tag then
			quest.complete_time = tonumber(child[1])
		elseif "scene_id" == child.tag then
			quest.scene_id = tonumber(child[1])
		elseif reward_map[child.tag] then
			build_reward(child, quest)
		elseif precondition_map[child.tag] then
			build_precondition(child, quest)
		elseif postcondition_map[child.tag] then
			build_postcondition(child, quest)
		end
	end
	
	return quest
end

local function load_xml(path)
	local file_handle = io.open(path)
	if not file_handle then
		f_quest_error_log("Mission_loader.load_config(%s) Load Config Failed!"
			, tostring(path))
		return nil
	end
	
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree, err = lom.parse(file_data)
	if err then
		f_quest_error_log("Mission_loader.load_config(%s) Parse Failed Occur Error: %s!"
			, tostring(path)
			, tostring(err))
		return nil
	end
	
	return xml_tree
end

function load_config(path_array)
	table.foreach(
		path_array
		, function (k, v)
			for _, node in pairs(load_xml(v)) do
				if "Quest" == node.tag then
					local quest = load_quest(node)
					--list[quest.id] = quest
					mission_list[quest.id] = quest
				end
			end
		end)
end


load_config({CONFIG_DIR .. "xml/npc_function/quest.xml", CONFIG_DIR .. "xml/npc_function/quest2.xml",
CONFIG_DIR .. "xml/npc_function/quest3.xml", CONFIG_DIR .. "xml/npc_function/daily_quest.xml"})