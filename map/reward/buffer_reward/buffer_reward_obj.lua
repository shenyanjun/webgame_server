--2010-11-09
--laojc
--礼品发放对象设置


buffer_reward_obj = oo.class(nil,"buffer_reward_obj")

function buffer_reward_obj:__init(type,start_date,end_date,start_time,end_time,time,bdc_content)
	self.start_date=start_date
	self.end_date=end_date
	self.start_time=start_time
	self.end_time=end_time
	self.type=type
	self.time=time

	self.flag = 0  --标志是否已经启动buffer,1 为已启动，0为未启动

	self.bdc_content = bdc_content
end
