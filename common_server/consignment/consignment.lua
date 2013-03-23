
-----------------------------------寄售行-----------------------------
require("consignment.index_table")


local update_time = 3600 * 0.5
local THIRTY_MINUTE = 30*60
local limit = 5

--属于table_type    装备，宝石等字段属于sub_type
local LVL = {10,20,30,40,50,60,70,80,90,100}
local OCC = {11,41,51}
local COL = {1,2,3,4,5}


Consignment = oo.class(nil, "Consignment")


function Consignment:__init()
	self.total 				= {}
	self.total.counts		= 0
	self.total.list 		= {}

	--物品名索引表
	self.name_l				= {}

	self.owner				= {}

	self.gold				= Lower_table()

	self.jade				= Lower_table()

	self.index				= Index_table()

	self.LVL				= {}
	for k , v in pairs(LVL) do
		self.LVL[v] = Index_table()
	end 

	self.OCC				= {}
	for k , v in pairs(OCC) do
		self.OCC[v] = Index_table()
	end

	self.COL				= {}
	for k , v in pairs(COL) do
		self.COL[v] = Index_table()
	end

	self.LVL_OCC			= {}
	for k , v in pairs(LVL) do
		self.LVL_OCC[v] = {}
		for k1 , v1 in pairs(OCC) do
			self.LVL_OCC[v][v1] = Index_table()
		end
	end

	self.LVL_COL			= {}
	for k , v in pairs(LVL) do
		self.LVL_COL[v] = {}
		for k1 , v1 in pairs(COL) do
			self.LVL_COL[v][v1] = Index_table()
		end
	end

	self.OCC_COL			= {}
	for k , v in pairs(OCC) do
		self.OCC_COL[v] = {}
		for k1 , v1 in pairs(COL) do
			self.OCC_COL[v][v1] = Index_table()
		end
	end

	self.LVL_OCC_COL		= {}
	for k , v in pairs(LVL) do
		self.LVL_OCC_COL[v] = {}
		for k1 , v1 in pairs(OCC) do
			self.LVL_OCC_COL[v][v1] = {}
			for k2, v2 in pairs(COL) do
				self.LVL_OCC_COL[v][v1][v2] =Index_table()
			end
		end
	end

	self.update_time = ev.time + update_time

	self.record = {}

	self:load()
end

function Consignment:get_click_param()
	return self, self.on_timer,3,nil
end

function Consignment:on_timer()
	if ev.time > self.update_time then
		local list = self.total.list
		if list ~= nil then 
			local del_list = {}
			local flags =false
			for k,v in pairs(list) do
				if v:is_expiredtime() then
					flags = true
					table.insert(del_list,k)
				end
			end
			if flags then
				self:delete_expired_consignment(del_list)
			end
		end
		self.update_time = self.update_time + update_time
	end
end

-------------------------------------加入寄售
function Consignment:check_consignment(char_id)
	local consignment_count = 0
	if self.owner[char_id] then
		for k , v in pairs(self.owner[char_id]) do
			consignment_count = consignment_count + 1
		end
	end
	return consignment_count
end

function Consignment:create_consignment(node, allows, char_id)
	local count = self:check_consignment(char_id)
	if count >= allows then
		self:add_compensate_consignment_notice(node)
		return nil
	end 
	local consignment_goods = Consignment_goods(node)
	if consignment_goods == nil then return end
	if self:add_consignment(consignment_goods) then
		return self:get_owner_id_consignment(node.owner_id)
	end
	return nil
end

