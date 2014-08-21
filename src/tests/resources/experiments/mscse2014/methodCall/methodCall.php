<?php

// static call
class C { public function d() { } }

$c = new C;
$c->d();

$d = "d";
$c->$d();

$c->$d();

// variable calls
//$a->$b();
//$a::$b();
