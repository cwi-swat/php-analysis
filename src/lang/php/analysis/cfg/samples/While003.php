<?php 
$x = 1;
while (true) {
	echo "The value of x outer is $x\n";
	while (true) {
		echo "The value of x is $x\n";
		break 2;
	}
}
echo "Done!\n";
?>