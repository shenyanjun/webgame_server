
local lom = require("lom")
module("yellow_reward.yellow_reward_load", package.seeall)

local new_gift	= {}
local every_gift = {}
local uplv_gift = {}
local max_lv = 8

function init()
	HandleXmlFile(CONFIG_DIR .. "xml/yellow_reward/zone_new_gift.xml")
	HandleXmlFile(CONFIG_DIR .. "xml/yellow_reward/zone_day_gift.xml")
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
			if attr_tree.tag == "item" then
				new_gift[tonumber(attr_tree.attr.id)] = tonumber(attr_tree.attr.sum)
			elseif attr_tree.tag == "normal" then
				for i,v in pairs(attr_tree) do
					if v.tag == "gift" then
						every_gift[tonumber(v.attr.lv)] = {}
						every_gift[tonumber(v.attr.lv)].item_id = {}
						--every_gift[tonumber(v.attr.lv)].item_extra_id = {}
						for c,d in pairs(v) do
							if d.tag == "item" then
								every_gift[tonumber(v.attr.lv)].item_id[tonumber(d.attr.id)] = tonumber(d.attr.sum)
							--elseif d.tag == "item_extra_id" then
								--every_gift[tonumber(v.attr.lv)].item_extra_id[tonumber(d.attr.id)] = tonumber(d.attr.count)
							end
						end
					end
				end
			elseif attr_tree.tag == "year" then
				every_gift.item_extra_id = {}
				every_gift.item_extra_id[tonumber(attr_tree.attr.id)] = tonumber(attr_tree.attr.sum)
			--elseif attr_tree.tag == "levelup" then
				--print("levelup :",j_e(attr_tree))
				--for i,v in pairs(attr_tree) do
					--if v.tag == "item_id" then
						--uplv_gift[tonumber(v.attr.id)] = tonumber(v.attr.count)
					--end
				--end
			end
		end
	end
end

function get_new_gift()	
	return new_gift or {}
end

function get_every_gift(y_lv)
	if y_lv > max_lv then
		y_lv = y_lv - max_lv
	end
	return every_gift[y_lv].item_id or -1
end

function get_max_lv()
	return max_lv
end

--function get_every_extra_gift(y_lv)
	--y_lv = y_lv % 8
	--return every_gift[y_lv].item_extra_id or -1
--end

function get_every_extra_gift()
	return every_gift.item_extra_id or -1
end

init()
