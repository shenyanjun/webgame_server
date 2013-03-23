

---------------------------------接收抽奖，与map交互---------------------

--挑选号码
Sv_commands[0][CMD_SPECLOTTERY_CHOICE_NUMBER_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.number or not pkt.char_id then return end

	if char_id ~= nil then
		g_spec_lottery_mgr:choice_number(pkt.char_id, pkt.number)
	end
end

--开奖  测试用
--Sv_commands[0][CMD_LOTTERY_OPEN_NUMBER_M] =
--function(conn,char_id,pkt)
	--g_spec_lottery_mgr:draw_lottery()
--end
