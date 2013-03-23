
local vip_config=require("vip.vip_info_load")
Vip_Play_Info = oo.class(nil, "Vip_Play_Info")

VIPATTR = {
["KILLMONSTER"] = "kill_mon",     			    --杀怪加成
["SPRINT"] = "spring",          			    --泡温泉
["OFFLINE"] = "off_exp",        				--离线
["ESCORT"] = "escort",         				    --押镖
["TRANSFER"] = "transfer",       			    --跟斗云传送
["CONSIGNMENT"] = "consignment",   			    --寄售
["SILVERBOX"] = "silver_box",        			--白银宝箱
["ULTIMATEXP"] = "ultima_exp",      		 	--帮派强盗副本最终经验奖励
["ULTIMATCON"] = "ultima_cont",    				--帮派强盗副本最终帮贡奖励 
["INTENSIFY"] = "intensify",       				--强化
["WARREWARD"] = "war_reward",                   --战场奖励	
["SPIRITPOLYMER"] = "spirit",                   --聚灵阵
["FACTIONREWARD"] = "faction_reward",           --帮派奖励
["EXCADD"] = "exc_addition",					--全服答题排错
["DOUADD"] = "integral_addtition",				--全服答题积分加倍
["JUMP"] = "jumplayer",							--跑塔跳层
["JUMPADD"] = "jump_addition",    				--跳层加成
["CHEST_ONE"] = "chest_one",					--VIP开宝箱
["CHEST_TWO"] = "chest_two",
["CHEST_THREE"] = "chest_three",
["PET_CULT"] = "pet_cult",						--宠物修炼加成
["COPY_TIME"] = "copy_time",					--副本挂机时间
["COPY_EXP"] = "copy_exp",						--副本经验加成
["COLLECTIONS"] = "collections",				--VIP采集次数
["FAIRIES_IMOLEST"] = "fairies_imolest",		--仙灵 调戏次数
["FAIRIES_PMOLEST"] = "fairies_pmolest",		--仙灵 被调戏次数
["CHEST_FOUR"]  = "chest_four"
}    

function Vip_Play_Info:__init()
	self.vip_list = {}
	self:load_db()
end

function Vip_Play_Info:load_db()
	local db = f_get_db()
	local rows, e_code = db:select("vip_card")
	if 0 ~= e_code then
		return 
	end	
	for i,v in pairs(rows or {}) do
		for c,d in pairs(v) do
			if c == "char_id" then
				self.vip_list[d] = {}
				self.vip_list[d]["end_time"] = v["end_time"]
				self.vip_list[d]["card_type"] = v["card_type"]
			end	
		end
	end
end

function Vip_Play_Info:update_vip_list(char_id,endtime,cardtype)
	self.vip_list[char_id] = self.vip_list[char_id] or {}
	self.vip_list[char_id]["end_time"] = endtime
	self.vip_list[char_id]["card_type"] = cardtype
	self:send_inform(char_id, cardtype)
end

function Vip_Play_Info:get_vip_type(char_id)
	if self.vip_list[char_id] then
		if ev.time > self.vip_list[char_id]["end_time"] then
			self.vip_list[char_id]["card_type"] = 0
			return 0
		end
		return self.vip_list[char_id]["card_type"]	
	end
	return 0
end

function Vip_Play_Info:get_vip_field(char_id,fieldname)
	return vip_config.VipTable[self:get_vip_type(char_id)][fieldname]
end

function Vip_Play_Info:send_inform(char_id, cardtype)
		g_faction_mgr:vip_state_change(char_id, cardtype)  -- 帮派聊天 排序
end