# Send To Builder Request TCL by shadzik@pld-linux.org

set versionstr "Send To Builder Request TCL v0.9.2 by shadzik"

set cmdbook "./scripts/cmdbook.txt"
set logfile "/home/users/stbr/db/stbrlog.db"
set unfilled "/home/users/stbr/db/unfilled.db"
set script "./scripts/cvslog.sh"
set cancellation "./scripts/cancellation.sh"
set resend "./scripts/resend.sh"
set makereq "./pld-builder.new/client/make-request.sh"
set back &
set cntr 0
set cvsroot ":pserver:cvs@cvs.pld-linux.org:/cvsroot"
set usage "Usage: !stbr \[help\] \[url\] \[version\] th\|ti\|ti-dev \[no\]upgrade spec1\[:BRANCH\]\[/\[+bcond+...\]\[-bcond-...\]\[%kernel%...\]\] spec2\[:BRANCH\]\[/\[+bcond+...\]\[-bcond-...\]\[%kernel%...\]\] ..."
set nickpass "stbr-bot"
set cmdtxt "./scripts/cmd.txt"
set maintenance "./scripts/maintenance.txt"
set bannedspec "./scripts/bannedspec.txt"
set queueparser "./scripts/queue_parser.pl"
set queuechan "#pld"
set actconfig "stbr.conf"
set bindedmh 0

############ DO NOT CHANGE ANYTHING BELOW UNLESS YOU KNOW WHAT YOU"RE DOING ###############

bind notc - "*This nickname is owned by someone else*" identify
bind dcc n identify man_identify 

proc man_identify { hand idx mask } {
global nickpass
	putserv "PRIVMSG NickServ :identify $nickpass"
	putlog "Sending Identify to NickServ"
}

proc identify { nick uhost hand text } {
global nickpass
	putserv "PRIVMSG NickServ :identify $nickpass"
	putlog "Sending Identify to NickServ"
}

putlog "STBR: using config $config"
if {([string match $actconfig $config])} {
	bind time - "* * * * *" pub:buildstatus
	putlog "STBR: Buildstatus activated"
}

proc putqueue {ver} {
	global queueparser queuechan
	exec $queueparser $ver > ${ver}.stat
	set qfile [open ${ver}.stat r]
	while {[gets $qfile l] >= 0} {
		putserv "privmsg $queuechan :$l"
		putlog "STBR: Found status: $ver: $l"
	}
	close $qfile
}

proc pub:buildstatus {nick host hand chan arg} {
	putlog "STBR: Searching for status..."
	putqueue ac
	putqueue ti
	putqueue ti-dev
	putqueue th
	putqueue aidath
}

proc help {nick} {
	global usage bindedmh
	putserv "privmsg $nick :$usage"
	putserv "privmsg $nick :Options:"
	putserv "privmsg $nick :!stbr help - shows this help"
	putserv "privmsg $nick :!stbr url - shows main URL on private chat"
	putserv "privmsg $nick :!stbr version - shows version on public channel"
	putserv "privmsg $nick :Type 'more' for more help and examples (you've got 120 seconds to do that)"
	bind msg - more msg:more_help
	set bindedmh 1
	utimer 120 "if {$bindedmh==1} {unbind msg - more msg:more_help; set bindedmh 0}"
}


proc msg:more_help {nick uhost hand text} {
	global bindedmh
	putserv "privmsg $nick :Examples:"
	putserv "privmsg $nick :!stbr th upgrade spec1 spec2:DEVEL - sends upgrade request for spec1 on branch HEAD and spec2 on branch DEVEL to TH developers"
	putserv "privmsg $nick :!stbr ti noupgrade spec1 - sends noupgrade request for spec1 on branch HEAD directly to Titanium builders"
	putserv "privmsg $nick :!stbr ti noupgrade spec1/+bcond1-bcond2 - sends noupgrade request for spec1 on branch HEAD with bcond1 enabled and bcond2 disabled"
	putserv "privmsg $nick :Other commands:"
	putserv "privmsg $nick :!stat spec \[BRANCH\] - checks if spec exists on BRANCH, if BRANCH is not set HEAD is taken"
	putserv "privmsg $nick :!del spec date time - (for admins only) removes request and sends cancelation email"
	putserv "privmsg $nick :Visit http://stbr.pld-linux.org/ to see the status of your request."
	if {$bindedmh==1} {
		unbind msg - more msg:more_help
		set bindedmh 0
	}
}

proc url {nick} {
	putserv "privmsg $nick :Visit http://stbr.pld-linux.org/ to see the status of your request."
}

proc version {chan nick} {
	global versionstr
	putserv "privmsg $chan :$nick: $versionstr"
}

