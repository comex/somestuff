import sys
f = open('/dev/ttyUSB0', 'rb')
while True:
	i = f.read(1)
	print hex(ord(i)), ' ',

