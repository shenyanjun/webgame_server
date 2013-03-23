
local lom = require("lom")
module("reward.login_reward_l.loader.sign_in_loader", package.seeall)

local reward_info = {}
local vip_reward_info = {}
local condition = {}

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/login_reward/sign_in.xml")
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
			if attr_tree.tag == "day" then
				local day = tonumber(attr_tree.attr["id"])
				if not day then print("not attr_tree.attr[id]") return end
				condition[day] = tonumber(attr_tree.attr["condition"]) or 100
				reward_info[day] = {}
				vip_reward_info[day] = {}
				for i,v in pairs(attr_tree) do	
					if v.tag == "reward" then		
						reward_info[day] = {}
						local count = 1		
						for c,d in pairs(v) do
							if d.tag == "item" then
								reward_info[day][count] = {}
								for p,t in pairs(d.attr) do
									if type(p) == "string" then	
										reward_info[day][count][p] = tonumber(t)
									end
								end
								count = count + 1
							end
						end	
					elseif v.tag == "vip_reward" then		
						vip_reward_info[day] = {}	
						local app_count = 1			
						for c,d in pairs(v) do
							if d.tag == "item" then
								vip_reward_info[day][app_count] = {}
								for p,t in pairs(d.attr) do
									if type(p) == "string" then	
										vip_reward_info[day][app_count][p] = tonumber(t)
									end
								end
								app_count = app_count + 1
							end
						end
					end			
				end
			end
		end
	end

end

function get_condition(day)
	return condition[day] or 10000
end

function get_reward_day_info(type, day)
	if type == 1 then
		return reward_info[day]
	elseif type == 2 then
		return vip_reward_info[day]
	end
end

function print_info_test()
	print ("======print reward_info=====")
	print (j_e(reward_info))
	for k,v in pairs(reward_info) do
		print(k,v)
	end
	print ("======end=====\n")

	print ("======print vip_reward_info=====")
	for k,v in pairs(vip_reward_info) do
		print (k,v)
	end
	print ("======end=====\n")

	print ("======print condition=====")
	for k,v in pairs(condition) do
		print (k,v)
	end
	print ("=====end=====")
end

init()