function Consignment:add_consignment(consignment_goods)
	if consignment_goods ~= nil then
		if Consignment_db:SaleConsignment(consignment_goods) == true then
			if consignment_goods.uuid then
				self:insert_consignment(consignment_goods)
				local str 
				if not consignment_goods.item_DB then
					str = string.format(
						"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = 0,create_time =%d,money = %d,money_type= %d",
							consignment_goods.owner_id,
							consignment_goods.item_id,
							consignment_goods.count,
							ev.time,
							consignment_goods.money_count,
							consignment_goods.money_type)
				else
					str = string.format(
						"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = 0,create_time =%d,money = %d,money_type= %d,remark = '%s'",
							consignment_goods.owner_id,
							consignment_goods.item_id,
							consignment_goods.count,
							ev.time,
							consignment_goods.money_count,
							consignment_goods.money_type,
							Json.Encode(consignment_goods.item_DB))
				end
				g_web_sql:write(str) 
				return true
			end
		end
	end
	return false
end

function Consignment:insert_consignment(consignment_goods)
	if not consignment_goods or not consignment_goods.uuid then
		return
	end

	local sub_type 
	local node = {}
	local pkt = {}
	local item_name

	if consignment_goods.item_id == -2 then			--元宝
		sub_type = self:fliter_sub_type(consignment_goods.item_id)
		item_name = '-2'
	elseif consignment_goods.item_id == -1 then		--铜币
		sub_type = self:fliter_sub_type(consignment_goods.item_id)
		item_name = '-1'
	elseif consignment_goods.item_id > 0 then		--物品
		local e_code , item = Item_factory.create(consignment_goods.item_id)
		if e_code ~= 0 then
			return
		end
		local lvl = item:get_item_lvl() or item:get_req_lvl()
		node.lvl = self:filter_LVL(lvl)
		node.col = item:get_color()
		node.occ = self:filter_OCC(item:get_req_class())
		
		sub_type = self:fliter_sub_type(consignment_goods.item_id, item)
		item_name = item:get_name()
	end
	pkt = self:maintain_get_table_type(node)
	for k , v in pairs(pkt) do
		v:add_type_index(sub_type,consignment_goods.uuid)
	end
	self.index:add_type_index(sub_type, consignment_goods.uuid)
	self:add_name_l(item_name, consignment_goods.uuid)

	self.total.counts = self.total.counts + 1
	self.total.list[consignment_goods.uuid] = consignment_goods
	self.owner[consignment_goods.owner_id] = self.owner[consignment_goods.owner_id] or {}
	table.insert(self.owner[consignment_goods.owner_id],consignment_goods.uuid)

	return
end

----------------------------------------------维护-------------
function Consignment:add_name_l(name, uuid)
	if not self.name_l[name] then
		self.name_l[name] = Lower_table()
		self.name_l[name]:add_uuid(uuid)
	else
		self.name_l[name]:add_uuid(uuid)
	end
end

function Consignment:sub_name_l(name, uuid)
	if not self.name_l[name] then
		return
	else
		self.name_l[name]:dec_uuid(uuid)
	end
end

function Consignment:filter_LVL(lvl)
	if not lvl then
		return nil
	end
	for i = 1, table.getn(LVL), 1 do
		if lvl <= LVL[i] then
			return LVL[i]
		end
	end
end

function Consignment:filter_OCC(occ)
	for k ,v in pairs(OCC) do
		if occ == v then
			return occ
		end
	end
	return nil
end

--用于维护表结构,返回涉及的表 node包括 .lvl .occ .col 
function Consignment:maintain_get_table_type(node)
	local pkt = {}
	if node.lvl then
		table.insert(pkt,self.LVL[node.lvl])
		if node.occ then
			table.insert(pkt,self.LVL_OCC[node.lvl][node.occ])
			if node.col then
				table.insert(pkt,self.LVL_OCC_COL[node.lvl][node.occ][node.col])
			end
		end
		if node.col then
			 table.insert(pkt,self.LVL_COL[node.lvl][node.col])
		end
	end
	if node.occ then
		table.insert(pkt,self.OCC[node.occ])
		if node.col then
			table.insert(pkt,self.OCC_COL[node.occ][node.col])
		end
	end
	if node.col then
		table.insert(pkt,self.COL[node.col])
	end

	return pkt
