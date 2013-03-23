--author:   zhanglongqi
--date:     2011.03.30
--file:     vip_include.lua

require("vip.vip_obj")
require("vip.vip_mgr")
require("vip.vip_loader")
require("vip.vip_fairy_store_include")
require("vip.vip_fairy_store_loader")

VIPATTR = {
["KILLMONSTER"] = "kill_mon",       --杀怪加成
["SPRINT"] = "spring",            --泡温泉
["OFFLINE"] = "off_exp",           --离线
["ESCORT"] = "escort",            --押镖
["TRANSFER"] = "transfer",          --跟斗云传送
["CONSIGNMENT"] = "consignment",       --寄售
["SILVERBOX"] = "silver_box",         --白银宝箱
["ULTIMATEXP"] = "ultima_exp",        --帮派强盗副本最终经验奖励
["ULTIMATCON"] = "ultima_cont",       --帮派强盗副本最终帮贡奖励 
["INTENSIFY"] = "intensify",        --强化
["WARREWARD"] = "war_reward",                   --战场奖励	
["SPIRITPOLYMER"] = "spirit",                           --聚灵阵
["FACTIONREWARD"] = "faction_reward",           --帮派奖励
["EXCADD"] = "exc_addition",				--全服答题排错
["DOUADD"] = "integral_addtition",			--全服答题积分加倍
["JUMP"] = "jumplayer",				--跑塔跳层
["JUMPADD"] = "jump_addition",       --跳层加成
["CHEST_ONE"] = "chest_one",		--VIP开宝箱
["CHEST_TWO"] = "chest_two",
["CHEST_THREE"] = "chest_three",
["PET_CULT"] = "pet_cult",		--宠物修炼加成
["COPY_TIME"] = "copy_time",		--副本挂机时间
["COPY_EXP"] = "copy_exp",	--副本经验加成
["COLLECTIONS"] = "collections",	--VIP采集次数
["CHEST_FOUR"]  = "chest_four"
}    

 



local vip_config = require("vip.vip_loader")

--功能：使用卡
--参数：卡类
--返回：
function f_use_vip_card(char_id,card_type)
	if card_type < 1 then
		return 20400
	end
	return g_vip_mgr:use_item(char_id,card_type)
end



--剩余时间
Clt_commands[1][CMD_MAP_VIP_GET_VALID_TIME_C]=
function(conn,pkt) 
	if not conn.char_id then return end
	local ret = g_vip_mgr:get_remain_time(conn.char_id) 
	local retpkt = {} 
	retpkt.time = ret 
	retpkt.flag = g_vip_mgr:is_get_bonus(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_GET_VALID_TIME_S,retpkt) 
end 


 
--领取白银宝箱
Clt_commands[1][CMD_MAP_VIP_GET_BONUS_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	local vip_type = g_vip_mgr:get_vip_info(conn.char_id)
	local ret = {}
	ret.result = 0

	if vip_type <=0 then 
		ret.result = 20398
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_GET_BONUS_S,ret)
		return 
	end

	if g_vip_mgr:is_get_bonus(conn.char_id)==0  then 
		ret.result = 20399
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_GET_BONUS_S,ret)
		return 
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()


	local vip_exp = 0
	local vip_bonus = vip_config.VipTable[vip_type]["vip_bonus"]
	if vip_bonus and vip_config.VipTable[vip_type]["vip_bonus"].vip_exp then
		vip_exp = vip_config.VipTable[vip_type]["vip_bonus"].vip_exp.exp or 0
	end
	local item_l = {}

	if vip_bonus and vip_bonus.item_list then
		 for i,v in pairs(vip_bonus.item_list or {}) do
			item_l[i] = {}
			item_l[i].type = 1
			item_l[i].number = v.number
			item_l[i].item_id = v.id

		 end


		if pack_con:add_item_l(item_l,{['type'] = ITEM_SOURCE.OPEN_VIP}) ~= 0 then
			ret.result = 43017
			g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_GET_BONUS_S,ret)
			return 
		end
	end
	if vip_exp ~= 0 then
		player:add_exp(vip_exp)
	end
	--记录开宝箱
	g_vip_mgr:open_bonus(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_VIP_GET_BONUS_S,ret)
end