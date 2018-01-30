<?
header('Content-type: text/html; charset=utf-8');
error_reporting(E_ALL);
#setlocale(LC_ALL, 'C');
ob_start("ob_gzhandler");
$db = sqlite_open("/home/users/stbr/db/stbrlog.db");
$unfdb = sqlite_open("/home/users/stbr/db/unfilled.db");

include("queue.php");

$distros = array(
	"th" => "http://ep09.pld-linux.org/~builderth/queue.gz",
	"ti" =>  "http://kraz.tld-linux.org/~builderti/queue.gz",
	"ti-dev" =>  "http://kraz.tld-linux.org/~buildertidev/queue.gz"
);

foreach($distros as $line => $url)
{
	$queue[$line] = new Queue($url);
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="pl">
<head>
<title>Send To Builder Requests (RC2)</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<style type="text/css">
h2 { text-align: center; }
body, td { font-family: Verdana; font-size: 9pt; background-image:url('white-stripes.png'); margin:0; }
table { border-collapse: collapse; width: 100%; }
td { padding: 6px 15px; }
tr.entry { padding: 6px 15px; border-top: 3px solid #ebebe4; border-bottom: 1px solid #ebebe4 }
tr.branch { padding: 6px 15px; width: 150px; color: red; } 
.thead td, thead td, tfoot td { background: #ebebe4 }
.thead td, thead td { border-bottom: 1px solid #c0c0c0; border-top: 1px solid #c0c0c0; padding: 5px 15px }
.thead td a, thead td a { color: #000000 }
tfoot td { border-top: 2px solid #c0c0c0; border-bottom: 1px solid #c0c0c0 }
tfoot td a { display: block; padding: 2px 5px; border: 1px outset; float: left; border: 1px solid #c0c0c0; background: #ffffff; color: #000000; text-decoration: none; margin-left: 5px }
#phonebookTable thead tr td div {
	text-align: center;
	font-weight: bold;
}
.status {
	width: 200px;
}
.builder, .spec, .status {
	width: 100px;
}
.recip {
	width: 80px;
}

.line {
	width: 20px;
}

.date { 
	width: 80px;
	text-align: center;
}
.sender {
	width: 80px;
}
.appInfoHead td {
	text-decoration: underline;
}

tr.application:hover td {
	background: #f2f2f2;
}
div#logoPLD {
	text-align: right;
}

a, a:visited {
	color: blue;
}
a:hover, a:visited:hover {
	color: red;
}

a.mailto, a.mailto:visited {
	background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAANBAMAAABSlfMXAAAAElBMVEUAAADAwMDIyMjU1NTh4eHq6urvtBmjAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQfXBRIQIwkqTPrmAAAANElEQVQI12NgIAIIQgGDsEooEDgZMog6AVlOKoEMoqFOpsEqoSBGqKFwKIQBAtgYihBjhABusBAkFbJeowAAAABJRU5ErkJggg==) right center no-repeat;
	padding-right: 18px;
}
a.mailto:hover, a.mailto:visited:hover {
	background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAANBAMAAABSlfMXAAAAGFBMVEUAAADAwMDMzMzf39/q6ury8vL5+fn///9jzSKfAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQfXBRIQKiMgNYh5AAAAPklEQVQI12NgYGAwFGYAgyDzYlUwrVpeHgRkMQNpIMuAQbgcDAwZRNJBdJkjg4gbiJECZLiAAXEMRUEwEAIApjwY+YHESpgAAAAASUVORK5CYII=);
}
#Popup {
	display: none;
	position: absolute;
	padding: 2px;
	border: 2px solid #c0c0c0;
	background: #ebebe4;
	color: #000;
	z-index: 1000;
	right: auto;
	bottom: auto;
	width: auto;
	max-width: 490px;
	height: auto;
	left: 10px;
	top: 10px;
}
.ok { color: green; }
.fail { color: red; }
#bottomlink {
	padding: 15px 15px 15px 15px;
	text-align: right;
}

</style>

<script type="text/javascript">
/*<![CDATA[*/
/* popup by sparky, GPLv2 ! */

function tohtml( txt ) {
    return decodeURIComponent(txt .replace(/\[/g, '<') .replace(/\]/g, '>')
        .replace(/<</g, '[') .replace(/>>/g, ']')
	.replace(/`/g, "'")
	.replace(/OK/g, '<b class="ok">OK</b>')
	.replace(/\?/g, '<b class="dunno">?</b>')
	.replace(/FAIL/g, '<b class="fail">FAIL</b>'));
}

popup = null;
popupS = null;
var overLock = 0;
var activeOver = null;
function O(e, t, txt) {
    if ( activeOver == this )
	return;
    if ( overLock ) {
	overLock = 0;
	hideOver();
    }
    popupS.left = "10px";
    popupS.display = "block";
    popup.innerHTML = tohtml( txt );
    if (popup.offsetWidth > 500)
	popupS.width = "500px";
    activeOver = t;
    t.onmouseout = hideOver;
    t.onclick = lockOver;
    if (window.onmousemove)
	window.onmousemove = moveOver;
    else
	document.onmousemove = moveOver;

    moveOver(e);
}

function getScrollTop() {
    if (window.pageYOffset) {
        return window.pageYOffset;
    } else {
        /* for IE */
        return document.getElementsByTagName('html')[0].scrollTop;
    }
    return 0;
}
function getScrollLeft() {
    if (window.pageXOffset) {
        return window.pageXOffset;
    } else {
        /* for IE */
        return document.getElementsByTagName('html')[0].scrollLeft;
    }
    return 0;
}

var lastEvent = null;
function getEvent(e) {
    if (!(e)) {
	try {
	    if (event)
		e = event;
	    else
		return lastEvent;
	} catch (err) {
	    return lastEvent;
	}
    }
    if (lastEvent)
	delete lastEvent;
	lastEvent = new Number();
    if (e.pageX) {
	lastEvent.pageX = e.pageX;
	lastEvent.pageY = e.pageY;
    }
    lastEvent.clientX = e.clientX;
    lastEvent.clientY = e.clientY;
    return lastEvent;
}


function moveOver(e) {
    if (popupS.display == "none") return;
    e = getEvent(e)
    var x = 16, y = 16;
    if (e.pageX) {
        x += e.pageX;
        y += e.pageY;
    } else {
        x += e.clientX + getScrollLeft();
        y += e.clientY + getScrollTop();
    }

    var maxX = - popup.offsetWidth - 20 + getScrollLeft();
    var maxY = - popup.offsetHeight - 20 + getScrollTop();
    if (window.pageYOffset != null) {
        maxX += self.innerWidth;
        maxY += self.innerHeight;
    } else {
        var b = self.document.body;
        maxX += b.clientWidth;
        maxY += b.clientHeight;
    }

    popupS.left = (x < maxX ? x : maxX) + "px";
    popupS.top = (y < maxY ? y : y - popup.offsetHeight - 30) + "px";
}
function lockOver(e) {
    if ( overLock ) {
	overLock = 0;
	activeOver.onmouseout = hideOver;
	if (window.onmousemove)
	    window.onmousemove = moveOver;
	else
	    document.onmousemove = moveOver;
	moveOver(e);
	return;
    }
    overLock = 1;
    activeOver.onmouseout = null;
    if (window.onmousemove)
        window.onmousemove = null;
    else
        document.onmousemove = null;
    moveOver(e);
}
function hideOver() {
    if ( overLock ) return;
    popupS.display = "none";
    popupS.width = "auto";
    activeOver.onmouseout = null;
    activeOver.onclick = null;
    if (window.onmousemove)
        window.onmousemove = null;
    else
        document.onmousemove = null;
}
/*]]>*/
</script>

</head>
<body>
<a href="/" title="PLD STBR"><img src="stbr-ng.png" alt="PLD STBR" style="border:0;" /></a>
<div style="float:right;margin:10px 0 0 0;background:#ebebe4;border-bottom:1px solid #c0c0c0;border-top:1px solid #c0c0c0;padding: 5px 15px"><a href="http://pld-users.org/en/howtos/stbr-how-to-put-a-package-into-pld-repository">&raquo; How to put a package into PLD repo</a><br/><a href="/stats">&raquo; STBR stats</a><p>Queue status:<br/><a href="http://ep09.pld-linux.org/~builderth/queue.html">&raquo; Th builder queue</a><br/><a href="http://kraz.tld-linux.org/~builderti/queue.html">&raquo; Ti builder queue</a><br/><a href="http://kraz.tld-linux.org/~buildertidev/queue.html">&raquo; Ti-dev builder queue</a></p></div> <div onclick="javascript:document.getElementById('usageinfo').style.display='block'; this.style.display='none';">[ Click to show usage info ]</div>

<table style="width: 950px; margin-bottom: 3em; display: none" id="usageinfo">
<thead>
<tr><td class="branch"><b style="color: black;">Usage Info:</b></td></tr>
</thead>
<tbody>
<tr><td class="branch">!stbr [help] [url] th|ti|ti-dev [no]upgrade spec1[:BRANCH] spec2[:BRANCH] ...</td>
<td>Usage options</td></tr>
<tr><td class="branch">!stbr help</td>
<td>Shows help information on private chat</td></tr>
<tr><td class="branch">!stbr url</td>
<td>Shows URL to this site on private chat</td></tr>
<tr><td class="branch">!stat spec [BRANCH]</td>
<td>Checks if spec exists on BRANCH, if BRANCH is not set HEAD is taken</td></tr>
<tr><td class="branch">!del spec date time</td>
<td>(<b>for admins only</b>) removes request and sends cancelation email</td></tr>
<tr><td class="branch">!stbr th upgrade spec1 spec2:DEVEL</td>
<td>Sends upgrade request for spec1 on branch HEAD<br/>and spec2 on branch DEVEL to TH developers</td></tr>
<tr><td class="branch">!stbr th noupgrade spec1</td>
<td>Sends noupgrade request for spec1 on branch HEAD directly to Th builders</td></tr>
<tr><td colspan="2">
To see builder status info, click on the filled request's row.</td></tr>
</tbody>
</table>

<div id="phonebookTable">
<table>
<thead>
<tr>
<td>Date</td>
<td>Requester</td>
<td colspan="5">Application info</td>
</tr>
</thead>
<tbody>
<tr class="appInfoHead">
<td colspan="2"></td>
<td class="line">line</td>
<td class="spec">spec</td>
<td class="recip">recipient</td>
<td class="builder">builder</td>
<td class="status">queue status</td>
</tr>

<!-- <tbody id="dataTable"> -->
<?
$query = "LIMIT 25";

if(isset($_GET['show_all']))
{
	$query = "";	
}

if(isset($_GET['show']) and isset($_GET['date']))
{
	$query = "select * from stbr where sender = \"{$_GET['show']}\" and date = \"{$_GET['date']}\" order by date DESC";
} elseif (isset($_GET['show'])){
	$query = "select * from stbr where sender = \"{$_GET['show']}\" order by date DESC";
} else {
	$query = "SELECT * FROM stbr ORDER BY date DESC $query";
}

$query = sqlite_query($db,$query);

while($p = sqlite_fetch_array($query))
{

$inner  = "SELECT application.recipient as arecipient, application.spec as aspec, application.branch AS abranch, ";
$inner .= " builder, line, queue_requester, queue_date, queue_flags, queue_builder_info ";
$inner .= "FROM application ";
$inner .= "LEFT JOIN status ";
$inner .= "ON (application.spec=status.spec AND application.date=status.date AND application.branch=status.branch) ";
if(!isset($_GET['upgrade']))
{
$inner .= "WHERE application.date='{$p['date']}' ";
}
else
{
$inner .= "WHERE builder='upgrade' ";
}
$inner .= "ORDER BY application.date DESC";
//echo $inner;
$inner = sqlite_query($db, $inner);
$rows = sqlite_num_rows($inner) + 1;
$sender = $p['sender'];

$pos = strpos($p['sender'], '@');
if($pos)
{
	$sender = substr($p['sender'], 0, $pos+3) . '...';
}
?>
<tr class="entry">
<td class="date" rowspan="<?=$rows?>"><?=$p['date']?></td>
<td class="sender" rowspan="<?=$rows?>"><?=$sender?></td>
<td colspan="5"></td>
</tr>
<!-- inner evil -->
<?

while($q = sqlite_fetch_array($inner))
{
	$title = '';
	$request_status_unknown = false;

	if(empty($q['queue_requester']) && empty($q['queue_date']))
	{
		$filled = $queue[$q['line']]->is_filled(array('spec' => $q['aspec'], 'date' => $p['date'], 'builder' => $q['builder'], 'line' => $q['line']));
		
		if(count($filled))
		{
			$filled['date'] = date("d.m.Y H:i:s", $filled['date']);

			foreach($filled['builder'] as $key => $value)
			{
				$randname = '/home/users/stbr/tmp/stbr-' . rand();
				$url = `./parser.py {$q['line']} {$filled['no']} {$key} $randname`;
				//echo $q['line']." ".$filled['no']." ".$key." ".$randname."<br/>\n";
				//echo $filled['no']."<br/>";

				$url = file_get_contents($randname);

				if(empty($url))
				{
					$request_status_unknown = true;
					$title .= $value . " @ " . $key . "[br/]";
				}
				else
				{
					$url = urlencode(trim($url));
					$title .= $value . " @ [a href=&quot;" . $url . "&quot;]" . $key . "[/a][br/]";
				}
				unlink($randname);

				if($value === '?')
					$request_status_unknown = true;
			}
			
			if(!$request_status_unknown)
			{
				$insert = 'INSERT INTO status VALUES ("';
				$insert .= $p['date'] . '","' . $q['aspec'] .'","';
				$insert .= $q['abranch'] . '","'; 
				$insert .= $filled['requester'] . '","' . $filled['date'] . '","';
			       	$insert .= $filled['flags'] . '","' . $title;
				$insert .= '");';
				$insert = sqlite_escape_string($insert);
				sqlite_exec($db, $insert, $err);
				//echo $err;
				$delete = 'delete from unfilled where spec="'. $q['aspec'] .'" and branch="'. $q['abranch'] .'"';
				//file_put_contents ("../delete.log", $delete, FILE_APPEND);
				$delete = sqlite_escape_string($delete);
				sqlite_exec($unfdb, $delete, $err);
			}
			$title = "onmouseover=\"O(event, this, '$title')\"";
			
			$info = '<a class="mailto">' . $filled['requester'] . '</a> / ' . $filled['flags'] . '<br />' . $filled['date'];
		}
		else
		{
			$info = "not filled";

			// check for src builder status
			$src_status = `./src-builder-status.py {$q['line']} {$q['aspec']}`;
			//$src_status = `./src-builder-status-maildir.py {$q['line']} {$q['aspec']}`;

			if(trim($src_status) == 'FAILED')
			{
				$info = "Source builder has failed to build src.rpm";

				$insert = 'INSERT INTO status VALUES ("';
				$insert .= $p['date'] . '","' . $q['aspec'] .'","';
				$insert .= $q['abranch'] . '","n/a"'; 
				$insert .= ',"","' . $info . '"';
			       	$insert .= ',"Check SourceX: tag(s) in .spec file or contact developers.");';
				$insert = sqlite_escape_string($insert);
				sqlite_exec($db, $insert, $err);
				$delete = 'delete from unfilled where spec="'. $q['aspec'] .'" and branch="'. $q['abranch'] .'"';
				//file_put_contents ("../delete2.log", $delete, FILE_APPEND);
				$delete = sqlite_escape_string($delete);
				sqlite_exec($unfdb, $delete, $err);
			}
		}
	}
	else
	{
		$info = '<a class="mailto">' . $q['queue_requester'] . '</a> / ' . $q['queue_flags'] . '<br />' . $q['queue_date'];
		$title = "onmouseover=\"O(event, this, 'Cached: [br/]{$q['queue_builder_info']}')\"";
	}
?>
<tr class="application" <?=$title?>>
<td class="line"><?=$q['line']?></td>
<?
	$pkg = explode(".", $q['aspec']);
	if(count($pkg)==3)
		$pkg = $pkg[0].".".$pkg[1];
	else
		$pkg = $pkg[0];
?>
<td class="spec"><a href="http://cvs.pld-linux.org/cgi-bin/viewvc.cgi/cvs/packages/<?=$pkg?>/<?=$q['aspec']?>?pathrev=<?=$q['abranch']?>"><?=$q['aspec']?></a>:<?=$q['abranch']?></td>
<td class="recip"><a class="mailto"><?=$q['arecipient']?></a></td>
<td class="builder"><?=$q['builder']?></td>
<td class="status">
<?=$info?>
</td>
</tr>
<?
}
?>
<!-- end of evil -->
<?
}
sqlite_close($db);
sqlite_close($unfdb);
?>
</tbody>
</table>

<table class="thead">
<tr>
<td colspan="3">
</td>
</tr>
</table>

</div>
<div id="bottomlink">
<a href="./?show_all">Show all requests &raquo;</a>
<p><a href="http://validator.w3.org/check?uri=referer"><img src="http://www.w3.org/Icons/valid-xhtml10" alt="Valid XHTML 1.0 Transitional" height="31" width="88" /></a></p>
</div>
<div id="logoPLD" onmouseover="O(event, this, 'Powered by [b]PLD[/b]')">
<a href="http://www.pld-linux.org/"><img src="logo_03.png" alt="PLD" style="border:0;" /></a>
</div>

<div id="Popup">EMPTY</div>

<script type="text/javascript">
/*<![CDATA[*/
/* fill href of As with class="mailto" */

(function replace_mailto()
{
	var as = document.getElementsByTagName("a"); 
	for ( var i = 0; i < as.length; i++ ) {
		if ( as[i].className == "mailto" )
			as[i].href = "mailto:" + as[i].innerHTML + "@" + "pld-linux.org";
	}
}) ();

popup = document.getElementById("Popup");
popupS = popup.style;
/*]]>*/
</script>

</body>
</html>
