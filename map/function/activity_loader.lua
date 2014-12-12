
--每日活动配置文件
local lom = require("lom")
module("function.activity_loader", package.seeall)

ACT_LV_UP	 = 1
ACT_MK_MONEY = 2
ACT_UP_AB	 = 3
ACT_DAREN	 = 4

local activity = {}    --每日必做
local act_map = {}     --每日必做 副本id
local act_scene = {}   --每日必做 场景id
local act_monster = {} -- 每日必做 杀怪 id
local act_reward = {}  --每日必做 奖励
local act_sign = 0

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/activity/activity.xml")
end

--从XML文件中读取数据
function HandleXmlFile(str_file)
	local file_handle = io.open(str_file)
	if not file_handle then
		print("HandleXmlFile can't open the xml file, file name=", str_file)
		return 
	end
	local file_data = file_handle:read("*a")
	file_handle:close()
	
	local xml_tree,err = lom.parse(file_data)
	if err then
		print("HandleXmlFile error:",err)
		return 
	end
	local ret = HandleXmlTree(xml_tree)
end

--XML数据结构分析
function HandleXmlTree(xml_tree)
	if not xml_tree then
			print("HandleXmlTree tree is nil return")
		return
	end
	if xml_tree.tag and xml_tree.tag == "config" then
		for _, attr_tree in pairs(xml_tree) do
			if attr_tree.tag == "act_lv" then
				local lv = tonumber(attr_tree.attr.minlv)
				if not lv then print("attr_tree.minlv is nil") end
				activity[lv] = {}
				act_reward[lv] ={}
				for i,v in pairs(attr_tree) do
					if v.tag == "act_type" then
						local act_type = tonumber(v.attr.type)
						activity[lv][act_type] = {}
						act_reward[lv][act_type] ={}
						for c,d in pairs(v) do
							if d.tag == "task" then
								--activity[lv][act_type][d.attr.id] = {}
								for p,t in pairs(d.attr) do
									if type(p) == "string" then
										activity[lv][act_type][d.attr.id] = tonumber(d.attr.count)
									end
								end
							elseif d.tag == "reward" then
								--act_reward[lv][act_type][d.attr.id] = {}
								for p,t in pairs(d.attr) do
									if type(p) == "string" then
										act_reward[lv][act_type][d.attr.id] = tonumber(d.attr.count)
									end
								end
							end
						end
					end
				end
			elseif attr_tree.tag == "act_map" then
				for i,v in pairs(attr_tree) do
					if v.tag == "map_id" then
						for c,d in pairs(v.attr) do
							act_map[tonumber(v.attr.mapid)] = v.attr.id
						end
					end
				end  
			elseif attr_tree.tag == "act_scene" then  
				for i,v in pairs(attr_tree) do
					if v.tag == "map_id" then
						for c,d in pairs(v.attr) do
							act_scene[tonumber(v.attr.mapid)] = v.attr.id
						end
					end
				end  	
			elseif attr_tree.tag == "act_monster" then
				for i,v in pairs(attr_tree) do
					if v.tag == "monster_id" then
						for c,d in pairs(v.attr) do
							act_monster[tonumber(v.attr.monster)] = tonumber(v.attr.id)
						end
					end
				end
			elseif attr_tree.tag == "sign" then
				act_sign = tonumber(attr_tree.attr.id)
			end
		end
	end
end

--获得每日内容等级
function get_currer_lv(lv)
	local temp = 0
	for i,v in pairs(activity) do
		if lv >= tonumber(i) and tonumber(i) > temp then
			temp = i
		end
	end
	return tonumber(temp)
end

--获得每日内容
function get_currer_activity(type,lv)
	if not type or not lv  then return end
	return activity[lv] and activity[lv][type] or {}
end

--限制进入场景次数
function get_act_sceneid(scene_id)
	if act_scene[scene_id] then
		return act_scene[scene_id]
	end
	return 0
end

--限制进入副本次数
function get_act_mapid(mapid)
	if act_map[mapid] then
		return act_map[mapid]
	end
	return 0
end

--限制杀怪次数
function get_act_monsteid(monsterid)
	if act_monster[monsterid] then
		return act_monster[monsterid]
	end
	return 0
end

function get_sign()
	return act_sign
end

--获取奖励物品
function get_reward(type,lv)
	if not type or not lv  then return end
	return act_reward[lv][type] or {}	
end

--启动物品加载
init()