proc random {book} {
	set file [open $book r]
	gets $file hands
	set range [llength $hands]
	close $file
	set whichone [expr {int(rand()*$range)}]
	return [lindex $hands $whichone]
}

proc rthx {} {
	set answer {"luz" "luzik" "nie ma sprawy" "spoko" "no problem" "n/p" "dla ciebie zawsze z mila checia"}
	set range [llength $answer]
	set whichone [expr {int(rand()*$range)}]
	return [lindex $answer $whichone]
}

proc sendto {dist spec branch} {
global cvsroot
if {([string match ti-dev $dist])} {
	set dist "ti"
}
set reqbook "./scripts/requesters-${dist}.txt"
if {([string match HEAD $branch])} {set cmd "-N"} {set cmd "-r$branch"}
set splited [split $spec "."]
set lsize [llength $splited]
if {($lsize == 3)} {
	set pkg [lrange $splited 0 1]
	regsub -all " " $pkg "." pkg
} else {
	set pkg [lindex $splited 0]
}
if {[catch {exec cvs -d $cvsroot rlog $cmd packages/$pkg/$spec | awk {/author/{a = $5; sub(/;/, "", a); if (!seen[a]) print a; seen[a] = 1}}} results]} {return 0}
set file [open $reqbook r]
gets $file lista
close $file
foreach devil $results {
	foreach requester $lista {
		if {([string match $requester $devil])} {return $devil}
	}
}
random $reqbook
}

if {([string match $actconfig $config])} {
	bind time - "00 * * * *" checkunfilled
	putlog "STBR: Checkunfilled activated"
}

proc checkunfilled {nick host hand chan arg} {
	global unfilled resend queuechan logfile
	putcmdlog "STBR: Looking for unfilled specs..."
	set time [clock seconds]
	set unfilledreq [exec sqlite $unfilled "select * from unfilled order by date;"]
	foreach unfr $unfilledreq {
		set splitreq [split $unfr "|"]
		set date [lindex $splitreq 0]
		set futuredate [clock scan {+2 days} -base $date]
		set spec [lindex $splitreq 1]
		set branch [lindex $splitreq 2]
		set recipient [lindex $splitreq 3]
		set dist [lindex $splitreq 4]
		set reqbook "./scripts/requesters-${dist}.txt"
		if { [expr {$time >= $futuredate }] } {
			set towho [random $reqbook]
			set splited [split $spec "."]
			set lsize [llength $splited]
			if {($lsize == 3)} {
				set pkg [lrange $splited 0 1]
				regsub -all " " $pkg "." pkg
			} else {
				set pkg [lindex $splited 0]
			}
			exec $resend $dist $pkg/$spec $branch $towho 
			exec sqlite $unfilled "update unfilled set date='$time' where spec='$spec' and branch='$branch' and line='$dist';" &
			putserv "privmsg $queuechan :Found requests unfilled for more than 2 days. Resent request for $spec to $towho."
		}
	}
}

proc pub:stat {nick host hand chan arg} {
global cvsroot maintenance
if {([file exists $maintenance]) && (![matchattr $hand S])} {
	set plik [open $maintenance r]
	gets $plik reason
	close $plik
	putcmdlog "Maintenance mode active"
	putserv "privmsg $chan :$nick: I'm now in maintenance mode (reason: $reason). Only owners may perform real actions."
	return 0
	}
if {[llength [lrange $arg 0 end]] < 1} {putserv "privmsg $chan :$nick: Usage: !stat spec \[BRANCH\]";return 0}
set spec [lindex $arg 0]
set branch [lindex $arg 1]
if {[string length $branch]==0} {
	set branch "HEAD"
}
if {!([string match *.spec $spec])} { 
	set pkg $spec
	append spec ".spec" 
} else { 
	set splited [split $spec "."]
	set lsize [llength $splited]
	if {($lsize == 3)} {
		set pkg [lrange $splited 0 1]
		regsub -all " " $pkg "." pkg
	} else {
		set pkg [lindex $splited 0]
	}
}
if {([string match HEAD $branch])} {set cmd "-N"} else {set cmd "-r$branch"}
if {[catch {exec cvs -d $cvsroot rlog $cmd packages/$pkg/$spec} results]} {
	putserv "privmsg $chan :$nick: ${spec}@${branch} doesn't exist in PLD's repository."
	return 0
}
	set link "http://cvs.pld-linux.org/cgi-bin/cvsweb.cgi/packages/$pkg/$spec?only_with_tag=$branch"
	putserv "privmsg $chan :$nick: ${spec}@${branch} exists in PLD's repository. Go see it at $link"
	return 0
}

proc banned_spec {spec} {
global bannedspec
set file [open $bannedspec r]
gets $file lista
close $file
foreach bspec $lista {
	if {([string match $spec $bspec])} {
		return 0
	}
}
}