end


--按条件搜索对应的小表，
function Consignment:search_table_uuid(node)
	if node then
		if node.lvl then
			if node.occ then
				if node.col then
					return self.LVL_OCC_COL[node.lvl][node.occ][node.col]
				else 
					return self.LVL_OCC[node.lvl][node.occ]
				end
			elseif node.col then
				return self.LVL_COL[node.lvl][node.col]
			else
				return self.LVL[node.lvl]
			end
		elseif node.occ then
			if node.col then
				return self.OCC_COL[node.occ][node.col]
			else
				return self.OCC[node.occ]
			end
		elseif node.col then
			return self.COL[node.col]
		else
			return self.index
		end
	else
		return self.index
	end
end

--按分类sub_type,用于搜索和维护
function Consignment:fliter_sub_type(item_id,item)
	if item_id then
		if item_id == -1 then
			return 'gold'
		elseif item_id == -2 then
			return 'jade'
		elseif  item_id > 0 and item then
			local m_class = item:get_m_class()
			local s_class = item:get_s_class()
			if m_class == 5 and s_class == 1 then
				return 'weapon'
			elseif m_class == 5 and (s_class == 3 or s_class == 4 or s_class == 5 or s_class == 6 or s_class == 7) then
				return 'armor'
			elseif m_class == 5 and (s_class == 2 or s_class == 8 or s_class == 9 or s_class == 10 or s_class == 12) then
				return 'ornament'
			elseif m_class == 6 then
				return 'gem'
			elseif m_class == 1 and (s_class == 8 or s_class == 9 or s_class == 13) then
				return 'pet'
			elseif m_class == 9 and s_class == 1 then
				return 'pet'
			else
				return 'others'
			end
		end
	end
end

---------------------按条件获取列表
function Consignment:get_list(node)
	--print("node = ",j_e(node))
	local pages 	= node.pages or 1
	local pagesize 	= node.pagesize or 5
	local pkt 		= {}
	pkt.pages 			= pages
	pkt.pagesize		= pagesize
	pkt.timestamp		= node.timestamp or ev.time + 60
	pkt.consignment_list = {}

	local uuid_table = {}  --存储找到的uuid表
	local type = node.condition_list.sub_type
	if not type and not node.condition_list.name then
		return
	else 
		if node.condition_list.name then
			if not self.name_l[node.condition_list.name] then
				pkt.count = 0
				return pkt
			else
				uuid_table = self.name_l[node.condition_list.name]:get_pages_pagesize_uuid(pages, pagesize)
				pkt.count = self.name_l[node.condition_list.name]:get_count()
			end
		else
			local table_type = node.condition_list.type_table
			local item_table = self:search_table_uuid(table_type)
			if not item_table then return end
			uuid_table = item_table:get_pages_pagesize_table_uuid(type, pages, pagesize)
			pkt.count = item_table:get_index_table_count(type)
		end
	end

	for k,v in pairs(uuid_table) do
		local con_copy = self.total.list[v]
		if con_copy then
			table.insert(pkt.consignment_list,con_copy:spec_serialize_to_net())
		end
	end
	--print("pkt = ",j_e(pkt))
	return pkt
end

-----打开ID所属寄售
function Consignment:get_owner_id_consignment(char_id)
	local uuids = self.owner[char_id]
	local spk = {}
	spk.consignment_list = {}
	if uuids then
		local del_list = {}
		local flags = false
		for k , uuid in pairs(uuids) do
			if uuid then 
				local pkt = {}
				local consignment_goods = self.total.list[uuid]
				if consignment_goods:is_expiredtime() then
					flags = true
					table.insert(del_list,uuid)
				else
					if consignment_goods then
						table.insert(spk.consignment_list,consignment_goods:spec_serialize_to_net())
						flags = true
					end
				end
			end
		end
		if flags then
			self:delete_expired_consignment(del_list)
		end
	end

	spk.record = self.record[char_id]

	return spk
