<?php

$a + $b; // Both array -> [E] = array() || One of them not array: [E] <: floaty()
$c - $d; // [$c] != array(), [$d] != array(), .
$e * $f; // [$c] != array(), [$d] != array(), .
$g / $h; // [$c] != array(), [$d] != array(), .
$i % $j; // [E] = int

// bitwise operators:

// for &, | and ^
// [$l && $r] = string => [E] = string,
// [$l || $r] != string => [E] = int
$k & $l; // and
$m | $n; // inclusive or
$o ^ $p; // exclusive or

// for << and >>
// [E] = int()
$q << $r; // shift left
$s >> $t; // shift right