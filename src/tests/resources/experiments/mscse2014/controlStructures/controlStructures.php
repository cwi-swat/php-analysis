<?php

// check if control flow constructs do not
// block the collecting of constraints

// if else elseif
if ($a1) {"10";}
if ($b1) {"20";} else {"30";}
if ($c1) {"40";} else if ("50") {$d1;} else {$e1;}
if ($c1) {"40";} elseif ("50") {$d1;} else {$e1;}
// if else elseif without brackets
if ($a2) "11";
if ($b2) "21"; else "31";
if ($c2) "41"; else if ("51") $d2; else $e2;
if ($a1): "12"; endif;

// while
while($f1) { "60"; }
while($f2)  "61";
while ($f3): "62"; endwhile;

// do while
do { $g1; } while ($h1);
do $g2; while ($h2);

// for
for ($i1; $i2; $i3) { "70"; }
for ($i4; ;$i5) { "71"; }
for (; ; ) { "72"; }
for ($i6, $j7; $i8; $j9, $i11, $i12);

// foreach
foreach ($k as $v) foreach ($kk as $vv) "80";
foreach ($arr as $key => $value) { continue $a; "statement"; }
foreach ($array as $element): "81"; endforeach;

// break and continue are ignored!

// switch
switch ($l2) { case 10; case "1str": "string"; break; default: "def"; }
switch ($l2): case 20: "zero2"; break; case "2str": "string"; break; default: "def"; endswitch;

// declare
declare(ticks=1) { $m; }

// goto
goto a; 'Foo';  a: 'Bar';

// try catch
try { $n1; } catch (\Exception $e) { $n2; };
try { $n3; } catch (\Exception $e) { $n4; } finally { $n5; };