end

--平衡列表
function Consignment:del_consignment_goods(uuid)
	local consignment_goods = self.total.list[uuid]
	local pkt = {}
	local sub_type
	local node = {}
	local item_name

	if consignment_goods.item_id == -2 then			--元宝
		sub_type = self:fliter_sub_type(consignment_goods.item_id)
		item_name = "-2"
	elseif consignment_goods.item_id == -1 then		--铜币
		sub_type = self:fliter_sub_type(consignment_goods.item_id)
		item_name = "-1"
	elseif consignment_goods.item_id > 0 then		--物品
		local e_code , item = Item_factory.create(consignment_goods.item_id)
		if e_code ~= 0 then
			return
		end
		local lvl = item:get_item_lvl() or item:get_req_lvl()
		node.lvl = self:filter_LVL(lvl)
		node.col = item:get_color()
		node.occ = self:filter_OCC(item:get_req_class())
		sub_type = self:fliter_sub_type(consignment_goods.item_id,item)
		item_name = item:get_name()
	end
	pkt = self:maintain_get_table_type(node)
	for k , v in pairs(pkt) do
		v:sub_type_index(sub_type,consignment_goods.uuid)
	end
	self.index:sub_type_index(sub_type, consignment_goods.uuid)
	self:sub_name_l(item_name, consignment_goods.uuid)

	for k , v in pairs(self.owner[consignment_goods.owner_id]) do
		if v == uuid then
			table.remove(self.owner[consignment_goods.owner_id] , k)
			break
			--self.owner[consignment_goods.owner_id][k] = nil
		end
	end
	self.total.counts = self.total.counts - 1
	self.total.list[uuid] = nil
	return
end

---------------------------物品下架
function Consignment:delete_owner_uuid_consignment(char_id,uuid)
	local flags = false
	local pkt = {}
	local consignment = self.total.list[uuid]
	if consignment and consignment.owner_id == char_id then
		flags = true
	end

	if not flags then
		pkt.result = 20505
		return pkt
	end

	local node = {}
	node.item_id  = consignment.item_id 
	node.count	  = consignment.count 
	node.owner_id = consignment.owner_id 
	node.item_DB  = consignment.item_DB

	if self:sub_consignment_goods(uuid, 3) then
		self:off_consignment_notice(node)
		return self:get_owner_id_consignment(char_id)
	end

end

-----物品过期
function Consignment:delete_expired_consignment(del_list)
	for k,uuid in pairs(del_list) do
		local consignment = self.total.list[uuid]
		local node = {}
		node.item_id  = consignment.item_id 
		node.count	  = consignment.count 
		node.owner_id = consignment.owner_id 
		node.item_DB  = consignment.item_DB

		if self:sub_consignment_goods(uuid, 2) then
			self:timeoff_consignment_notice(node)
		end
	end
	return 
end

---------------删除寄售品  type 1=购买 2=过期下架 3=手动下架
function Consignment:sub_consignment_goods(uuid, type, char_id)
	if Consignment_db:DeleteConsignment(uuid) == true then
		--后台记录
		local consignment_goods = self.total.list[uuid]
		local str
		if char_id then
			if not consignment_goods.item_DB then
				str = string.format(
				"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = %d,create_time =%d,money = %d,money_type= %d,from_char_id=%d",
						char_id,
						consignment_goods.item_id,
						consignment_goods.count,
						type,
						ev.time,
						consignment_goods.money_count,
						consignment_goods.money_type,
						consignment_goods.owner_id)
			else 
				str = string.format(
				"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = %d,create_time =%d,money = %d,money_type= %d,from_char_id=%d, remark = '%s'",
						char_id,
						consignment_goods.item_id,
						consignment_goods.count,
						type,
						ev.time,
						consignment_goods.money_count,
						consignment_goods.money_type,
						consignment_goods.owner_id,
						Json.Encode(consignment_goods.item_DB))
			end
		else
			if not consignment_goods.item_DB then
				str = string.format(
				"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = %d,create_time =%d,money = %d,money_type= %d",
						consignment_goods.owner_id,
						consignment_goods.item_id,
						consignment_goods.count,
						type,
						ev.time,
						consignment_goods.money_count,
						consignment_goods.money_type)
			else
				str = string.format(
				"insert into log_consignment set char_id =%d ,item_id = %d,item_num = %d,type = %d,create_time =%d,money = %d,money_type= %d, remark = '%s'",
						consignment_goods.owner_id,
						consignment_goods.item_id,
						consignment_goods.count,
						type,
						ev.time,
						consignment_goods.money_count,
						consignment_goods.money_type,
						Json.Encode(consignment_goods.item_DB))
			end

		end
		g_web_sql:write(str)  

		self:del_consignment_goods(uuid)
		return true
	end
	return false
