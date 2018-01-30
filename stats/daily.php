<?

require_once("php-ofc-library/open-flash-chart.php");
require_once("db.dat");

$pld_lines = array("th","ti","ti-dev");

$year = date("Y");
$month = date("m");
$max_days = date("t");
//if ($month < 10)
//	$month = "0".$month;
$days = array();
for ($i=1; $i<=$max_days; $i++) {
	if ($i < 10)
		$i = "0".$i;
	$days[] = (string)$i;
}

$th_bar = new line();
$ti_bar = new line();
$ti_dev_bar = new line();

$thm = array();
$tim = array();
$tidm = array();
foreach ($pld_lines as $line) {
	foreach($days as $day) {
		$q = @$DBhandle->query('select count(*) from application where line="' . $line . '" and date >="'.$year.'-' . (string)$month . '-'.$day.' 00:00:00" and date < "'.$year.'-'. (string)$month .'-'.$day.' 23:59:59"');
		$data = (int)$q->fetchSingle();
		switch($line) {
			case "th":
				if ($data == 0)
					$thm[] = null;
				else
					$thm[] = $data;
				break;
			case "ti":
				if ($data == 0)
					$tim[] = null;
				else
					$tim[] = $data;
				break;
			case "ti-dev":
				if ($data == 0)
					$tidm[] = null;
				else
					$tidm[] = $data;
				break;
		}
	}
}

$th_max = max($thm);
$ti_max = max($tim);
$tid_max = max($tidm);
if ($th_max >= $ti_max)
	$scale = $th_max;
else
	$scale = $ti_max;

$month_name = date("F");
$title = new title("Daily Requests in $month_name $year");

$th_bar->set_values($thm);
$th_bar->set_colour('#FF6633');
$th_bar->set_key('Th', 12);
$ti_bar->set_values($tim);
$ti_bar->set_colour('#3366FF');
$ti_bar->set_key('Titanium', 12);
$ti_dev_bar->set_values($tidm);
$ti_dev_bar->set_colour('#006600');
$ti_dev_bar->set_key('Titanium Devel', 12);

$chart = new open_flash_chart();
$chart->set_title($title);
$chart->add_element($th_bar);
$chart->add_element($ti_bar);
$chart->add_element($ti_dev_bar);

$y = new y_axis();
$y->set_range(0, $scale, 1);

$xlabels = new x_axis_labels();
$xlabels->set_labels($days);

$x = new x_axis();
$x->set_labels($xlabels);

$chart->set_x_axis($x);
$chart->set_y_axis($y);

echo $chart->toPrettyString();

?>
