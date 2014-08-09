<?php

+$a; // [+$a] <: int(), [$a] != array()
-$b; // [+$b] <: int(), [$b] != array()
!$c; // [!$c] = bool()
// ~E = bitwise not
~$d; // [~$d] = int|string, [$d] = float|int|string
$e++; // big conditional list
$f--; // same big conditional list
++$g; // same big conditional list
--$h; // same big conditional list
