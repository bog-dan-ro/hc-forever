#!/usr/bin/python
# Convert a binary file to a sequence of UrJTAG commands
# which feed the data to the FPGA via USER1 instructions

import sys
data = sys.stdin.read()

addr = 0
if len(sys.argv) > 1:
	addr = eval(sys.argv[1])

print "# start address: 0x%04x" % addr
print "# data: 0x%04x (%d) bytes" % (len(data), len(data))

print "register UR 32"
print "instruction USER1 000010 UR"
print "instruction USER1"
print "shift ir"

for ch in data:
	print "dr 0x80%04x%02x" % (addr, ord(ch))
	print "shift dr"
	addr += 1

print "dr 0x0"
print "shift dr"
