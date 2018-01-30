<?

require_once("php-ofc-library/open-flash-chart.php");
require_once("db.dat");

$pld_lines = array("th","ti");
$year = "2009";
$months = array("Jan", 
		"Feb",
		"Mar",
		"Apr", 
		"May", 
		"Jun",
		"Jul", 
		"Aug", 
		"Sep", 
		"Oct",
		"Nov", 
		"Dec"
	);

$th_bar = new bar();
$ti_bar = new bar();

$thm = array();
$tim = array();
foreach ($pld_lines as $line) {
	for ($month=1; $month<=12; $month++) {
		$month2 = $month+1;
		if ($month < 10) {
			$month = "0".$month;
			$month2 = "0".$month2;
		}
		if ((int)$month < 12)
			$q = @$DBhandle->query('select count(*) from application where line="' . $line . '" and date >="'.$year.'-' . (string)$month . '-01 00:00:00" and date < "'.$year.'-'. (string)$month2 .'-01 00:00:00"');
		else {
			$year2 = $year+1;
			$q = @$DBhandle->query('select count(*) from application where line="' . $line . '" and date >="'.$year.'-' . (string)$month . '-01 00:00:00" and date < "'.$year2.'-01 00:00:00"');
		}
		if ($line == "th")
			$thm[] = (int)$q->fetchSingle();
		else
			$tim[] = (int)$q->fetchSingle();
	}
	
}

$th_max = max($thm);
$ti_max = max($tim);
if ($th_max >= $ti_max)
	$scale = $th_max;
else
	$scale = $ti_max;

$title = new title("$year Monthly Requests");

$th_bar->set_values($thm);
$th_bar->set_colour('#FF6633');
$th_bar->set_key('Th', 12);
$ti_bar->set_values($tim);
$ti_bar->set_colour('#3366FF');
$ti_bar->set_key('Titanium', 12);

$chart = new open_flash_chart();
$chart->set_title($title);
$chart->add_element($th_bar);
$chart->add_element($ti_bar);

$y = new y_axis();
$y->set_range(0, $scale, 20);

$xlabels = new x_axis_labels();
$xlabels->set_labels($months);

$x = new x_axis();
$x->set_labels($xlabels);

$chart->set_x_axis($x);
$chart->set_y_axis($y);

echo $chart->toPrettyString();

?>
