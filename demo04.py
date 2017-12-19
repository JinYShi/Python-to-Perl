#!/usr/bin/python3

print("to test different condition of range")

count = 0
for i in range(100):
    k = i // 2
    j = 2
    for j in range(2, k - 1):
        k = i % j
        if k == 0:
            count = count - 1
            break
        k = i // 2
    count = count + 1
print(count)


coun = 0
for a in range(2, 100):
    b = a // 2
    c = 2
    for c in range(2, 50):
        b = a % c
        if b == 0:
            coun = coun - 1
            break
        b = a // 2
    coun = coun + 1
print(coun)
