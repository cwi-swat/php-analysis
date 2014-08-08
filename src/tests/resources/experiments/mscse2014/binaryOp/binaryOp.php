<?php

$a + $b; // Both array -> [E] = array() || One of them not array: [E] <: floaty()
$c - $d; // [$c] != array(), [$d] != array(), .
$e * $f; // [$c] != array(), [$d] != array(), .
$g / $h; // [$c] != array(), [$d] != array(), .
$i % $j; // [E] = int
