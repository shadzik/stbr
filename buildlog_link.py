#!/usr/bin/python

import os
import sys
import re
import readline
import codecs

html = "queue.html"

lines = []
links = []

def parseHtml():
	try:
		dist = sys.argv[1]
		id = sys.argv[2]
	except(IndexError):
		print "Usage: %s dist buildID [th-arch|ti-arch] [file]" % sys.argv[0]
		return
	try:
		f = open(html, 'r')
	except IOError:
		print "File doesn't exist."
		return
	read = f.xreadlines()
	for l in read:
		l = l.strip()
		lines.append(l)
	for i in range(len(lines)):
		if re.findall(id, lines[i]):
			log = 1
			while (lines[i+log] != "</ul>"):
				if re.findall("http",lines[i+log]):
					links = lines[i+log].split(" ")
					break
				log = log + 1
	try:
		if links:
			for i in range(len(links)):
				if re.findall("\"http://buildlogs", links[i]):
					try:
						link = links[i].split("\"")[1]
					except(IndexError):
						print "%s" % links[i]
						return
					try:
						if re.match("ti$", dist):
							arch = sys.argv[3].split("ti-")[1]
						elif re.match("ti-dev", dist):
							arch = sys.argv[3].split("ti-dev-")[1]
						else:
							arch = sys.argv[3].split("th-")[1]
						if re.findall(arch, link):
							try:
								fs = open(sys.argv[4], "w")
								fs.write(link)
								fs.close()
							except(IndexError):
								print link
								pass
							break
					except(IndexError):
						try:
							fs = open(sys.argv[3], "a")
							fs.write(link)
							fs.close()
						except(IndexError):
							print link
							pass
						pass
	except(UnboundLocalError):
		return

def getQueue():
	try:
		dist = sys.argv[1]
	except(IndexError):
		return
	if re.match("ti$", dist):
		os.popen("wget --quiet -N http://kraz.tld-linux.org/~builderti/queue.html")
	elif re.match("ti-dev", dist):
		os.popen("wget --quiet -N http://kraz.tld-linux.org/~buildertidev/queue.html")
	else:
		os.popen("wget --quiet -N http://ep09.pld-linux.org/~builderth/queue.html")

getQueue()
parseHtml()