proc command {exe} {
if {[catch {exec which $exe} results]} {return 0}
}

bind pub * !stbr pub:stbr
bind pub * stbr: pub:stbr
bind pub * stbr, pub:stbr
bind pub * !del pub:del
bind pub * !stat pub:stat
bind pub * !maintenance pub:setmaintenance

proc pub:del {nick host hand chan arg} {
global logfile cancellation unfilled
	if {([matchattr $hand S])} {
		set usage "Usage: !del spec date time"
		set spec [lindex $arg 0]
		set day [lindex $arg 1]
		set hour [lindex $arg 2]
		if {([string length $spec]<2) || ([string length $day]!=10) || ([string length $hour]!=8)} {
			putserv "privmsg $chan :$nick: $usage"
			return 0
		}
		set date ""; append date $day; append date " "; append date $hour
		set developer [exec sqlite $logfile "select recipient from application where spec='$spec' and date='$date';"]
		set email ""; append email $developer; append email "@pld-linux.org"
		putcmdlog "Deleting entry for: $spec on $date. Sending mail to $developer"
		exec sqlite $logfile "DELETE FROM application where spec='$spec' and date='$date'; DELETE FROM stbr where date='$date';" &
		exec sqlite $unfilled "DELETE FROM unfilled where spec='$spec';" &
		exec $cancellation $spec $email $hand &
		putserv "privmsg $chan :$nick: Request deleted. Cancellation e-mail sent to $developer"
	}
}

proc pub:setmaintenance {nick host hand chan arg} {
	global maintenance
	if {([matchattr $hand S])} {
		set usage "Usage: !maintenance on|off \[comment\]"
		set przelacznik [lindex $arg 0]
		set comment [lrange $arg 1 end]
		if {([string match on $przelacznik])} {
			set fp [open $maintenance "w"]
			puts -nonewline $fp $comment
			close $fp
			putserv "privmsg $chan :$nick: Maintenance Mode is On (reason: $comment)"
		} elseif {([string match off $przelacznik])} {
			file delete $maintenance
			putserv "privmsg $chan :$nick: Maintenance Mode is Off"
		} else {
			putserv "privmsg $chan :$nick: $usage"
		}	
	}
}

