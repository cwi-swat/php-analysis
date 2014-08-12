<?php

// array declaration
array(); // array();
[]; // array();
array("a", "b", "c"); // array(["a"] | ["b"] | ["c"]);
array(0, "b", 3.4); // array([0] | ["b"] | [3.4]);
[0,1,2]; // array([0] | [1] | [2]);

// array fetch
$a[0];
$b["def"];
$c[0][0];

$d[] = 1;