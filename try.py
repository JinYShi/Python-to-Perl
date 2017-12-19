#!/usr/bin/python3
import sys,re

line_count = 0
for line in sys.stdin:
    line = re.sub(r'[A-Z]','',line)
    line_count += 1
    print(line)
print("%d lines" % line_count)
