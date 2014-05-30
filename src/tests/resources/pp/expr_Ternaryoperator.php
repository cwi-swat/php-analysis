<?php

// ternary
$a ? $b : $c;
$a ? : $c;

// precedence
$a ? $b : $c ? $d : $e;
$a ? $b : ($c ? $d : $e);
