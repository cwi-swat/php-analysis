<?php 
$x = 3;
goto l1;

if ($x == 5) {
	l1:
	echo "The value of x is " . $x . "\n";
	$x = 4;
}
?>