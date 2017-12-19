#!/usr/bin/python3
import sys
d =list()
#initialize the value of each element

for arg in sys.argv[1:]:
	if arg not in d:
		d.append(arg)


#get a list of key
for key in d:
	print(key,end=' ')

# \n
print()