end

---------------购买物品
--返回物品购买信息
function Consignment:get_buy_info(uuid, char_id)
	local pkt = {}
	pkt.char_id = char_id
	local consignment_goods = self.total.list[uuid]
	if consignment_goods then
		pkt.uuid		= uuid
		pkt.money_type	= consignment_goods.money_type
		pkt.money_count = consignment_goods.money_count
	else
		pkt.result = 20508
	end	
	return pkt, consignment_goods.server_id
end

--等腾讯扣款成功
function Consignment:pre_buy_consignment(char_id, param_l)
	local consignment = self.total.list[param_l.uuid]
	if consignment then
		if not g_currency_mgr:consignment_id_exist(param_l.uuid) then
			g_currency_mgr:add_consignment_id(param_l.uuid, param_l, char_id, consignment.owner_id,
						consignment.money_count, math.ceil(consignment.money_count * 0.05))
			return 0
		end
	end
	
	return 20510
end

--扣完钱购买信息
function Consignment:buy_consignment(char_id,param_l)
	local pkt = {}
	local uuid = param_l.uuid
	local buyer = param_l.buyer_name
	local consignment = self.total.list[uuid]
	local node = {}
	if consignment then 	--购买
		node.buyer 		= buyer
		node.buyer_id	= char_id
		node.item_id	= consignment.item_id
		node.count  	= consignment.count
		node.money_type	= consignment.money_type
		node.money_count= consignment.money_count
		node.char_id	= consignment.owner_id
		node.item_DB	= consignment.item_DB
		self:sub_consignment_goods(uuid, 1, char_id)
		self:do_consignment_notice(node)
	else			--别人先买，发邮件补偿
		node.money_type	 = param_l.money_type
		node.money_count = param_l.money_count
		node.owner_id    = char_id
		self:compensate_consignment_notice(node)
		local str = string.format(
			"insert into log_consignment set char_id =%d ,type = %d,create_time =%d,money = %d,money_type= %d",
					char_id,
					4,
					ev.time,
					param_l.money_count,
					param_l.money_type)

		g_web_sql:write(str) 
	end
	
	return true
end

--出售记录
function Consignment:record_consignment(char_id, record)
	if not self.record[char_id] then
		self.record[char_id] = {}
	end
	if table.getn(self.record[char_id]) >= limit then
		table.remove(self.record[char_id], 1)
	end
	table.insert(self.record[char_id], record)
	Consignment_db:update_record(char_id, self.record[char_id])
	return
end

--购买记录
function Consignment:record_buy_consignment(char_id, record)
	if not self.record[char_id] then
		self.record[char_id] = {}
	end
	if table.getn(self.record[char_id]) >= limit then
		table.remove(self.record[char_id], 1)
	end
	table.insert(self.record[char_id], record)
	Consignment_db:update_record(char_id, self.record[char_id])
	return
end

