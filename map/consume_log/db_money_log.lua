
--金钱消费流水记录(实时写进jtxm_web数据库存)

function f_write_money_db_log(char_id, info, money_info)
	if not char_id or not info then print("write money_log char_id or info is nil") return end
	local str_log = string.format(" char_id: %d m_type: %d currency: %d, price: %d", char_id, info.op_type, info.currency, info.price)
	g_money_log:write(str_log)
end


--其它金币写日志
function f_write_gold_money_log(char_id, fromto, m_type, value)
	if not char_id then print("write money_log char_id or info is nil") return end

	local str_log = string.format(" char_id: %d fromto: %d m_type: %d value: %d", char_id, fromto, m_type, value)
	g_money_log:write(str_log)
end

