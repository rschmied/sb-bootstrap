#!/usr/bin/env python
import pickle
import time

try:
	file=open("/var/lib/cloud/instance/obj.pkl")
	ci=pickle.load(file)
	try:
		print ci.metadata['meta']['i_was_born']
	except:
		print int(time.time())
except:
	print int(time.time())
