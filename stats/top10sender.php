<?

require_once("php-ofc-library/open-flash-chart.php");
require_once("db.dat");

$top = 10;

$q = @$DBhandle->query('select sender, count(sender) AS c from stbr group by sender order by c desc limit '.$top.';');

$res = $q->fetchAll();
$specs = array();
$count = array();
foreach ($res as $e) {
	$specs[] = $e[0];
	$count[] = (int)$e[1];
}

$title = new title("STBR Sender Top $top");
$chart = new open_flash_chart();
$chart->set_title($title);

$ranks = array();
$bars = array();
for ($i=0; $i<$top; $i++) {
	$ranks[] = (string)($i+1);
	$bar = new bar_value($count[$i]);
	$bar->set_tooltip("$specs[$i], $count[$i]");
	$bars[] = $bar;
}

$bar = new bar_3d();
$bar->set_values($bars);
$chart->add_element($bar);

$y = new y_axis();
$y->set_range(0, max($count), 10);

$xlabels = new x_axis_labels();
$xlabels->set_labels($ranks);

$xlegend = new x_legend('Rank');

$x = new x_axis();
$x->set_labels($xlabels);

$chart->set_x_axis($x);
$chart->set_y_axis($y);
//$chart->set_x_legend($xlegend);

echo $chart->toPrettyString();

?>
