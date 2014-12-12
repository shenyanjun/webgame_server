--author:   zhanglongqi
--date:     2011.03.22
--file:     integral_container.lua


--调试打印函数
local debug_print=function() end 
local integral_loader=require("config.integral_config") 


module("mall.integral_func",package.seeall)


--功能：商城购买/离线经验
--参数：玩家id，总价，log参数
--返回：没有
function add_bonus(char_id,price,src_log)
   	if price <=0  then return end
    local player=g_obj_mgr:get_obj(char_id) 
	local pack_con=player:get_pack_con() 
	local bonus = price*(integral_loader._integral_config["use_jade_per"]["bonus"] or 0)  
	local e_code=pack_con:add_money(MoneyType.BONUS,math.floor(bonus*100),src_log) 
end 


function bonus_result(ret_bonus)

	local total = 0
	local append_per = 0 
	local bonus=ret_bonus

	--[[
	--帮派
    if player:get_faction() ~= nil and table.size(player:get_faction())~=0 then
		local faction_per = integral_loader._integral_config["append_per"]["faction"]
		if faction_per ~= nil then append_per = append_per + faction_per end
	end

	--vip
	local vip_per = g_vip_mgr:get_vip_attr(char_id,VIPATTR.VIP)
	if vip_per ~= nil then append_per = append_per + vip_per end
	]]

	local festivel_index = os.date("%Y/%m/%d",ev.time)
	local festival_per =  integral_loader._integral_config["date_per"][festivel_index]
	if festival_per == nil then
		if os.date("*t").wday==1 or os.date("*t").wday==7 then
		    local weeken_index = os.date("%w",ev.time)
		    local weeken_per=integral_loader._integral_config["date_per"][weeken_index]
			local total_per = weeken_per + append_per
		    total=math.floor(bonus*total_per)
		else
			local normal_per=integral_loader._integral_config["date_per"]["normal"] 
			local total_per = normal_per + append_per
		    total=math.floor(bonus*total_per)
		    
		end 
	else
	    local total_per = festival_per + append_per
	    total=math.floor(bonus*total_per)
	end
	return total
end


function get_bonus(char_id)
    local player=g_obj_mgr:get_obj(char_id) 
	local pack_con=player:get_pack_con() 
	local ret=pack_con:get_money() 
	local bonus=math.floor(ret.bonus/100)
	
	return bonus	
end

--功能：玩家兑换福利
--参数：char_id
--返回：錯誤類型
function exchange_bonus(char_id)
    local player=g_obj_mgr:get_obj(char_id) 
	local pack_con=player:get_pack_con()    
	 
	local bonus = get_bonus(char_id)
	if bonus < 1 then
	     return 60002
	end 

	local total = bonus_result(bonus)

    if total < 1 then
        return 60002 
	end 
	if pack_con:check_money_lock(MoneyType.BONUS) then return end
	pack_con:dec_money(MoneyType.BONUS,bonus*100,{['type']=MONEY_SOURCE.EXCHANGEBONUS}) 
	pack_con:add_money(MoneyType.JADE,total,{['type']=MONEY_SOURCE.EXCHANGEBONUS}) 

	return 0
end 


--功能：元宝
--参数：char_id
--返回：錯誤類型
function get_jade(char_id)

	local bonus = get_bonus(char_id)

	if bonus <= 0 then
	     return 0
	end 

	local total = bonus_result(bonus)

	if total < 0 then
	    return 0
	end
	return total
end 


--功能：玩家充值
--参数：char_id，充值数
--返回：没有
function charge(char_id,charge_count)
    if charge_count < 0 then 
	    return 
	end 
    local player=g_obj_mgr:get_obj(char_id) 
	local pack_con=player:get_pack_con() 
	local e_code=pack_con:add_money(MoneyType.INTEGRAL,math.floor(charge_count/10),{['type']=MONEY_SOURCE.CHARGE}) 
end 





