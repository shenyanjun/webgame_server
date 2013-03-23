u = iconv:New("gbk", "utf-8")
g = iconv:New("utf-8", "gbk")

str = "жпнд"
szU = u(str)
szG = g(szU)
print(str, szU, szG)
print(szG == str)
