#!/bin/bash
# author: shadzik at pld-linux dot org
# use with stbr.tcl at exactly the same version
# Version: 0.9.2

SPEC="$1"
SEND_TO="$2"
FROM="$3"

/usr/sbin/sendmail -t <<EOF
From: $FROM <$FROM@IRC-bot>
To: $SEND_TO
Subject: STBR Request Cancellation for $SPEC

Hello,

Please don't send $SPEC to builders!

The request for $SPEC was revised and rejected by $FROM
and is no longer valid.

Thank you.

Yours truly,
STBR Requester
EOF
