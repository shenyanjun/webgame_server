t = {["a"]= "a\\\"\\a\naa", ["b"] = -1}
str = Json.Encode(t)
print(str)
t = Json.Decode(str)
print(string.format("'%s'", t.a))
print(string.format("%d", t.b))
