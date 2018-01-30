<?

require_once("php-ofc-library/open-flash-chart.php");
require_once("db.dat");

$q = $DBhandle->query('select count(*) from application');
$total = (int)$q->fetchSingle();

$pld_lines = array("th","ti","ti-dev");

$tmp = array();
foreach ($pld_lines as $line) {
	$q = @$DBhandle->query('select count(*) from application where line="' . $line . '"');
	$tmp[] = (int)$q->fetchSingle();
}

$title = new title("STBR Total Requests: $total");

$bar = new bar_glass();
$bar->set_values($tmp);

$chart = new open_flash_chart();
$chart->set_title($title);
$chart->add_element($bar);

$y = new y_axis();
$y->set_range(0, max($tmp), 100);

$xlabels = new x_axis_labels();
$xlabels->set_labels(array("Th", "Titanium", "Titanium Devel"));

$x = new x_axis();
$x->set_labels($xlabels);

$chart->set_x_axis($x);
$chart->set_y_axis($y);

echo $chart->toPrettyString();

?>
