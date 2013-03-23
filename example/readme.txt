mudrv底层提供接口类：
1，poll类，底层提供全局对象ev。实现主线程轮询，网络模型，定时器，gc，信号。详见ev.lua
2，iconv类，编码转换。见iconv.lua
3，json类，json与table相互转换。见json.lua
4，socket，buffer类，实现socket相关操作
5，crypto类，提供常用函数，随机，md5，uuid等。见crypto.lua
6，MySQL类，提供mysql数据库操作。
7，lxplib，提供xml解析操作。