#!/bin/bash
# author: shadzik at pld-linux dot org
# use with stbr.tcl at exactly the same version
# Version: 0.9

CVSROOT=":pserver:cvs@cvs.pld-linux.org/cvsroot/"
HOST="pld-linux.org"
DIST="$1"
FROM="$2"
BUILDER="$3"
SPEC="$4"
BRANCH="$5"
SEND_TO="$6"
BCONDS_WITH="$7"
BCONDS_WITHOUT="$8"
DEFINES="$9"

option="-r"
send_branch=":$BRANCH"

if [ "$BUILDER" == "upgrade" ]; then

rm -fr packages/$SPEC >/dev/null 2>&1

if [ "$BRANCH" == "HEAD" ]; then
	send_branch=""
	cvs -d $CVSROOT get packages/$SPEC >/dev/null 2>&1
else
	cvs -d $CVSROOT up -r $BRANCH packages/$SPEC >/dev/null 2>&1
fi
ADD_INFO=`grep -B 50 -A 2 Name: packages/$SPEC`
fi

spec_name=$(awk '/Name:/ {print $2}' packages/$SPEC)
spec_ver=$(awk '/Version:/ {print $2}' packages/$SPEC |tr . _)
spec_rel=$(awk '/Release:/ {print $2}' packages/$SPEC |grep -vE "(\.)")

if [ "x$spec_rel" != "x" ]; then
auto_tag="auto-$DIST-$spec_name-$spec_ver-$spec_rel"
cvs -d $CVSROOT status -v packages/$SPEC |grep $auto_tag >/dev/null && TAG_INFO="Found $auto_tag tag. You need to increase spec release to successfully send upgrade." || TAG_INFO="No $auto_tag tag found. It's safe to send upgrade."
else
	TAG_INFO="Release seems not to be integer. Please correct this before sending upgrade."
fi

LAST_AUTOTAG=$(cvs -d ":pserver:cvs@cvs.pld-linux.org/cvsroot/" status -v packages/$SPEC |grep auto-$DIST |head -1 |awk '{print $1}')

if [ "x$LAST_AUTOTAG" != "x" ]; then
	LAST_AT="$LAST_AUTOTAG"
else
	LAST_AT="This spec was probably never sent to $DIST builders."
fi

function sendreq() {
/usr/sbin/sendmail -t <<EOF
From: $FROM <$FROM@IRC-bot>
To: $SEND_TO@$HOST
Subject: build request for $spec_name@$DIST

Hello,

$FROM is requesting build for $SPEC (on branch $BRANCH).
Please perform an $BUILDER on PLD-$DIST line.

I suppose you're lazy so I provide some commands you could just copy & paste:
make-request -d $DIST $option $BCONDS_WITH $BCONDS_WITHOUT $DEFINES ${spec_name}.spec$send_branch

Additional spec information:
$ADD_INFO

Tag information:
$TAG_INFO

Last auto-tag found:
$LAST_AT

Thank you.

Yours truly,
STBR Requester
EOF
}

function sendcmd() {
/usr/sbin/sendmail -t <<EOF
From: $FROM <$FROM@IRC-bot>
To: $SEND_TO@$HOST
Subject: COMMAND request

Hello,

$FROM is requesting command on builders.

I suppose you're lazy so I provide some commands you could just copy & paste:
make-request -d th -c $SPEC

Thank you.

Yours truly,
STBR Requester
EOF
}

if [ "$BUILDER" == "command" ]; then
	sendcmd
else
	sendreq
fi

