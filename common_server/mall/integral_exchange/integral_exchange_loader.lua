
local lom = require("lom")
local debug_print = print
module("mall.integral_exchange.integral_exchange_loader",package.seeall)

IntegralExchangeTable = {}


function init()
	local file_path = CONFIG_DIR.."xml/mall/integral_exchange.xml"
	HandleXmlFile(file_path)
end


function HandleXmlFile(file_path)
	debug_print("HandleXmlFile str_file=",file_path)
	local filehandle = io.open(file_path)
	if not filehandle then
		debug_print("HandleXmlFile can't open the xml file, file name=",file_path)
		return 
	end
	local file_data = filehandle:read("*a")
	filehandle:close()
	local xml_tree,error =  lom.parse(file_data)
	if error then
		debug_print("HandleXmlFile error:",error)
		return 
	end
	HandleXmlTree(xml_tree)
end


function HandleXmlTree(xml_tree)
	if not xml_tree then
		debug_print("HandleXmlTree is nil return")
		return
	end	
	if xml_tree.tag then
		if xml_tree.tag == "catalog" then
			local t_node = {}
			for k,v in pairs(xml_tree.attr or {}) do
				t_node[k] = tonumber(v)
			end
			t_node.list = {}
			local count = 1
			for i,xml_node in pairs(xml_tree or {}) do
				if xml_node.tag == "exchange" then	
					t_node.list[count] = {}
					for key,value in pairs(xml_node.attr or {}) do
						if key == "id" then
							t_node.list[count][key] = value
						else
							t_node.list[count][key] = tonumber(value)
						end
					end
					count = count+1
				end
			end
			HandleXmlNode(t_node)
		else
			for k,v in pairs(xml_tree or {}) do
				HandleXmlTree(v)
			end
		end
	end
end


function HandleXmlNode(node)
	local number = node.id
	IntegralExchangeTable[number] = {}
	for k,v in pairs(node.list or {}) do
		IntegralExchangeTable[number][k] = {}
		IntegralExchangeTable[number][k].id = v.id
		IntegralExchangeTable[number][k].need_jade = v.need_jade
		IntegralExchangeTable[number][k].exchange_times = v.exchange_times
		IntegralExchangeTable[number][k].need_integral = v.need_integral
		IntegralExchangeTable[number][k].exchange_gift = v.exchange_gift
	end
end


init()