--[[下架通知
邮件标题格式：“xxxxx逾期退还，请您查收。”
           邮件内容格式：“寄售道具【xxxx】×xx逾期退还，请您查收。”
]]
function Consignment:timeoff_consignment_notice(node)
	local spk = {}
	spk.owner_id 	= node.owner_id
	spk.item_id 	= node.item_id
	spk.count 		= node.count
	spk.item_DB		= node.item_DB
	local item_list = {}
	if spk.item_id == -1 then
		spk.item_name = f_get_string(531)--g_u("铜币")
	elseif spk.item_id == -2 then
		spk.item_name = f_get_string(532)--g_u("元宝")
	else
		local e_code , item = Item_factory.create(spk.item_id)
		if e_code ~= 0 then
			return
		end
		spk.item_name = item:get_name()
	end

	spk.title = f_get_string(533)--g_u("寄售品逾期下架退还，请您查收")
	spk.content = string.format(f_get_string(534),spk.item_name)
	
	return self:structure_email(spk)
end

--手动下架
function Consignment:off_consignment_notice(node)
	local spk = {}
	spk.owner_id 	= node.owner_id
	spk.item_id 	= node.item_id
	spk.count 		= node.count
	spk.item_DB		= node.item_DB
	local item_list = {}
	if spk.item_id == -1 then
		spk.item_name = f_get_string(531)
	elseif spk.item_id == -2 then
		spk.item_name = f_get_string(532)
	else
		local e_code , item = Item_factory.create(spk.item_id)
		if e_code ~= 0 then
			return
		end
		spk.item_name = item:get_name()
	end

	spk.title =  f_get_string(535)-- g_u("寄售品下架退还，请您查收")
	spk.content = string.format(f_get_string(536),spk.item_name)
	return self:structure_email(spk)
end
--[[购买通知
 邮件标题格式：“寄售物品成功售出，请您提取附件。”
           邮件内容格式：“xxx购买【xxxx】×1，支付xxx元宝，扣除手续费xx元宝，你可获得xxx元宝。”
]]
function Consignment:do_consignment_notice(node)

-------------------------------购买者邮件
	local spk = {}
	spk.owner_id 	= node.buyer_id
	spk.item_id 	= node.item_id
	spk.count 		= node.count
	spk.item_DB		= node.item_DB
	local item_list = {}
	if spk.item_id == -1 then
		spk.item_name = f_get_string(531)
	elseif spk.item_id == -2 then
		spk.item_name =f_get_string(532)
	else
		local e_code , item = Item_factory.create(spk.item_id)
		if e_code ~= 0 then
			return
		end
		spk.item_name = item:get_name()
	end

	local owner_info = {}
	owner_info.char_id 	= node.char_id
	owner_info.type 	= node.money_type
	owner_info.count	= node.money_count

	spk.title =  f_get_string(537)--g_u("物品成功购入，请您提取附件。")
	spk.content = string.format(f_get_string(538),spk.item_name)
	self:structure_email(spk, owner_info)
-------------------------------出售者邮件
	local tpk = {}
	tpk.owner_id 	= node.char_id
	tpk.item_id 	= node.money_type
	tpk.count 		= node.money_count - math.ceil(node.money_count * 0.05)
	local item_list = {}
	if tpk.item_id == 1 then
		tpk.item_name = f_get_string(531)
	elseif tpk.item_id == 2 then
		tpk.item_name = f_get_string(532)
	else
		return
	end

	tpk.title =  f_get_string(539)--g_u("物品成功卖出，请您提取附件。")
	tpk.content = string.format( f_get_string(540),node.buyer,spk.item_name)

	local buyer_info = {}
	buyer_info.buyer_id	= node.buyer_id
	buyer_info.type 	= node.money_type
	buyer_info.count	= node.money_count
	buyer_info.name		= spk.item_name
	buyer_info.item_cnt	= node.count

	self:structure_email(tpk, nil, buyer_info)
	--货币流水
	local money_count =  math.ceil(node.money_count * 0.05)
	local gold_jade 
	if node.money_type == 1 then
		gold_jade = 1
	else
		gold_jade = 3
	end
	local player_info = g_player_mgr.all_player_l[node.char_id]
	str = string.format("insert log_money set char_id=%d, char_name='%s', level=%d, io=%d, type=%d, money_type=%d, left_num=%d, time=%d, money_num=%d",
						node.char_id, player_info["char_nm"], player_info["level"], 0,  MONEY_SOURCE.CONSIGNMENT_TAXES, gold_jade,  0, os.time(), money_count)
	g_web_sql:write(str)  
