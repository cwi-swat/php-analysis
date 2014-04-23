<?php
$i = 0;
while (++$i) {
    switch ($i) {
        case 5:
            echo "At 5<br />\n";
            break 1;  /* Exit only the switch. */
        case 10:
            echo "At 10; quitting<br />\n";
            break $br = 2;  /* Exit the switch and the while. */
        default:
            continue $con = 2;  /* Exit the switch and the while. */
            break;
    }
}
