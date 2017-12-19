#!/usr/bin/python3

factor1 = 0
factor2 = 1
factor3 = 0


if factor1 == factor2 or factor1 == factor3:
    print("correct")

if factor1 == factor2 and factor1 == factor3:
    print("should not print out")
elif factor1 <= 0 and factor2 >= 0:
    print("correct")

