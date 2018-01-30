#!/usr/bin/python
#-*- coding: utf8 -*-
#
# This script uses stbr mailbox to fetch the build status of a SPEC file.
# It is used by the PLD Neatty Web Builder Monitor And Such to display
# the current state of the package. Hopefully.
#
# TODO:
#   - DEBUG mode fired from the commandline (getopt?)
#   - Status determined from the message sent date, not from the position
#     in a mailbox file
#   - Add Message-ID or filename (Maildir) in debug dismantle error
#     message
#   - Add file name in debug "processing message"... message
#
# $Id: src-builder-status.py 11792 2010-08-31 07:41:22Z shadzik $

import email
import email.Errors
import mailbox
import os
import sys


MAILDIR = '/home/users/stbr/Mail/'
ALLOWED_DISTVERS = ('th', 'ti', 'ti-dev')
ALLOWED_STATUSES = ('OK', 'FAILED')
DEBUG = False	# Change this to True in case of disaster to see what is going on



def email_reader_factory(fh):
    try:
	return email.message_from_file(fh)
    except email.Errors.MessageParseError:
	return ''


try:
    (distver, spec) = sys.argv[1:3]
    distver = distver.lower()
    if distver not in ALLOWED_DISTVERS:
	raise Exception()
except:
    sys.stderr.write('Usage: %s { %s } <spec>\n' % (os.path.basename(__file__), ' | '.join(ALLOWED_DISTVERS)))
    sys.exit(1)

builderstr = {
    'th': "builder-th-src",
    'ti': "builder-ti",
    'ti-dev': "builder-ti-dev"
}[distver]

#result = 'UNKNOWN'
result = None

try:
    mdir = mailbox.Maildir(MAILDIR, email_reader_factory)
    for message in mdir:
	if not message:
	    continue
	elif DEBUG:
	    sys.stderr.write('DEBUG: processing message %s\n' % (message['Message-ID'],))
	
	if not message['From'].endswith('%s@pld-linux.org>' % (builderstr)):
	    continue

    	for line in message.get_payload().split('\n'):
	    if line.startswith(spec):
		try:
		    (junk, branch, status) = line.split(' ', 2)
		except:
		    if DEBUG:
			sys.stderr.write('DEBUG:\tDismantle error at line "%s"\n' % (line,))
		    continue
		if status not in ALLOWED_STATUSES:
		    print status
		    continue
		else:
		    result = status
except Exception, e:
    if DEBUG:
	raise
    sys.stdout.write('Script Error\n')
    sys.exit(2)

if result:
    sys.stdout.write('%s\n' % (result,))

# vim: sts=4 noai nocp indentexpr=

