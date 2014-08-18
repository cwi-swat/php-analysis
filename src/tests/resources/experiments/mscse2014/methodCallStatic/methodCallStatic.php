<?php

// static call
if (true) {
    class C { public static function d() {} public function e() { $this::f(); } }
} else {
    class C { public static function d() {} }
}

//$c = c::d();

//$d = "d";
//$x = c::$d();

//$c = new C;
//$c::d();

//$d = "d";
//c::$d();

//$c::$d();