proc pub:stbr {nick host hand chan arg} {
global script back cntr logfile usage makereq cmdbook cmdtxt maintenance unfilled
if {([file exists $maintenance]) && (![matchattr $hand S])} {
	set plik [open $maintenance r]
	gets $plik reason
	close $plik
	putcmdlog "Maintenance mode active"
	putserv "privmsg $chan :$nick: I'm now in maintenance mode (reason: $reason). Only privileged users may perform real actions."
	return 0
}
putcmdlog "#$hand# Noticed Send To Build Request Mail command";
set time [clock seconds]
set date [clock format $time -format "%Y-%m-%d %H:%M:%S"]
set first [lindex $arg 0]
if {([string match help $first])} {help $nick; return 0}
if {([string match url $first])} {url $nick; return 0}
if {([string match version $first])} {version $chan $nick; return 0}
if {([string match dzieki $first]) || ([string match dziekuje $first]) || ([string match thx $first]) || ([string match tx $first]) || ([string match thnx $first]) || ([string match dzięki $first]) || ([string match dziękuję $first])} {
	set answ [rthx]; putserv "privmsg $chan :$nick: $answ"; return 0
}
if {!([string match th $first] || [string match ti $first] || [string match ti-dev $first])} {
	putserv "privmsg $chan :$nick: $usage"; return 0
}
set dist $first
set second [lindex $arg 1]
set third [lindex $arg 2]
if {([string match command $second])} {
	putserv "privmsg $chan :$nick: command not implemented yet."; return 0
}
set specs ""; append specs $third; append specs " "; append specs [lrange $arg 3 end]
set rspecs ""
set tspecs ""
set defines ""
set bconds_with ""
set bconds_without ""
if {!([string match noupgrade $second] || [string match upgrade $second])} {
	putserv "privmsg $chan :$nick: $usage"; return 0
}
if {([string length $third]<2)} {putserv "privmsg $chan :$nick: $usage"; return 0}
if {([string match noupgrade $second])} {set second "test-build"}
foreach spec $specs {
if {([string match */* $spec])} {
	set halfs [split $spec "/"]
	set spechalf [lindex $halfs 0]
	set bcondhalf [lindex $halfs 1]
	if {([string match *:* $spechalf])} {
		set halfs [split $spechalf ":"]
		set spec [lindex $halfs 0]
		set branch [lindex $halfs 1]
	} else {
		set spec $spechalf
		set branch "HEAD"
	}
	if {([string match *+* $bcondhalf]) || ([string match *-* $bcondhalf]) || ([string match *%* $bcondhalf])} {
		if {([string match *%* $bcondhalf])} {
			set bsplited [split $bcondhalf "%"]
			set bcondhalf [lindex $bsplited 0]
			set defines [lrange $bsplited 1 end]
			if {([string match *-* $bcondhalf])} {
				set bsplited [split $bcondhalf "-"]
				set bcondhalf [lindex $bsplited 0]
				set bconds_without [lrange $bsplited 1 end]
				if {([string match *+* $bcondhalf])} {
					set bsplited [split $bcondhalf "+"]
					set bconds_with [lrange $bsplited 1 end]
				}
			} 
		} elseif {([string match *-* $bcondhalf])} {
			set bsplited [split $bcondhalf "-"]
			set bcondhalf [lindex $bsplited 0]
			set bconds_without [lrange $bsplited 1 end]
			if {([string match *+* $bcondhalf])} {
				set bsplited [split $bcondhalf "+"]
				set bconds_with [lrange $bsplited 1 end]
			}
		} elseif {([string match *+* $bcondhalf])} {
			set bsplited [split $bcondhalf "+"]
			set bconds_with [lrange $bsplited 1 end]
		}
	}
} elseif {([string match *:* $spec])} {
	set splited [split $spec ":"]
	set spec [lindex $splited 0]
	set branch [lindex $splited 1]
} else {
	set branch "HEAD"
}

if {$bconds_with != ""} {
	set flag "--with "
	set with ""
	foreach bcond $bconds_with {
		set bcond $flag$bcond; append bcond " "; append with $bcond
	}
	set bconds_with $with
}
if {$bconds_without != ""} {
	set flag "--without "
	set without ""
	foreach bcond $bconds_without {
		set bcond $flag$bcond; append bcond " "; append without $bcond
	}
	set bconds_without $without
}
if {$defines != ""} {
	set flag "--kernel "
	set definedis ""
	foreach define $defines {
		set define $flag$define; append define " "; append definedis $define
	}
	set defines $definedis
}
if {!([string match *.spec $spec])} { set pkg $spec; append spec ".spec"} {set splited [split $spec "."]; set pkg [lindex $splited 0]}
set towho [sendto $dist $spec $branch]
if {($towho == 0)} {putserv "privmsg $chan :$nick: There is no such spec ($spec) on branch $branch in PLD's repository."; return 0}
set isbanned [banned_spec $spec]
if {($isbanned == 0)} {putserv "privmsg $chan :$nick: $spec is banned from being STBRed."; return 0}
if {($bconds_with == "") && ($bconds_without == "") && ($defines == "")} {
lappend rspecs $spec; append rspecs ":$branch (to $towho)"
lappend tspecs $spec; append tspecs ":$branch"
} else {
lappend rspecs $spec; append rspecs ":$branch (to $towho, options: $bconds_with $bconds_without $defines)"
lappend tspecs $spec; append tspecs ":$branch (options: $bconds_with $bconds_without $defines)"
}
if {([string match test-build $second])} {
	if {[utimer 5 "exec $makereq -d $dist -t $bconds_with $bconds_without $defines $spec:$branch >/dev/null 2>&1"]==0} {putserv "privmsg $chan :$nick: An error occured. Couldn't send test-build request for $spec to builders."; return 1}
	exec sqlite $logfile "INSERT INTO application VALUES('$date','$spec','$branch','stbr','$second','$dist');"
} {
	if {[exec $script $dist $nick $second $pkg/$spec $branch $towho $bconds_with $bconds_without $defines &]==0} {putserv "privmsg $chan :$nick: An error occured. Couldn't send STBR Mail for $spec to $towho."; return 1}
	exec sqlite $logfile "INSERT INTO application VALUES('$date','$spec','$branch','$towho','$second','$dist');"
	exec sqlite $unfilled "INSERT INTO unfilled VALUES('$time','$spec','$branch','$towho','$dist');"
}
}
exec sqlite $logfile "INSERT INTO stbr VALUES('$date','$nick');"
set date [split $date " "]
set day  [lindex $date 0]
set hour [lindex $date 1]
set space "%20"
if {([string match test-build $second])} {
	putserv "privmsg $chan :$nick: Sent $second request for $tspecs directly to PLD-$dist builders. Visit http://stbr.pld-linux.org/?show=$nick&date=$day$space$hour to track your request."
} {
	putserv "privmsg $chan :$nick: Sent STBR Mail for $rspecs. A ready-build will be performed on PLD-$dist line. Visit http://stbr.pld-linux.org/?show=$nick&date=$day$space$hour to track your request."
}
}

putlog "$versionstr loaded."
