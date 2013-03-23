--2012-4-24
--chenxidu
--战场官职系统头文件及定义

--官职类型
OFFICER_TYPE = {
	  TAKEN		        = 1											--天劫
	, BANNED		    = 2											--禁言
	, PUNISHMENT	    = 3											--天罚
	, GODSEND		    = 4											--天赐
	, RESET		        = 5											--赦免
}

MAX_OFFICER_COUNT = 4

require("officer.officer_mgr")
require("officer.officer_sort")
require("officer.officer_loader")
require("officer.officer_db")
require("officer.officer_process")