end
--[[补偿通知]]

function Consignment:compensate_consignment_notice(node)
	local tpk = {}
	tpk.owner_id 	= node.owner_id
	tpk.item_id 	= node.money_type	
	tpk.count 		= node.money_count
	local item_list = {}
	if tpk.item_id == 1 then
		tpk.item_name = f_get_string(531)
	elseif tpk.item_id == 2 then
		tpk.item_name = f_get_string(532)
	else
		return
	end

	tpk.title = f_get_string(541)
	tpk.content = string.format(f_get_string(542),node.buyer,tpk.item_name)
	self:structure_email(tpk)
end

--[[上架补偿]]

function Consignment:add_compensate_consignment_notice(node)

	local spk = {}
	spk.owner_id 	= node.owner_id
	spk.item_id 	= node.item_id
	spk.count 		= node.count
	spk.item_DB		= node.item_DB
	local item_list = {}
	if spk.item_id == -1 then
		spk.item_name = f_get_string(531)
	elseif spk.item_id == -2 then
		spk.item_name =f_get_string(532)
	else
		local e_code , item = Item_factory.create(spk.item_id)
		if e_code ~= 0 then
			return
		end
		spk.item_name = item:get_name()
	end

	spk.title =  f_get_string(552)--g_u("物品成功购入，请您提取附件。")
	spk.content = string.format(f_get_string(553))
	self:structure_email(spk)

end


---------构造邮件,owner_info给出售者信息，有代表是需要记录;buyer_info给购买者信息
function Consignment:structure_email(node, owner_info, buyer_info)
	local char_id 	= node.owner_id
	local item_id 	= node.item_id
	local count 	= node.count
	local item_DB	= node.item_DB
	local item_name	= node.item_name
	local title 	= node.title
	local content	= node.content
	local flags 	= false
	if item_id == 1 then
		item_id = -1
	elseif item_id == 2 then
		item_id = -2
	end

	local new_pkt = {}
	if item_id == -1  then
		new_pkt.item = self:build_item(item_id,count)
	elseif item_id == -2 then
		new_pkt.item = self:build_item(item_id,count)
	elseif item_id > 0 then
		new_pkt.item = self:build_item(item_id,count,item_name,item_DB)
		flags = true
	end

	local item_list = {}
	item_list[1] = new_pkt.item
	if item_id == -2 then				--元宝的干掉
		item_list = nil
	end

	local g_email = Email(-1,char_id,title,content,0,Email_type.type_annex,Email_sys_type.type_sys,item_list)
	if g_email ~= nil then
		local item ={}
		for k,v in pairs(item_list or {}) do
			item[1] ={}
			item[1]["item_id"] = v:get_item_id()
			if item_id > 0 then
				item[1]["item_obj"] = item_DB
			else
				item[1]["item_obj"] = v
			end
			if flags then
				item[1]["number"] = count
			else
				item[1]["number"] = 1
			end
		end
		if item_id ~= -2 then				--元宝的干掉
			g_email:set_item_list(item)
		end
		g_email_mgr:add_email(g_email)

		if owner_info then
			local record = {}
			--出售
			record.flags	= 1
			--购买时间
			record.time		= ev.time
			--购买者姓名
			record.buyer	= g_player_mgr.all_player_l[char_id]["char_nm"]
			--得到的货币类型  -1铜币 -2元宝
			record.type		= 0 - owner_info.type
			--得到的货币数量
			record.count 	= owner_info.count
			--卖出的物品名
			record.name 	= item_name
			--卖出的物品数量
			record.number 	= count
			self:record_consignment(owner_info.char_id, record)
		end

		if buyer_info then
			local record = {}
			--购买
			record.flags	= 2
			--购买时间
			record.time		= ev.time
			--购买者姓名
			record.buyer	= g_player_mgr.all_player_l[char_id]["char_nm"]
			--得到的货币类型  -1铜币 -2元宝
			record.type		= 0 - buyer_info.type
			--得到的货币数量
			record.count 	= buyer_info.count
			--卖出的物品名
			record.name 	= buyer_info.name
			--卖出的物品数量
			record.number 	= buyer_info.item_cnt
			self:record_buy_consignment(buyer_info.buyer_id, record)
		end
	end
