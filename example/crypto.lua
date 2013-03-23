for i=1,10 do
	print(crypto.random(2)) --[0,2)
	print(crypto.random(1,100)) --[1,100)
	print(crypto.random(2.5)) -- double [0,2.5)
	print(crypto.random(1,1.5)) -- double [1,1.5)
end

print(crypto.md5("123456"))
print(crypto.md5("123", "456"))

print(crypto.uuid())
print(crypto.uuid())
