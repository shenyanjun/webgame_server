--author:   zhanglongqi
--date:     2011.03.30
--file:     vip_mgr.lua



local vip_config=require("vip.vip_loader")

Vip_mgr=oo.class(nil,"Vip_mgr");



function Vip_mgr:__init()
     self.vip_list={}
end

--功能：返回信息
--参数：
--返回：0 非vip；1 周卡；2 月卡；3 季卡；4 半年卡；5 体验卡
function Vip_mgr:get_vip_info(char_id)
     local obj = self:get_vip_obj(char_id)
	 return obj:get_vip_info()
end


function Vip_mgr:get_remain_time(char_id)
	local obj = self:get_vip_obj(char_id)
	return obj:get_remain_time()
end


--功能：使用卡
--参数：玩家id，卡类
--返回：
function Vip_mgr:use_item(char_id,card_type)
     local obj = self:get_vip_obj(char_id)
	 return obj:use_item(card_type)
end


--功能：获取加成
--参数：char_id --玩家id，attr_type --宏定义
--返回：加成
function Vip_mgr:get_vip_attr(char_id,attr_type)
    local obj = self:get_vip_obj(char_id)
	local card_type = obj:get_card_type()
	local vip_attr = vip_config.VipTable[card_type] and vip_config.VipTable[card_type][attr_type] or 0
	return vip_attr
end


--功能：卡类
--参数：玩家id
--返回：卡类
function Vip_mgr:get_vip_type(char_id)
	local obj = self:get_vip_obj(char_id)
	return  obj:get_card_type()
end


--功能：返回vip obj
--参数：
--返回：
function Vip_mgr:get_vip_obj(char_id)
	if self.vip_list[char_id]==nil then
	    self.vip_list[char_id]=Vip_obj(char_id)
		self.vip_list[char_id]:db_load()
	end

	return  self.vip_list[char_id]
end



function Vip_mgr:login(char_id)
	self.vip_list[char_id]=Vip_obj(char_id)
	--第一次上线不加载
	local player = g_obj_mgr:get_obj(char_id)
	if not player:is_first_login() then
		self.vip_list[char_id]:db_load()
	end
end


function Vip_mgr:logout(char_id)
	self.vip_list[char_id]:logout_save()
	self.vip_list[char_id] = nil
end


function Vip_mgr:open_bonus(char_id)
	local obj = self:get_vip_obj(char_id)
	return obj:open_bonus_ex()
end


function Vip_mgr:is_get_bonus(char_id)
	local obj = self:get_vip_obj(char_id)
	return obj:is_get_bonus()
end

--传送剩余次数
function Vip_mgr:get_transfer_surplus(char_id)
	local obj = self:get_vip_obj(char_id)
	return  obj:get_transfer_surplus()
end

--
function Vip_mgr:sub_transfer(char_id, t)
	local obj = self:get_vip_obj(char_id)
	return  obj:sub_transfer(t)
end