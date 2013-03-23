
local lom = require("lom")
module("reward.login_reward_l.loader.add_login_loader", package.seeall)

local reward_info = {}
local reward_yellow_info = {}
local max_day = 0
--local sign        = 1

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/login_reward/add_login.xml")
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
		--sign = tonumber(xml_tree.attr["sign"]) or 1 --max_day
		max_day = tonumber(xml_tree.attr["maxday"]) or 7
		for _, attr_tree in pairs(xml_tree) do
			if attr_tree.tag == "day" then
				local day = tonumber(attr_tree.attr["id"])
				if not day then print("not attr_tree.attr[id]") return end
				reward_info[day] = {}
				reward_yellow_info[day] = {}
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
					elseif v.tag == "yellow_append" then		
						reward_yellow_info[day] = {}	
						local app_count = 1			
						for c,d in pairs(v) do
							if d.tag == "item" then
								reward_yellow_info[day][app_count] = {}
								for p,t in pairs(d.attr) do
									if type(p) == "string" then	
										reward_yellow_info[day][app_count][p] = tonumber(t)
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

--function get_sign()
	--return sign
--end

function get_max_day()
	return max_day
end

function get_reward_info()
	return reward_info
end

function get_reward_day_info(day,type)
	if not type then
		return reward_info[day] or {}
	else
		return reward_yellow_info[day] or {}
	end
end

init()
