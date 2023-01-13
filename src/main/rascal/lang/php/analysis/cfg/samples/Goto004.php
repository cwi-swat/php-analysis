<?php 
$x = 5;
goto l1;

while ($x == 5) {
	l1:
	echo "The value of x is " . $x . "\n";
	$x = 4;
}
?>