end

function Consignment:build_item(item_id,count,item_name,item_DB)
	local flags = true
	local money_list={}
	money_list[MoneyType.GOLD] = 0
	money_list[MoneyType.GIFT_GOLD] = 0
	money_list[MoneyType.JADE] = 0
	money_list[MoneyType.GIFT_JADE] = 0
	money_list[MoneyType.INTEGRAL] = 0

	if item_id == -1 then
		money_list[MoneyType.GOLD] = count
		flags = false
	elseif item_id == -2 then
		money_list[MoneyType.JADE] = count
		flags = false
	end

	if not flags then --货币用礼包发
		local item_list = {}
		if item_name then
			item_list[1] 		= {}
			item_list[1].id 	= item_id
			item_list[1].count	= count
			item_list[1].name	= item_name
		end
		
		--构造奖励礼包
		local _,item_l = Item_factory.create(104002000130)
		item_l:set_item_list(item_list)
		item_l:set_money(money_list)
		item_l:set_name(f_get_string(543))
		item_l.item_id = 104002000130
		return item_l
	else
		local e_code ,item_l = Item_factory.clone(item_id,item_DB)
		if e_code ~= 0 then
			return
		end
		--if item_DB then
			--item_l:clone(item_DB)
		--end
		return item_l
	end
end


--[[删除寄售品
更新寄卖品
]]
----------------------------数据持久化----------------------------
function Consignment:load()
	local rs= Consignment_db:LoadAllConsignment()
	if rs then
		for k,v in pairs(rs) do
			local consignment = {}
			consignment.uuid			= v.uuid		
			consignment.item_id 		= tonumber(v.item_id) 	
			consignment.count			= tonumber(v.count)		
			consignment.owner_id	 	= tonumber(v.owner_id)	
			consignment.owner_name		= v.owner_name	
			consignment.expired_time	= tonumber(v.expired_time)
			consignment.money_type		= tonumber(v.money_type)
			consignment.money_count 	= tonumber(v.money_count) 
			consignment.item_DB 		= v.item_DB
			consignment.server_id 		= v.server_id

			local consignment_goods = Consignment_goods(consignment)
			if consignment_goods then
				self:insert_consignment(consignment_goods)
			end
		end
	end

	local r_rs= Consignment_db:LoadAllConsignment_record()
	if r_rs then 
		for k, v in pairs(r_rs) do
			local error_flag = false
			for kk, vv in pairs(v.record) do
				if type(vv) ~= 'table' then
					error_flag =true
					break
				end
				if not vv.flags then
					vv.flags = 1
				end
			end
			if not error_flag then
				self.record[v.char_id] = v.record
			end
		end
	end

	return 
end

function Consignment:seralize_consignment_db()
	for k, v in pairs(self.total.list or {}) do 
		Consignment_db:update_consignment(v)
	end
	
	for k, v in pairs(self.record) do
		Consignment_db:update_record(k, v)
	end
end

