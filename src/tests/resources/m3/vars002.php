<?php 
$global = "globalScope";

class X { 
	public function getX() {
        $private = "class-X-Scope";
        function f() {
            $private = "function-f-Scope";
        }
        function g() {
            $private = "function-g-Scope";
            $private = "function-g-Scope";
        }
    }
}

function h() {
    $private = "h";
}

$global = "globalScope";
$global2 = "globalScope";

$var = 'something';

$global3 |= $var;
$global4 ^= $var;
$global5 .= $var;
$global6 /= $var;
$global7 -= $var;
$global8 %= $var;
$global9 *= $var;
$global10 += $var;
$global11 <<= "globalScope";
$global12 >>= 1;
